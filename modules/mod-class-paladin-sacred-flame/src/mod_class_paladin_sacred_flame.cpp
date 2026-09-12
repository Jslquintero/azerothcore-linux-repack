/*
 * Sacred Flame - custom paladin passive.
 */

#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Player.h"
#include "PlayerScript.h"
#include "QuestDef.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "UnitScript.h"
#include "Unit.h"

#include <algorithm>
#include <cmath>
#include <map>

namespace
{
enum SacredFlameSpells
{
    SPELL_PALADIN_SACRED_FLAME_PASSIVE = 900001,
    SPELL_PALADIN_SACRED_FLAME_DAMAGE = 900002,
    SPELL_PALADIN_SACRED_FLAME_STACK_AURA = 900005
};

enum SacredFlameQuests
{
    QUEST_PALADIN_SACRED_FLAME_HORDE = 900003,
    QUEST_PALADIN_SACRED_FLAME_ALLIANCE = 900004
};

constexpr uint32 SACRED_FLAME_TICK_INTERVAL = 2 * IN_MILLISECONDS;
constexpr uint32 SACRED_FLAME_STACK_DURATION = 5 * IN_MILLISECONDS;
constexpr uint32 SACRED_FLAME_HOLY_FIRE_IMPACT_KIT = 3030;
constexpr float SACRED_FLAME_RADIUS = 6.0f;
constexpr uint8 SACRED_FLAME_MAX_STACKS = 3;

struct SacredFlameState
{
    uint32 tickTimer = SACRED_FLAME_TICK_INTERVAL;
    uint32 stackTimer = 0;
    uint8 stacks = 0;
};

std::map<ObjectGuid, SacredFlameState> SacredFlameStates;

bool CanUseSacredFlame(Player const* player)
{
    return player &&
        player->IsAlive() &&
        player->IsClass(CLASS_PALADIN, CLASS_CONTEXT_ABILITY) &&
        (player->HasSpell(SPELL_PALADIN_SACRED_FLAME_PASSIVE) ||
            player->GetQuestRewardStatus(QUEST_PALADIN_SACRED_FLAME_ALLIANCE) ||
            player->GetQuestRewardStatus(QUEST_PALADIN_SACRED_FLAME_HORDE));
}

void RemoveStackAura(Player* player)
{
    if (player)
        player->RemoveAura(SPELL_PALADIN_SACRED_FLAME_STACK_AURA);
}

void ResetStacks(Player* player, SacredFlameState& state)
{
    state.stackTimer = 0;
    state.stacks = 0;
    RemoveStackAura(player);
}

void RefreshStackAura(Player* player, uint8 stacks)
{
    Aura* aura = player->GetAura(SPELL_PALADIN_SACRED_FLAME_STACK_AURA);
    if (!aura)
        aura = player->AddAura(SPELL_PALADIN_SACRED_FLAME_STACK_AURA, player);

    if (!aura)
        return;

    aura->SetMaxDuration(SACRED_FLAME_STACK_DURATION);
    aura->SetDuration(SACRED_FLAME_STACK_DURATION);
    aura->SetStackAmount(stacks);
}

void AddStack(Player* player)
{
    if (!CanUseSacredFlame(player))
        return;

    SacredFlameState& state = SacredFlameStates[player->GetGUID()];
    state.stacks = std::min<uint8>(SACRED_FLAME_MAX_STACKS, state.stacks + 1);
    state.stackTimer = SACRED_FLAME_STACK_DURATION;
    RefreshStackAura(player, state.stacks);
}

int32 CalculateDamage(Player* player, uint8 stacks)
{
    float const level = static_cast<float>(player->GetLevel());
    float const attackPower = player->GetTotalAttackPowerValue(BASE_ATTACK);
    float const spellPower = static_cast<float>(player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_HOLY));
    float const baseDamage = level * 0.08f + attackPower * 0.006f + spellPower * 0.012f;
    float const stackMultiplier = 1.0f + 0.05f * static_cast<float>(stacks);

    return std::max<int32>(1, static_cast<int32>(std::ceil(baseDamage * stackMultiplier)));
}

void TickSacredFlame(Player* player, SacredFlameState const& state)
{
    std::list<Unit*> targets;
    Acore::AnyUnfriendlyUnitInObjectRangeCheck check(player, player, SACRED_FLAME_RADIUS);
    Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(
        player, targets, check);
    Cell::VisitObjects(player, searcher, SACRED_FLAME_RADIUS);

    int32 const damage = CalculateDamage(player, state.stacks);
    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(SPELL_PALADIN_SACRED_FLAME_DAMAGE);
    for (Unit* target : targets)
    {
        if (!target || !target->IsAlive() || !player->IsValidAttackTarget(target))
            continue;

        uint32 const holyDamage = static_cast<uint32>(std::max<int32>(1, damage));
        player->CastSpell(target, SPELL_PALADIN_SACRED_FLAME_DAMAGE, true);
        target->SendPlaySpellImpact(target->GetGUID(), SACRED_FLAME_HOLY_FIRE_IMPACT_KIT);

        if (spellInfo)
            player->SendSpellNonMeleeDamageLog(
                target, spellInfo, holyDamage, SPELL_SCHOOL_MASK_HOLY, 0, 0, false, 0);

        Unit::DealDamage(
            player, target, holyDamage, nullptr, SPELL_DIRECT_DAMAGE, SPELL_SCHOOL_MASK_HOLY, spellInfo, false);
    }
}

bool IsSacredFlameQuest(uint32 questId)
{
    return questId == QUEST_PALADIN_SACRED_FLAME_ALLIANCE || questId == QUEST_PALADIN_SACRED_FLAME_HORDE;
}

void LearnSacredFlameIfEligible(Player* player)
{
    if (!player || !player->IsClass(CLASS_PALADIN, CLASS_CONTEXT_ABILITY))
        return;

    if (player->HasSpell(SPELL_PALADIN_SACRED_FLAME_PASSIVE))
        return;

    if (!player->GetQuestRewardStatus(QUEST_PALADIN_SACRED_FLAME_ALLIANCE) &&
        !player->GetQuestRewardStatus(QUEST_PALADIN_SACRED_FLAME_HORDE))
        return;

    player->learnSpell(SPELL_PALADIN_SACRED_FLAME_PASSIVE);
}
}

class mod_class_paladin_sacred_flame_player : public PlayerScript
{
public:
    mod_class_paladin_sacred_flame_player() : PlayerScript("mod_class_paladin_sacred_flame_player",
        {
            PLAYERHOOK_ON_UPDATE,
            PLAYERHOOK_ON_LOGOUT,
            PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST,
            PLAYERHOOK_ON_LOGIN
        })
    {
    }

    void OnPlayerLogin(Player* player) override
    {
        LearnSacredFlameIfEligible(player);
    }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        LearnSacredFlameIfEligible(player);

        ObjectGuid const playerGuid = player->GetGUID();

        if (!CanUseSacredFlame(player))
        {
            RemoveStackAura(player);
            SacredFlameStates.erase(playerGuid);
            return;
        }

        SacredFlameState& state = SacredFlameStates[playerGuid];

        if (state.stackTimer)
        {
            if (state.stackTimer <= diff)
                ResetStacks(player, state);
            else
                state.stackTimer -= diff;
        }

        if (state.tickTimer > diff)
        {
            state.tickTimer -= diff;
            return;
        }

        state.tickTimer = SACRED_FLAME_TICK_INTERVAL;
        TickSacredFlame(player, state);
    }

    void OnPlayerLogout(Player* player) override
    {
        RemoveStackAura(player);
        SacredFlameStates.erase(player->GetGUID());
    }

    void OnPlayerCompleteQuest(Player* player, Quest const* quest) override
    {
        if (!player || !quest)
            return;

        uint32 const questId = quest->GetQuestId();
        if (IsSacredFlameQuest(questId))
            LearnSacredFlameIfEligible(player);
    }
};

class mod_class_paladin_sacred_flame_unit : public UnitScript
{
public:
    mod_class_paladin_sacred_flame_unit() : UnitScript("mod_class_paladin_sacred_flame_unit", true,
        {
            UNITHOOK_MODIFY_MELEE_DAMAGE
        })
    {
    }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
    {
        if (!damage || !target || !attacker || !attacker->IsPlayer())
            return;

        if (!target->IsAlive() || !attacker->IsValidAttackTarget(target))
            return;

        AddStack(attacker->ToPlayer());
    }
};

void Addmod_class_paladin_sacred_flameScripts()
{
    new mod_class_paladin_sacred_flame_player();
    new mod_class_paladin_sacred_flame_unit();
}

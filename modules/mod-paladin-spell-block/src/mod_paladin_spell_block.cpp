/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "Config.h"
#include "DBCStores.h"
#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "Unit.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <array>
#include <cmath>

namespace
{
enum PaladinTalentTree : uint8
{
    PALADIN_TREE_HOLY = 0,
    PALADIN_TREE_PROTECTION = 1,
    PALADIN_TREE_RETRIBUTION = 2,
    PALADIN_TREE_MAX = 3
};

struct PaladinSpellBlockSpec
{
    bool holy = false;
    bool protection = false;
};

float GetConfigFloat(char const* option, float defaultValue)
{
    return sConfigMgr->GetOption<float>(option, defaultValue);
}

uint32 GetConfigUInt(char const* option, uint32 defaultValue)
{
    return sConfigMgr->GetOption<uint32>(option, defaultValue);
}

bool IsBlockingDisabled(Player const* player)
{
    return player->IsNonMeleeSpellCast(false, false, true) || player->HasUnitState(UNIT_STATE_CONTROLLED);
}

bool HasUsableShield(Player* player)
{
    if (!player->CanBlock())
    {
        return false;
    }

    Item* shield = player->GetUseableItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
    return shield && !shield->IsBroken() && shield->GetTemplate() && shield->GetTemplate()->Block;
}

uint8 GetTalentRank(Player const* player, TalentEntry const* talentInfo)
{
    for (int8 rank = MAX_TALENT_RANK - 1; rank >= 0; --rank)
    {
        uint32 const spellId = talentInfo->RankID[rank];
        if (!spellId)
        {
            continue;
        }

        PlayerTalentMap const& talents = player->GetTalentMap();
        PlayerTalentMap::const_iterator itr = talents.find(spellId);
        if (itr != talents.end() && itr->second->specMask & player->GetActiveSpecMask())
        {
            return uint8(rank + 1);
        }
    }

    return 0;
}

std::array<uint32, PALADIN_TREE_MAX> GetActivePaladinTalentPoints(Player const* player)
{
    std::array<uint32, PALADIN_TREE_MAX> points = { };

    for (uint32 talentId = 0; talentId < sTalentStore.GetNumRows(); ++talentId)
    {
        TalentEntry const* talentInfo = sTalentStore.LookupEntry(talentId);
        if (!talentInfo)
        {
            continue;
        }

        TalentTabEntry const* tab = sTalentTabStore.LookupEntry(talentInfo->TalentTab);
        if (!tab || !(tab->ClassMask & player->getClassMask()) || tab->tabpage >= PALADIN_TREE_MAX)
        {
            continue;
        }

        points[tab->tabpage] += GetTalentRank(player, talentInfo);
    }

    return points;
}

PaladinSpellBlockSpec GetPaladinSpellBlockSpec(Player const* player)
{
    std::array<uint32, PALADIN_TREE_MAX> const points = GetActivePaladinTalentPoints(player);

    uint32 const holyMin = GetConfigUInt("PaladinSpellBlock.MinHolyPoints", 10);
    uint32 const protectionMin = GetConfigUInt("PaladinSpellBlock.MinProtectionPoints", 10);
    bool const allowDominantTree = sConfigMgr->GetOption<bool>("PaladinSpellBlock.AllowDominantTree", false);

    PaladinSpellBlockSpec spec;
    spec.holy = points[PALADIN_TREE_HOLY] >= holyMin;
    spec.protection = points[PALADIN_TREE_PROTECTION] >= protectionMin;

    if (allowDominantTree && !spec.holy && !spec.protection)
    {
        uint32 const dominant = std::max({
            points[PALADIN_TREE_HOLY],
            points[PALADIN_TREE_PROTECTION],
            points[PALADIN_TREE_RETRIBUTION]
        });
        spec.holy = dominant > 0 && points[PALADIN_TREE_HOLY] == dominant;
        spec.protection = dominant > 0 && points[PALADIN_TREE_PROTECTION] == dominant;
    }

    return spec;
}

bool IsEligibleSpell(Unit const* target, Unit const* attacker, SpellInfo const* spellInfo)
{
    if (!attacker || !spellInfo || spellInfo->IsPositive() || !attacker->IsHostileTo(target))
    {
        return false;
    }

    if (spellInfo->DmgClass != SPELL_DAMAGE_CLASS_MAGIC && spellInfo->DmgClass != SPELL_DAMAGE_CLASS_NONE)
    {
        return false;
    }

    if (spellInfo->IsAffectingArea() && !sConfigMgr->GetOption<bool>("PaladinSpellBlock.AllowAreaSpells", false))
    {
        return false;
    }

    return true;
}

bool TryPaladinSpellBlock(Unit* target, Unit* attacker, SpellInfo const* spellInfo, SpellMissInfo& missInfo)
{
    if (!sConfigMgr->GetOption<bool>("PaladinSpellBlock.Enable", true) || !target || !target->IsPlayer())
    {
        return false;
    }

    Player* player = target->ToPlayer();
    if (player->getClass() != CLASS_PALADIN || !player->IsAlive() || IsBlockingDisabled(player))
    {
        return false;
    }

    if (sConfigMgr->GetOption<bool>("PaladinSpellBlock.RequireShield", true) && !HasUsableShield(player))
    {
        return false;
    }

    if (sConfigMgr->GetOption<bool>("PaladinSpellBlock.RequireFrontArc", true) &&
        attacker && !player->HasInArc(M_PI, attacker) && !player->HasIgnoreHitDirectionAura())
    {
        return false;
    }

    if (!IsEligibleSpell(player, attacker, spellInfo))
    {
        return false;
    }

    PaladinSpellBlockSpec const spec = GetPaladinSpellBlockSpec(player);
    if (!spec.holy && !spec.protection)
    {
        return false;
    }

    float chance = sConfigMgr->GetOption<bool>("PaladinSpellBlock.UseRealBlockChance", true)
        ? player->GetUnitBlockChance()
        : 0.0f;
    if (spec.holy)
    {
        chance += GetConfigFloat("PaladinSpellBlock.HolyBonusChance", 6.0f);
    }

    if (spec.protection)
    {
        chance += GetConfigFloat("PaladinSpellBlock.ProtectionBonusChance", 10.0f);
    }

    chance = std::clamp(chance, 0.0f, GetConfigFloat("PaladinSpellBlock.MaxChance", 35.0f));
    if (!roll_chance_f(chance))
    {
        return false;
    }

    missInfo = SPELL_MISS_BLOCK;

    if (sConfigMgr->GetOption<bool>("PaladinSpellBlock.PlayAnimation", false))
    {
        player->HandleEmoteCommand(EMOTE_ONESHOT_PARRY_SHIELD);
    }

    return true;
}
}

class PaladinSpellBlockUnitScript : public UnitScript
{
public:
    PaladinSpellBlockUnitScript() : UnitScript("PaladinSpellBlockUnitScript") { }

    bool OnMagicSpellHitResult(Unit* caster, Unit* target, SpellInfo const* spellInfo, SpellMissInfo& missInfo) override
    {
        return TryPaladinSpellBlock(target, caster, spellInfo, missInfo);
    }
};

void Addmod_paladin_spell_blockScripts()
{
    new PaladinSpellBlockUnitScript();
}

/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 */

#include "CellImpl.h"
#include "DBCStores.h"
#include "GameObject.h"
#include "GlobalScript.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Item.h"
#include "Log.h"
#include "Player.h"
#include "PlayerScript.h"
#include "Random.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "Unit.h"
#include "UnitScript.h"
#include "WorldPacket.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <list>
#include <unordered_map>
#include <unordered_set>

enum WowForeverRacialSpells : uint32
{
    SPELL_WF_SHATTER_CURSE        = 910001,
    SPELL_WF_BERSERKING           = 20554,
    SPELL_DA_VOODOO_SHUFFLE       = 58943,
    SPELL_WF_CULTIVATION          = 20552,
    SPELL_WF_PLAINSRUNNING        = 910013,
    SPELL_WF_PLAINSRUNNING_SPEED  = 910016,
    SPELL_WF_RAPID_REGENERATION   = 910017,
    SPELL_WF_TOUCH_GRAVE_MELEE    = 910018,
    SPELL_WF_TOUCH_GRAVE_CASTER   = 910019,
    SPELL_VAMPIRIC_TOUCH_HEAL     = 52724,
    SPELL_WF_BIG_GAME_HUNTER      = 910020,
    SPELL_WF_MACE_SPECIALIZATION  = 910021,
    SPELL_WF_STONEFORM_REDUCTION  = 910022,
    SPELL_WF_EXPANSIVE_MIND_RAGE  = 910023,
    SPELL_WF_EXPANSIVE_MIND_ENERGY = 910024,
    SPELL_WF_EXPANSIVE_MIND_RUNIC_POWER = 910042,
    SPELL_WF_EUREKA_ROGUE         = 910025,
    SPELL_WF_EUREKA_WARRIOR       = 910026,
    SPELL_WF_EUREKA_WARLOCK       = 910027,
    SPELL_WF_EUREKA_PRIEST        = 910028,
    SPELL_WF_WILL_TO_SURVIVE      = 910029,
    SPELL_WF_ELUNES_LIGHT         = 910031,
    SPELL_WF_WISP_SPIRIT_SPEED    = 910032,
};

namespace
{
constexpr float CULTIVATION_RANGE = 5.0f;
constexpr uint32 CULTIVATION_DESPAWN_SECONDS = 10 * MINUTE;
constexpr uint32 CULTIVATION_ENTRY_OFFSET = 1000000;
constexpr uint32 PLAINSRUNNING_GAIN_TICK_MS = 5 * IN_MILLISECONDS;
constexpr uint32 PLAINSRUNNING_DECAY_TICK_MS = IN_MILLISECONDS;
constexpr uint8 PLAINSRUNNING_MAX_BONUS = 30;
constexpr uint8 PLAINSRUNNING_DAMAGE_DECAY = 5;
constexpr uint8 RAPID_REGENERATION_TICK_PCT = 10;
constexpr uint8 RAPID_REGENERATION_TICKS = 5;
constexpr uint32 TOUCH_GRAVE_COOLDOWN_MS = IN_MILLISECONDS;
constexpr uint8 TOUCH_GRAVE_DRAIN_PCT = 5;
constexpr uint8 TOUCH_GRAVE_MELEE_CHANCE = 5;
constexpr uint8 TOUCH_GRAVE_CASTER_CHANCE = 10;

struct PlainsrunningState
{
    uint32 MovingTime = 0;
    uint32 StillTime = 0;
    uint8 Bonus = 0;
};

struct PendingEurekaCharge
{
    uint32 AuraSpellId = 0;
    uint32 CastSpellId = 0;
    uint8 ChargesBeforeCast = 0;
};

std::unordered_map<ObjectGuid, PlainsrunningState> PlainsrunningStates;
std::unordered_map<ObjectGuid, PendingEurekaCharge> PendingEurekaCharges;
std::unordered_map<ObjectGuid, uint32> TouchOfGraveCooldowns;
std::unordered_set<ObjectGuid> CultivatedHerbs;

bool IsWeaponSubclass(Item const* item, uint32 subclass1, uint32 subclass2)
{
    if (!item || item->GetTemplate()->Class != ITEM_CLASS_WEAPON)
        return false;

    uint32 subclass = item->GetTemplate()->SubClass;
    return subclass == subclass1 || subclass == subclass2;
}

bool HasWeaponSubclass(Player const* player, uint32 subclass1, uint32 subclass2)
{
    return IsWeaponSubclass(player->GetWeaponForAttack(BASE_ATTACK), subclass1, subclass2)
        || IsWeaponSubclass(player->GetWeaponForAttack(OFF_ATTACK), subclass1, subclass2);
}

float GetWeaponCritBonus(Player const* player)
{
    if (player->getRace() == RACE_ORC && player->HasSpell(20574)
        && HasWeaponSubclass(player, ITEM_SUBCLASS_WEAPON_AXE, ITEM_SUBCLASS_WEAPON_AXE2))
        return 1.0f;

    if (player->getRace() == RACE_DWARF && player->HasSpell(SPELL_WF_MACE_SPECIALIZATION)
        && HasWeaponSubclass(player, ITEM_SUBCLASS_WEAPON_MACE, ITEM_SUBCLASS_WEAPON_MACE2))
        return 1.0f;

    if (player->getRace() == RACE_HUMAN && player->HasSpell(20597)
        && HasWeaponSubclass(player, ITEM_SUBCLASS_WEAPON_SWORD, ITEM_SUBCLASS_WEAPON_SWORD2))
        return 2.0f;

    return 0.0f;
}

bool IsRemovableStoneformDebuff(AuraApplication const* aura)
{
    if (!aura || aura->IsPositive())
        return false;

    SpellInfo const* spellInfo = aura->GetBase()->GetSpellInfo();
    return spellInfo->Dispel == DISPEL_DISEASE
        || spellInfo->Dispel == DISPEL_POISON
        || (spellInfo->GetAllEffectsMechanicMask() & (1ULL << MECHANIC_BLEED));
}

bool IsHerbalismNode(GameObject const* gameObject)
{
    if (!gameObject || gameObject->GetGoType() != GAMEOBJECT_TYPE_CHEST)
        return false;

    LockEntry const* lock = sLockStore.LookupEntry(gameObject->GetGOInfo()->GetLockId());
    if (!lock)
        return false;

    for (uint8 i = 0; i < MAX_LOCK_CASE; ++i)
        if (lock->Type[i] == LOCK_KEY_SKILL && SkillByLockType(LockType(lock->Index[i])) == SKILL_HERBALISM)
            return true;

    return false;
}

GameObject* FindCultivationHerb(Player const* player)
{
    std::list<GameObject*> gameObjects;
    Acore::GameObjectInRangeCheck check(player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(),
        CULTIVATION_RANGE);
    Acore::GameObjectListSearcher<Acore::GameObjectInRangeCheck> searcher(player, gameObjects, check);
    Cell::VisitObjects(player, searcher, CULTIVATION_RANGE);

    GameObject* nearest = nullptr;
    float nearestDistance = CULTIVATION_RANGE;
    for (GameObject* gameObject : gameObjects)
    {
        if (!IsHerbalismNode(gameObject) || !gameObject->isSpawned() || gameObject->getLootState() != GO_READY
            || gameObject->GetOwnerGUID() || !player->IsWithinLOSInMap(gameObject)
            || CultivatedHerbs.contains(gameObject->GetGUID()))
            continue;

        float distance = player->GetDistance(gameObject);
        if (!nearest || distance < nearestDistance)
        {
            nearest = gameObject;
            nearestDistance = distance;
        }
    }

    return nearest;
}

bool IsPlainsrunningMovementAllowed(Player const* player)
{
    uint32 const movementFlags = MOVEMENTFLAG_FORWARD | MOVEMENTFLAG_BACKWARD | MOVEMENTFLAG_STRAFE_LEFT |
        MOVEMENTFLAG_STRAFE_RIGHT;

    return player->getRace() == RACE_TAUREN
        && player->HasSpell(SPELL_WF_PLAINSRUNNING)
        && player->IsAlive()
        && !player->IsMounted()
        && !player->GetVehicle()
        && !player->IsInFlight()
        && !player->IsFlying()
        && !player->isSwimming()
        && !player->IsInWater()
        && !player->IsWalking()
        && player->HasUnitMovementFlag(movementFlags);
}

void ApplyPlainsrunning(Player* player, PlainsrunningState& state)
{
    if (!state.Bonus)
    {
        player->RemoveAura(SPELL_WF_PLAINSRUNNING_SPEED);
        return;
    }

    Aura* aura = player->GetAura(SPELL_WF_PLAINSRUNNING_SPEED);
    if (!aura)
        aura = player->AddAura(SPELL_WF_PLAINSRUNNING_SPEED, player);

    if (aura && aura->GetStackAmount() != state.Bonus)
        aura->SetStackAmount(state.Bonus);
}

void DecayPlainsrunning(Player* player, uint8 amount)
{
    auto itr = PlainsrunningStates.find(player->GetGUID());
    if (itr == PlainsrunningStates.end())
        return;

    PlainsrunningState& state = itr->second;
    if (!state.Bonus)
        return;

    state.Bonus = state.Bonus > amount ? state.Bonus - amount : 0;
    state.MovingTime = 0;
    ApplyPlainsrunning(player, state);
}

void CancelRapidRegeneration(Player* player)
{
    player->RemoveAura(SPELL_WF_RAPID_REGENERATION);
}

uint8 GetTouchOfGraveChance(Player const* player)
{
    if (player->HasSpell(SPELL_WF_TOUCH_GRAVE_CASTER))
        return TOUCH_GRAVE_CASTER_CHANCE;

    if (player->HasSpell(SPELL_WF_TOUCH_GRAVE_MELEE))
        return TOUCH_GRAVE_MELEE_CHANCE;

    return 0;
}

void TryTouchOfGrave(Player* player, Unit* victim)
{
    if (!player || !victim || player->getRace() != RACE_UNDEAD_PLAYER || player == victim)
        return;

    if (!player->IsValidAttackTarget(victim))
        return;

    uint8 chance = GetTouchOfGraveChance(player);
    if (!chance || TouchOfGraveCooldowns[player->GetGUID()] || !roll_chance_i(chance))
        return;

    TouchOfGraveCooldowns[player->GetGUID()] = TOUCH_GRAVE_COOLDOWN_MS;
    uint32 damage = player->CountPctFromMaxHealth(TOUCH_GRAVE_DRAIN_PCT);
    uint32 actualDamage = Unit::DealDamage(player, victim, damage, nullptr, DIRECT_DAMAGE, SPELL_SCHOOL_MASK_SHADOW,
        nullptr, false);
    if (actualDamage)
        player->CastCustomSpell(SPELL_VAMPIRIC_TOUCH_HEAL, SPELLVALUE_BASE_POINT0, actualDamage, player, true);
}

void LearnIfMissing(Player* player, uint32 spellId)
{
    if (!player->HasSpell(spellId))
        player->learnSpell(spellId);
}

void RemoveIfKnown(Player* player, uint32 spellId)
{
    player->RemoveAura(spellId);

    if (player->HasSpell(spellId))
        player->removeSpell(spellId, SPEC_MASK_ALL, false);
}

void AddActionIfEmpty(Player* player, uint8 button, uint32 spellId)
{
    if (!player->GetActionButton(button))
        player->addActionButton(button, spellId, ACTION_BUTTON_SPELL);
}

void UpdateWispSpirit(Player* player)
{
    if (player->getRace() == RACE_NIGHTELF && player->HasSpell(20585)
        && player->HasPlayerFlag(PLAYER_FLAGS_GHOST))
    {
        if (!player->HasAura(SPELL_WF_WISP_SPIRIT_SPEED))
            player->CastSpell(player, SPELL_WF_WISP_SPIRIT_SPEED, true);

        return;
    }

    player->RemoveAura(SPELL_WF_WISP_SPIRIT_SPEED);
}

void EnsureRacials(Player* player)
{
    switch (player->getRace())
    {
        case RACE_ORC:
            LearnIfMissing(player, SPELL_WF_SHATTER_CURSE);
            AddActionIfEmpty(player, 75, SPELL_WF_SHATTER_CURSE);
            break;
        case RACE_TAUREN:
            LearnIfMissing(player, SPELL_WF_CULTIVATION);
            LearnIfMissing(player, SPELL_WF_PLAINSRUNNING);
            AddActionIfEmpty(player, 75, SPELL_WF_CULTIVATION);
            break;
        case RACE_TROLL:
            RemoveIfKnown(player, SPELL_DA_VOODOO_SHUFFLE);
            LearnIfMissing(player, SPELL_WF_BERSERKING);
            LearnIfMissing(player, SPELL_WF_RAPID_REGENERATION);
            AddActionIfEmpty(player, 75, SPELL_WF_BERSERKING);
            AddActionIfEmpty(player, 76, SPELL_WF_RAPID_REGENERATION);
            break;
        case RACE_UNDEAD_PLAYER:
            RemoveIfKnown(player, SPELL_WF_RAPID_REGENERATION);

            if (player->getClass() == CLASS_WARRIOR || player->getClass() == CLASS_PALADIN
                || player->getClass() == CLASS_ROGUE)
            {
                RemoveIfKnown(player, SPELL_WF_TOUCH_GRAVE_CASTER);
                LearnIfMissing(player, SPELL_WF_TOUCH_GRAVE_MELEE);
            }
            else if (player->getClass() == CLASS_PRIEST || player->getClass() == CLASS_MAGE
                || player->getClass() == CLASS_WARLOCK)
            {
                RemoveIfKnown(player, SPELL_WF_TOUCH_GRAVE_MELEE);
                LearnIfMissing(player, SPELL_WF_TOUCH_GRAVE_CASTER);
            }
            else
            {
                RemoveIfKnown(player, SPELL_WF_TOUCH_GRAVE_MELEE);
                RemoveIfKnown(player, SPELL_WF_TOUCH_GRAVE_CASTER);
            }
            break;
        case RACE_DWARF:
            LearnIfMissing(player, SPELL_WF_BIG_GAME_HUNTER);
            LearnIfMissing(player, SPELL_WF_MACE_SPECIALIZATION);
            break;
        case RACE_GNOME:
            RemoveIfKnown(player, 20592);
            LearnIfMissing(player, 20589);
            LearnIfMissing(player, 20593);
            if (player->getClass() != CLASS_WARRIOR)
                RemoveIfKnown(player, SPELL_WF_EXPANSIVE_MIND_RAGE);
            if (player->getClass() != CLASS_ROGUE)
                RemoveIfKnown(player, SPELL_WF_EXPANSIVE_MIND_ENERGY);
            if (player->getClass() == CLASS_PALADIN || player->getClass() == CLASS_HUNTER
                || player->getClass() == CLASS_PRIEST || player->getClass() == CLASS_SHAMAN
                || player->getClass() == CLASS_MAGE || player->getClass() == CLASS_WARLOCK
                || player->getClass() == CLASS_DRUID)
                LearnIfMissing(player, 20591);
            else
                RemoveIfKnown(player, 20591);
            if (player->getClass() == CLASS_WARRIOR)
            {
                LearnIfMissing(player, SPELL_WF_EXPANSIVE_MIND_RAGE);
                LearnIfMissing(player, SPELL_WF_EUREKA_WARRIOR);
                AddActionIfEmpty(player, 75, SPELL_WF_EUREKA_WARRIOR);
            }
            else if (player->getClass() == CLASS_ROGUE)
            {
                LearnIfMissing(player, SPELL_WF_EXPANSIVE_MIND_ENERGY);
                LearnIfMissing(player, SPELL_WF_EUREKA_ROGUE);
                AddActionIfEmpty(player, 75, SPELL_WF_EUREKA_ROGUE);
            }
            else if (player->getClass() == CLASS_DEATH_KNIGHT)
                LearnIfMissing(player, SPELL_WF_EXPANSIVE_MIND_RUNIC_POWER);
            else if (player->getClass() == CLASS_WARLOCK)
            {
                LearnIfMissing(player, SPELL_WF_EUREKA_WARLOCK);
                AddActionIfEmpty(player, 75, SPELL_WF_EUREKA_WARLOCK);
            }
            else if (player->getClass() == CLASS_PRIEST)
            {
                LearnIfMissing(player, SPELL_WF_EUREKA_PRIEST);
                AddActionIfEmpty(player, 75, SPELL_WF_EUREKA_PRIEST);
            }
            break;
        case RACE_HUMAN:
            LearnIfMissing(player, SPELL_WF_WILL_TO_SURVIVE);
            AddActionIfEmpty(player, 76, SPELL_WF_WILL_TO_SURVIVE);
            break;
        case RACE_NIGHTELF:
            LearnIfMissing(player, 20580);
            LearnIfMissing(player, SPELL_WF_ELUNES_LIGHT);
            AddActionIfEmpty(player, 75, 20580);
            AddActionIfEmpty(player, 76, SPELL_WF_ELUNES_LIGHT);
            break;
        default:
            break;
    }
}
}

namespace
{
bool IsEurekaAbility(SpellInfo const* spell, bool healing, uint8 depth = 0)
{
    if (!spell || spell->IsPassive() || depth > 3)
        return false;

    // These parent abilities deal their damage/healing through a class script.
    uint32 firstRank = sSpellMgr->GetFirstSpellInChain(spell->Id);
    if (firstRank == 5308 || firstRank == 47540)
        return true;

    for (SpellEffectInfo const& effect : spell->Effects)
    {
        switch (effect.Effect)
        {
            case SPELL_EFFECT_SCHOOL_DAMAGE:
            case SPELL_EFFECT_WEAPON_DAMAGE:
            case SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL:
            case SPELL_EFFECT_NORMALIZED_WEAPON_DMG:
            case SPELL_EFFECT_WEAPON_PERCENT_DAMAGE:
            case SPELL_EFFECT_HEALTH_LEECH:
            case SPELL_EFFECT_POWER_BURN:
                return true;
            case SPELL_EFFECT_HEAL:
            case SPELL_EFFECT_HEAL_MAX_HEALTH:
                if (healing)
                    return true;
                break;
            default:
                break;
        }

        switch (effect.ApplyAuraName)
        {
            case SPELL_AURA_PERIODIC_DAMAGE:
            case SPELL_AURA_PERIODIC_DAMAGE_PERCENT:
            case SPELL_AURA_PERIODIC_LEECH:
                return true;
            case SPELL_AURA_PERIODIC_HEAL:
                if (healing)
                    return true;
                break;
            default:
                break;
        }

        // Includes Mutilate and channel parents, but excludes proc auras and weapon enchants.
        if ((effect.Effect == SPELL_EFFECT_TRIGGER_SPELL
            || effect.ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL)
            && IsEurekaAbility(sSpellMgr->GetSpellInfo(effect.TriggerSpell), healing, depth + 1))
            return true;
    }

    return false;
}

uint32 GetEurekaAuraForCast(Player const* player, SpellInfo const* spell)
{
    if (!player || !spell || player->getRace() != RACE_GNOME)
        return 0;

    uint32 auraSpellId = 0;
    uint32 family = 0;
    Powers power = POWER_MANA;
    switch (player->getClass())
    {
        case CLASS_ROGUE: auraSpellId = 910037; family = SPELLFAMILY_ROGUE; power = POWER_ENERGY; break;
        case CLASS_WARRIOR: auraSpellId = 910038; family = SPELLFAMILY_WARRIOR; power = POWER_RAGE; break;
        case CLASS_WARLOCK: auraSpellId = 910039; family = SPELLFAMILY_WARLOCK; power = POWER_MANA; break;
        case CLASS_PRIEST: auraSpellId = 910040; family = SPELLFAMILY_PRIEST; power = POWER_MANA; break;
        default: return 0;
    }

    if (spell->Id == auraSpellId || spell->PowerType != power
        || spell->SpellFamilyName != family
        || !IsEurekaAbility(spell, player->getClass() == CLASS_PRIEST))
        return 0;

    return auraSpellId;
}
}

class gnome_eureka_modifiers : public GlobalScript
{
public:
    gnome_eureka_modifiers() : GlobalScript("gnome_eureka_modifiers",
        { GLOBALHOOK_ON_IS_AFFECTED_BY_SPELL_MOD_CHECK }) { }

    bool OnIsAffectedBySpellModCheck(SpellInfo const* affectSpell, SpellInfo const* checkSpell,
        SpellModifier const* mod) override
    {
        uint32 family;
        Powers power;
        switch (affectSpell->Id)
        {
            case 910037: family = SPELLFAMILY_ROGUE; power = POWER_ENERGY; break;
            case 910038: family = SPELLFAMILY_WARRIOR; power = POWER_RAGE; break;
            case 910039: family = SPELLFAMILY_WARLOCK; power = POWER_MANA; break;
            case 910040: family = SPELLFAMILY_PRIEST; power = POWER_MANA; break;
            default: return true;
        }

        // Returning false accepts the modifier; the private family sentinel rejects all others.
        // Native charged spellmods snapshot DoTs/HoTs and consume once per completed cast, not per hit.
        if (!mod->ownerAura || !mod->ownerAura->GetOwner()->IsPlayer())
            return true;

        return checkSpell->SpellFamilyName != family || checkSpell->PowerType != power
            || !IsEurekaAbility(checkSpell, family == SPELLFAMILY_PRIEST);
    }
};

class gnome_expansive_mind : public PlayerScript
{
public:
    gnome_expansive_mind() : PlayerScript("gnome_expansive_mind",
        { PLAYERHOOK_ON_AFTER_UPDATE_MAX_POWER }) { }

    void OnPlayerAfterUpdateMaxPower(Player* player, Powers& power, float& value) override
    {
        if (player->getRace() != RACE_GNOME)
            return;

        uint32 spellId = power == POWER_MANA ? 20591 : power == POWER_RAGE ? SPELL_WF_EXPANSIVE_MIND_RAGE
            : power == POWER_ENERGY ? SPELL_WF_EXPANSIVE_MIND_ENERGY
            : power == POWER_RUNIC_POWER ? SPELL_WF_EXPANSIVE_MIND_RUNIC_POWER : 0;
        if (!spellId || (!player->HasSpell(spellId) && !player->HasAura(spellId)))
            return;

        // The aura normally supplies this multiplier. Normalize it first so the racial remains exactly 5%
        // when the passive aura is active, and still works for characters where the aura was not applied.
        if (player->HasAura(spellId))
            value /= 1.05f;

        // 100 * 1.05f may otherwise truncate to 104 when SetMaxPower converts it to uint32.
        value = std::nextafter(value * 1.05f, std::numeric_limits<float>::infinity());
    }
};

class spell_wf_racial_blood_fury : public AuraScript
{
    PrepareAuraScript(spell_wf_racial_blood_fury);

    void CalculateSpellPower(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = false;

        Player* player = GetUnitOwner()->ToPlayer();
        if (!player)
        {
            amount = 0;
            return;
        }

        int32 spellPower = player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_ALL);
        for (uint8 school = SPELL_SCHOOL_HOLY; school < MAX_SPELL_SCHOOL; ++school)
            spellPower = std::max(spellPower, player->SpellBaseDamageBonusDone(SpellSchoolMask(1 << school)));

        amount = CalculatePct(std::max(spellPower, 0), 10);
    }

    void HandleSpellPower(AuraEffect const* aurEff, AuraEffectHandleModes /*mode*/, bool apply)
    {
        if (Player* player = GetTarget()->ToPlayer())
            player->ApplySpellPowerBonus(aurEff->GetAmount(), apply);
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes mode)
    {
        HandleSpellPower(aurEff, mode, true);
    }

    void HandleRemove(AuraEffect const* aurEff, AuraEffectHandleModes mode)
    {
        HandleSpellPower(aurEff, mode, false);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_wf_racial_blood_fury::CalculateSpellPower, EFFECT_2,
            SPELL_AURA_DUMMY);
        OnEffectApply += AuraEffectApplyFn(spell_wf_racial_blood_fury::HandleApply, EFFECT_2,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectRemove += AuraEffectRemoveFn(spell_wf_racial_blood_fury::HandleRemove, EFFECT_2,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_wf_racial_cultivation : public SpellScript
{
    PrepareSpellScript(spell_wf_racial_cultivation);

    SpellCastResult CheckCast()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getRace() != RACE_TAUREN || !FindCultivationHerb(player))
            return SPELL_FAILED_BAD_TARGETS;

        return SPELL_CAST_OK;
    }

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player)
            return;

        GameObject* herb = FindCultivationHerb(player);
        if (!herb)
            return;

        Position position = player->GetRandomNearPosition(3.0f);
        GameObject* duplicate = player->SummonGameObject(herb->GetEntry() + CULTIVATION_ENTRY_OFFSET,
            position.GetPositionX(), position.GetPositionY(), position.GetPositionZ(), position.GetOrientation(),
            0.0f, 0.0f, 0.0f, 1.0f,
            CULTIVATION_DESPAWN_SECONDS);
        if (!duplicate)
            return;

        CultivatedHerbs.insert(herb->GetGUID());
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_wf_racial_cultivation::CheckCast);
        OnEffectHitTarget += SpellEffectFn(spell_wf_racial_cultivation::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_wf_racial_rapid_regeneration : public AuraScript
{
    PrepareAuraScript(spell_wf_racial_rapid_regeneration);

    void HandlePeriodic(AuraEffect const* aurEff)
    {
        Unit* target = GetTarget();
        if (!target)
            return;

        Unit::DealHeal(target, target, target->CountPctFromMaxHealth(RAPID_REGENERATION_TICK_PCT));
        if (aurEff->GetTickNumber() >= RAPID_REGENERATION_TICKS)
            target->RemoveAura(SPELL_WF_RAPID_REGENERATION);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_wf_racial_rapid_regeneration::HandlePeriodic, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
    }
};

// Shadowmeld starts its cooldown when the aura ends.
class spell_wf_racial_shadowmeld_aura : public AuraScript
{
    PrepareAuraScript(spell_wf_racial_shadowmeld_aura);

    bool _usedInCombat = false;

    void HandleRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        LOG_DEBUG("server.racial.shadowmeld", "Shadowmeld remove: player={} combatCast={}",
            GetTarget()->GetGUID().ToString(), _usedInCombat);
        if (!_usedInCombat)
            return;

        // A positive SMSG_MODIFY_COOLDOWN shifts the client's start time into the future,
        // leaving its duration at 10 seconds. Send a complete event cooldown for the sweep.
        if (Player* player = GetTarget()->ToPlayer())
        {
            uint32 const cooldown = 2 * MINUTE * IN_MILLISECONDS;
            player->RemoveSpellCooldown(20580, true);
            player->AddSpellCooldown(20580, 0, cooldown, true);

            WorldPacket data;
            player->BuildCooldownPacket(data,
                SPELL_COOLDOWN_FLAG_INCLUDE_GCD | SPELL_COOLDOWN_FLAG_INCLUDE_EVENT_COOLDOWNS, 20580, cooldown);
            player->SendDirectMessage(&data);
            LOG_DEBUG("server.racial.shadowmeld", "Shadowmeld extended: player={} remainingMs={}",
                player->GetGUID().ToString(), player->GetSpellCooldownDelay(20580));
        }
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_wf_racial_shadowmeld_aura::HandleRemove, EFFECT_0,
            SPELL_AURA_MOD_STEALTH, AURA_EFFECT_HANDLE_REAL);
    }

public:
    void SetUsedInCombat(bool usedInCombat) { _usedInCombat = usedInCombat; }
};

class spell_wf_racial_shadowmeld : public SpellScript
{
    PrepareSpellScript(spell_wf_racial_shadowmeld);

    bool _usedInCombat = false;

    void HandleBeforeCast()
    {
        _usedInCombat = GetCaster()->IsInCombat();
        LOG_DEBUG("server.racial.shadowmeld", "Shadowmeld cast: player={} combat={}",
            GetCaster()->GetGUID().ToString(), _usedInCombat);
    }

    void HandleAfterHit()
    {
        if (Aura* aura = GetHitAura())
            if (auto* script = aura->GetScript<spell_wf_racial_shadowmeld_aura>("spell_wf_racial_shadowmeld"))
            {
                script->SetUsedInCombat(_usedInCombat);
                LOG_DEBUG("server.racial.shadowmeld", "Shadowmeld aura received combat={}", _usedInCombat);
            }
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_wf_racial_shadowmeld::HandleBeforeCast);
        AfterHit += SpellHitFn(spell_wf_racial_shadowmeld::HandleAfterHit);
    }
};

class spell_wf_racial_stoneform : public SpellScript
{
    PrepareSpellScript(spell_wf_racial_stoneform);

    void HandleAfterCast()
    {
        Unit* caster = GetCaster();
        caster->RemoveAppliedAuras(IsRemovableStoneformDebuff);
        caster->CastSpell(caster, SPELL_WF_STONEFORM_REDUCTION, true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_wf_racial_stoneform::HandleAfterCast);
    }
};

class spell_wf_racial_unit : public UnitScript
{
public:
    spell_wf_racial_unit() : UnitScript("spell_wf_racial_unit", true, {
        UNITHOOK_ON_DAMAGE,
        UNITHOOK_MODIFY_SPELL_CRIT_CHANCE,
        UNITHOOK_ON_BEFORE_ROLL_MELEE_OUTCOME_AGAINST
    }) { }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (!damage)
            return;

        if (Player* player = victim ? victim->ToPlayer() : nullptr)
        {
            if (player->getRace() == RACE_TAUREN)
                DecayPlainsrunning(player, PLAINSRUNNING_DAMAGE_DECAY);

            if (player->getRace() == RACE_TROLL)
                CancelRapidRegeneration(player);
        }

        if (Player* player = attacker ? attacker->ToPlayer() : nullptr)
            TryTouchOfGrave(player, victim);
    }

    void OnBeforeRollMeleeOutcomeAgainst(Unit const* attacker, Unit const* /*victim*/, WeaponAttackType /*attType*/,
        int32& /*attackerMaxSkillValueForLevel*/, int32& /*victimMaxSkillValueForLevel*/,
        int32& /*attackerWeaponSkill*/, int32& /*victimDefenseSkill*/, int32& critChance, int32& /*missChance*/,
        int32& /*dodgeChance*/, int32& /*parryChance*/, int32& /*blockChance*/) override
    {
        if (Player const* player = attacker ? attacker->ToPlayer() : nullptr)
            critChance += int32(GetWeaponCritBonus(player) * 100.0f);
    }

    void ModifySpellCritChance(Unit const* caster, Unit const* /*victim*/, SpellInfo const* /*spellInfo*/,
        SpellSchoolMask /*schoolMask*/, WeaponAttackType /*attackType*/, float& critChance) override
    {
        Player const* player = caster ? caster->ToPlayer() : nullptr;
        if (!player)
            return;

        critChance += GetWeaponCritBonus(player);
    }
};

class gnome_eureka_quest_marker : public UnitScript
{
public:
    gnome_eureka_quest_marker() : UnitScript("gnome_eureka_quest_marker") { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (!unit->IsPlayer() || unit->ToPlayer()->getRace() != RACE_GNOME || !IsEurekaAura(aura->GetId()))
            return;

        unit->SetNpcFlag(UNIT_NPC_FLAG_QUESTGIVER);
        SendQuestMarkerStatus(unit, DIALOG_STATUS_AVAILABLE);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* aurApp, AuraRemoveMode /*mode*/) override
    {
        Aura* aura = aurApp->GetBase();
        if (!unit->IsPlayer() || unit->ToPlayer()->getRace() != RACE_GNOME || !IsEurekaAura(aura->GetId()))
            return;

        // Another class-specific Eureka aura may still be active after an aura replacement.
        for (uint32 spellId : { 910037, 910038, 910039, 910040 })
            if (spellId != aura->GetId() && unit->HasAura(spellId))
                return;

        unit->RemoveNpcFlag(UNIT_NPC_FLAG_QUESTGIVER);
        SendQuestMarkerStatus(unit, DIALOG_STATUS_NONE);
    }

private:
    static bool IsEurekaAura(uint32 spellId)
    {
        return spellId >= 910037 && spellId <= 910040;
    }

    static void SendQuestMarkerStatus(Unit* unit, uint8 status)
    {
        WorldPacket data(SMSG_QUESTGIVER_STATUS, 9);
        data << unit->GetGUID();
        data << status;
        unit->SendMessageToSet(&data, true);
    }
};

class spell_wf_racial_player : public PlayerScript
{
public:
    spell_wf_racial_player() : PlayerScript("spell_wf_racial_player", {
        PLAYERHOOK_ON_LOGIN,
        PLAYERHOOK_ON_SPELL_CAST,
        PLAYERHOOK_ON_UPDATE,
        PLAYERHOOK_ON_LOGOUT
    }) { }

    void OnPlayerLogin(Player* player) override
    {
        EnsureRacials(player);
    }

    void OnPlayerSpellCast(Player* player, Spell* spell, bool /*skipCheck*/) override
    {
        if (!spell)
            return;

        SpellInfo const* spellInfo = spell->GetSpellInfo();

        if (!spell->IsTriggered())
        {
            uint32 auraSpellId = GetEurekaAuraForCast(player, spellInfo);
            Aura* eurekaAura = auraSpellId ? player->GetAura(auraSpellId) : nullptr;
            if (eurekaAura && eurekaAura->GetCharges())
                PendingEurekaCharges[player->GetGUID()] = { auraSpellId, spellInfo->Id, eurekaAura->GetCharges() };
        }

        if (player->getRace() == RACE_TROLL && player->HasAura(SPELL_WF_RAPID_REGENERATION)
            && spellInfo->Id != SPELL_WF_RAPID_REGENERATION)
            CancelRapidRegeneration(player);
    }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (auto pending = PendingEurekaCharges.find(player->GetGUID()); pending != PendingEurekaCharges.end())
        {
            Spell* channelSpell = player->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
            if (!channelSpell || channelSpell->GetSpellInfo()->Id != pending->second.CastSpellId)
            {
                Aura* eurekaAura = player->GetAura(pending->second.AuraSpellId);
                if (eurekaAura && eurekaAura->GetCharges() == pending->second.ChargesBeforeCast)
                    eurekaAura->DropCharge();
                PendingEurekaCharges.erase(pending);
            }
        }

        if (auto itr = TouchOfGraveCooldowns.find(player->GetGUID()); itr != TouchOfGraveCooldowns.end())
        {
            if (itr->second <= diff)
                TouchOfGraveCooldowns.erase(itr);
            else
                itr->second -= diff;
        }

        if (player->getRace() == RACE_TROLL && player->HasAura(SPELL_WF_RAPID_REGENERATION)
            && player->HasUnitMovementFlag(MOVEMENTFLAG_MASK_MOVING))
            CancelRapidRegeneration(player);

        UpdateWispSpirit(player);

        if (player->getRace() != RACE_TAUREN)
            return;

        PlainsrunningState& state = PlainsrunningStates[player->GetGUID()];
        if (IsPlainsrunningMovementAllowed(player))
        {
            state.StillTime = 0;
            if (state.Bonus >= PLAINSRUNNING_MAX_BONUS)
                return;

            state.MovingTime += diff;
            if (state.MovingTime < PLAINSRUNNING_GAIN_TICK_MS)
                return;

            state.MovingTime -= PLAINSRUNNING_GAIN_TICK_MS;
            ++state.Bonus;
            ApplyPlainsrunning(player, state);
            return;
        }

        state.MovingTime = 0;
        if (!state.Bonus)
            return;

        state.StillTime += diff;
        if (state.StillTime < PLAINSRUNNING_DECAY_TICK_MS)
            return;

        state.StillTime -= PLAINSRUNNING_DECAY_TICK_MS;
        --state.Bonus;
        ApplyPlainsrunning(player, state);
    }

    void OnPlayerLogout(Player* player) override
    {
        PlainsrunningStates.erase(player->GetGUID());
        PendingEurekaCharges.erase(player->GetGUID());
        TouchOfGraveCooldowns.erase(player->GetGUID());
    }
};

class spell_wf_racial_blood_fury_loader : public SpellScriptLoader
{
public:
    spell_wf_racial_blood_fury_loader() : SpellScriptLoader("spell_wf_racial_blood_fury") { }

    AuraScript* GetAuraScript() const override
    {
        return new spell_wf_racial_blood_fury();
    }
};

class spell_wf_racial_cultivation_loader : public SpellScriptLoader
{
public:
    spell_wf_racial_cultivation_loader() : SpellScriptLoader("spell_wf_racial_cultivation") { }

    SpellScript* GetSpellScript() const override
    {
        return new spell_wf_racial_cultivation();
    }
};

class spell_wf_racial_rapid_regeneration_loader : public SpellScriptLoader
{
public:
    spell_wf_racial_rapid_regeneration_loader() : SpellScriptLoader("spell_wf_racial_rapid_regeneration") { }

    AuraScript* GetAuraScript() const override
    {
        return new spell_wf_racial_rapid_regeneration();
    }
};

class spell_wf_racial_stoneform_loader : public SpellScriptLoader
{
public:
    spell_wf_racial_stoneform_loader() : SpellScriptLoader("spell_wf_racial_stoneform") { }

    SpellScript* GetSpellScript() const override
    {
        return new spell_wf_racial_stoneform();
    }
};

void AddSC_racial_spell_scripts()
{
    new gnome_eureka_modifiers();
    new gnome_expansive_mind();
    new gnome_eureka_quest_marker();
    new spell_wf_racial_blood_fury_loader();
    new spell_wf_racial_cultivation_loader();
    new spell_wf_racial_rapid_regeneration_loader();
    new spell_wf_racial_stoneform_loader();
    RegisterSpellAndAuraScriptPair(spell_wf_racial_shadowmeld, spell_wf_racial_shadowmeld_aura);
    new spell_wf_racial_unit();
    new spell_wf_racial_player();
}

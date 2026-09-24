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
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Item.h"
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
#include <algorithm>
#include <list>
#include <unordered_map>
#include <unordered_set>

enum WowForeverRacialSpells : uint32
{
    SPELL_WF_SHATTER_CURSE        = 910001,
    SPELL_WF_BERSERKING           = 20554,
    SPELL_WF_CULTIVATION          = 20552,
    SPELL_WF_PLAINSRUNNING        = 910013,
    SPELL_WF_PLAINSRUNNING_SPEED  = 910016,
    SPELL_WF_RAPID_REGENERATION   = 910017,
    SPELL_WF_TOUCH_GRAVE_MELEE    = 910018,
    SPELL_WF_TOUCH_GRAVE_CASTER   = 910019,
    SPELL_WF_BIG_GAME_HUNTER      = 910020,
    SPELL_WF_MACE_SPECIALIZATION  = 910021,
    SPELL_WF_STONEFORM_REDUCTION  = 910022,
    SPELL_WF_EXPANSIVE_MIND_RAGE  = 910023,
    SPELL_WF_EXPANSIVE_MIND_ENERGY = 910024,
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
constexpr uint32 CULTIVATION_DESPAWN_MS = 10 * MINUTE * IN_MILLISECONDS;
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
constexpr uint8 EXPANSIVE_MIND_RESOURCE_PCT = 5;
constexpr uint8 EUREKA_OUTPUT_PCT = 10;
constexpr uint8 EUREKA_CHARGES = 3;
constexpr uint8 ELUNES_LIGHT_CRIT_PCT = 10;

struct PlainsrunningState
{
    uint32 MovingTime = 0;
    uint32 StillTime = 0;
    uint8 Bonus = 0;
};

struct EurekaInfo
{
    uint8 Class = 0;
    Powers Power = POWER_MANA;
    uint8 CostReduction = 0;
    bool AffectsHealing = false;
};

std::unordered_map<ObjectGuid, PlainsrunningState> PlainsrunningStates;
std::unordered_map<ObjectGuid, uint32> TouchOfGraveCooldowns;
std::unordered_map<ObjectGuid, uint8> EurekaCharges;
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

    if (player->getRace() == RACE_NIGHTELF && player->HasAura(SPELL_WF_ELUNES_LIGHT))
        return ELUNES_LIGHT_CRIT_PCT;

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

bool IsGnomeEurekaSpell(uint32 spellId)
{
    return spellId == SPELL_WF_EUREKA_ROGUE
        || spellId == SPELL_WF_EUREKA_WARRIOR
        || spellId == SPELL_WF_EUREKA_WARLOCK
        || spellId == SPELL_WF_EUREKA_PRIEST;
}

bool HasAuraEffect(SpellInfo const* spellInfo, AuraType auraType)
{
    if (!spellInfo)
        return false;

    for (SpellEffectInfo const& effect : spellInfo->Effects)
        if (effect.ApplyAuraName == auraType)
            return true;

    return false;
}

EurekaInfo const* GetEurekaInfo(Player const* player)
{
    static EurekaInfo const Rogue = { CLASS_ROGUE, POWER_ENERGY, 20, false };
    static EurekaInfo const Warrior = { CLASS_WARRIOR, POWER_RAGE, 40, false };
    static EurekaInfo const Warlock = { CLASS_WARLOCK, POWER_MANA, 50, false };
    static EurekaInfo const Priest = { CLASS_PRIEST, POWER_MANA, 15, true };

    if (!player)
        return nullptr;

    if (player->HasAura(SPELL_WF_EUREKA_ROGUE))
        return &Rogue;

    if (player->HasAura(SPELL_WF_EUREKA_WARRIOR))
        return &Warrior;

    if (player->HasAura(SPELL_WF_EUREKA_WARLOCK))
        return &Warlock;

    if (player->HasAura(SPELL_WF_EUREKA_PRIEST))
        return &Priest;

    return nullptr;
}

bool IsEurekaDamageSpell(Player const* player, SpellInfo const* spellInfo)
{
    if (!player || !spellInfo || spellInfo->Id == 75 || IsGnomeEurekaSpell(spellInfo->Id))
        return false;

    EurekaInfo const* info = GetEurekaInfo(player);
    if (!info || player->getClass() != info->Class)
        return false;

    if (spellInfo->PowerType != info->Power)
        return false;

    return spellInfo->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE)
        || spellInfo->HasEffect(SPELL_EFFECT_WEAPON_DAMAGE)
        || spellInfo->HasEffect(SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL)
        || spellInfo->HasEffect(SPELL_EFFECT_NORMALIZED_WEAPON_DMG)
        || spellInfo->HasEffect(SPELL_EFFECT_WEAPON_PERCENT_DAMAGE)
        || HasAuraEffect(spellInfo, SPELL_AURA_PERIODIC_DAMAGE)
        || HasAuraEffect(spellInfo, SPELL_AURA_PERIODIC_DAMAGE_PERCENT)
        || HasAuraEffect(spellInfo, SPELL_AURA_PERIODIC_LEECH);
}

bool IsEurekaHealSpell(Player const* player, SpellInfo const* spellInfo)
{
    EurekaInfo const* info = GetEurekaInfo(player);
    if (!info || !info->AffectsHealing || !spellInfo || spellInfo->PowerType != info->Power)
        return false;

    return spellInfo->HasEffect(SPELL_EFFECT_HEAL)
        || spellInfo->HasEffect(SPELL_EFFECT_HEAL_MAX_HEALTH)
        || HasAuraEffect(spellInfo, SPELL_AURA_PERIODIC_HEAL);
}

uint32 GetActiveEurekaSpell(Player const* player)
{
    if (!player)
        return 0;

    for (uint32 spellId : { SPELL_WF_EUREKA_ROGUE, SPELL_WF_EUREKA_WARRIOR, SPELL_WF_EUREKA_WARLOCK,
        SPELL_WF_EUREKA_PRIEST })
        if (player->HasAura(spellId))
            return spellId;

    return 0;
}

void SpendEurekaCharge(Player* player)
{
    if (!player)
        return;

    uint32 auraId = GetActiveEurekaSpell(player);
    if (!auraId)
    {
        EurekaCharges.erase(player->GetGUID());
        return;
    }

    uint8& charges = EurekaCharges[player->GetGUID()];
    if (!charges)
        charges = EUREKA_CHARGES;

    --charges;
    if (charges)
        return;

    EurekaCharges.erase(player->GetGUID());
    player->RemoveAura(auraId);
}

bool ShouldSpendEurekaCharge(Player const* player, SpellInfo const* spellInfo)
{
    return IsEurekaDamageSpell(player, spellInfo) || IsEurekaHealSpell(player, spellInfo);
}

void ApplyEurekaDamageBonus(Player* player, SpellInfo const* spellInfo, uint32& damage)
{
    if (!damage || !IsEurekaDamageSpell(player, spellInfo))
        return;

    AddPct(damage, EUREKA_OUTPUT_PCT);
}

void ApplyEurekaHealBonus(Player* player, SpellInfo const* spellInfo, uint32& heal)
{
    if (!heal || !IsEurekaHealSpell(player, spellInfo))
        return;

    AddPct(heal, EUREKA_OUTPUT_PCT);
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
        if (!IsHerbalismNode(gameObject) || CultivatedHerbs.contains(gameObject->GetGUID()))
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

    player->RemoveAura(SPELL_WF_PLAINSRUNNING_SPEED);
    player->CastCustomSpell(SPELL_WF_PLAINSRUNNING_SPEED, SPELLVALUE_BASE_POINT0, state.Bonus - 1, player, true);
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
        Unit::DealHeal(player, player, actualDamage);
}

void LearnIfMissing(Player* player, uint32 spellId)
{
    if (!player->HasSpell(spellId))
        player->learnSpell(spellId);
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
            LearnIfMissing(player, SPELL_WF_BERSERKING);
            LearnIfMissing(player, SPELL_WF_RAPID_REGENERATION);
            AddActionIfEmpty(player, 75, SPELL_WF_BERSERKING);
            AddActionIfEmpty(player, 76, SPELL_WF_RAPID_REGENERATION);
            break;
        case RACE_UNDEAD_PLAYER:
            if (player->getClass() == CLASS_WARRIOR || player->getClass() == CLASS_PALADIN
                || player->getClass() == CLASS_ROGUE)
                LearnIfMissing(player, SPELL_WF_TOUCH_GRAVE_MELEE);
            else if (player->getClass() == CLASS_PRIEST || player->getClass() == CLASS_MAGE
                || player->getClass() == CLASS_WARLOCK)
                LearnIfMissing(player, SPELL_WF_TOUCH_GRAVE_CASTER);
            break;
        case RACE_DWARF:
            LearnIfMissing(player, SPELL_WF_BIG_GAME_HUNTER);
            LearnIfMissing(player, SPELL_WF_MACE_SPECIALIZATION);
            break;
        case RACE_GNOME:
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
        GameObject* duplicate = player->SummonGameObject(herb->GetEntry(), position.GetPositionX(),
            position.GetPositionY(), position.GetPositionZ(), position.GetOrientation(), 0.0f, 0.0f, 0.0f, 0.0f,
            CULTIVATION_DESPAWN_MS);
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
        UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK,
        UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
        UNITHOOK_MODIFY_HEAL_RECEIVED,
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

    void ModifyPeriodicDamageAurasTick(Unit* /*target*/, Unit* attacker, uint32& damage,
        SpellInfo const* spellInfo) override
    {
        ApplyEurekaDamageBonus(attacker ? attacker->ToPlayer() : nullptr, spellInfo, damage);
    }

    void ModifySpellDamageTaken(Unit* /*target*/, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (damage <= 0)
            return;

        uint32 positiveDamage = uint32(damage);
        ApplyEurekaDamageBonus(attacker ? attacker->ToPlayer() : nullptr, spellInfo, positiveDamage);
        damage = int32(positiveDamage);
    }

    void ModifyHealReceived(Unit* /*target*/, Unit* healer, uint32& heal, SpellInfo const* spellInfo) override
    {
        ApplyEurekaHealBonus(healer ? healer->ToPlayer() : nullptr, spellInfo, heal);
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

class spell_wf_racial_player : public PlayerScript
{
public:
    spell_wf_racial_player() : PlayerScript("spell_wf_racial_player", {
        PLAYERHOOK_ON_LOGIN,
        PLAYERHOOK_ON_SPELL_CAST,
        PLAYERHOOK_ON_UPDATE,
        PLAYERHOOK_ON_LOGOUT,
        PLAYERHOOK_ON_AFTER_UPDATE_MAX_POWER
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
        if (player->getRace() == RACE_TROLL && player->HasAura(SPELL_WF_RAPID_REGENERATION)
            && spellInfo->Id != SPELL_WF_RAPID_REGENERATION)
            CancelRapidRegeneration(player);

        if (player->getRace() == RACE_NIGHTELF && spellInfo->Id == 20580 && player->IsInCombat())
        {
            player->RemoveSpellCooldown(20580, true);
            player->AddSpellCooldown(20580, 0, 2 * MINUTE * IN_MILLISECONDS, true);
        }

        if (player->getRace() != RACE_GNOME)
            return;

        if (IsGnomeEurekaSpell(spellInfo->Id))
        {
            EurekaCharges[player->GetGUID()] = EUREKA_CHARGES;
            return;
        }

        if (!ShouldSpendEurekaCharge(player, spellInfo))
            return;

        if (EurekaInfo const* info = GetEurekaInfo(player))
            if (int32 cost = spell->GetPowerCost())
                player->ModifyPower(info->Power, CalculatePct(cost, info->CostReduction));

        SpendEurekaCharge(player);
    }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
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
        TouchOfGraveCooldowns.erase(player->GetGUID());
        EurekaCharges.erase(player->GetGUID());
    }

    void OnPlayerAfterUpdateMaxPower(Player* player, Powers& power, float& value) override
    {
        if (player->getRace() != RACE_GNOME)
            return;

        if ((power == POWER_RAGE && player->HasSpell(SPELL_WF_EXPANSIVE_MIND_RAGE))
            || (power == POWER_ENERGY && player->HasSpell(SPELL_WF_EXPANSIVE_MIND_ENERGY)))
            AddPct(value, EXPANSIVE_MIND_RESOURCE_PCT);
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
    new spell_wf_racial_blood_fury_loader();
    new spell_wf_racial_cultivation_loader();
    new spell_wf_racial_rapid_regeneration_loader();
    new spell_wf_racial_stoneform_loader();
    new spell_wf_racial_unit();
    new spell_wf_racial_player();
}

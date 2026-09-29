-- Gnome racials: native resource bonuses, charged Eureka spellmods and a 3-second Escape Artist.
-- Duration indexes verified in the installed SpellDuration.dbc: 27 = 3000 ms, 8 = 15000 ms.
-- Eureka helper records use a private family sentinel; the script selects eligible abilities.

DELETE FROM `spell_dbc` WHERE `ID` = 20589;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `CastingTimeIndex`, `RecoveryTime`, `RangeIndex`, `EquippedItemClass`, `Effect_1`,
`ImplicitTargetA_1`, `EffectTriggerSpell_1`, `SpellIconID`, `StartRecoveryCategory`, `StartRecoveryTime`,
`SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`, `Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(20589, 16, 1, 120000, 1, -1, 64, 1, 910041, 517, 133, 1500, 1,
'Escape Artist',
'Racial',
CONCAT('Instantly escape the effects of any movement impairing effect and gain immunity to those effects for ',
'3 sec.'),
'');

DELETE FROM `spell_dbc` WHERE `ID` = 910041;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `AttributesEx`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`, `EquippedItemClass`,
`Effect_1`, `Effect_2`, `EffectDieSides_1`, `EffectDieSides_2`, `EffectBasePoints_1`, `EffectBasePoints_2`,
`ImplicitTargetA_1`, `ImplicitTargetA_2`, `EffectAura_1`, `EffectAura_2`, `EffectMiscValue_1`, `EffectMiscValue_2`,
`SpellVisualID_1`, `SpellIconID`, `SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`, `Description_Lang_enUS`,
`AuraDescription_Lang_enUS`) VALUES
(910041, 16, 32768, 1, 27, 1, -1, 6, 6, 1, 1, 10, 10, 1, 1, 77, 77, 7, 11, 1008, 517, 1,
'Escape Artist',
'Racial',
CONCAT('Instantly escape the effects of any movement impairing effect and gain immunity to those effects for ',
'3 sec.'),
'Immune to movement impairing effects.');

DELETE FROM `spell_dbc` WHERE `ID` = 20591;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`, `EquippedItemClass`, `Effect_1`,
`EffectDieSides_1`, `EffectBasePoints_1`, `ImplicitTargetA_1`, `EffectAura_1`, `EffectMiscValue_1`, `SpellIconID`,
`SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`, `Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(20591, 80, 1, 21, 1, -1, 6, 1, 4, 1, 132, 0, 1654, 1,
'Expansive Mind',
'Racial',
'Maximum Mana increased by 5%.',
'');

DELETE FROM `spell_dbc` WHERE `ID` = 910023;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`, `EquippedItemClass`, `Effect_1`,
`EffectDieSides_1`, `EffectBasePoints_1`, `ImplicitTargetA_1`, `EffectAura_1`, `EffectMiscValue_1`, `SpellIconID`,
`SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`, `Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(910023, 80, 1, 21, 1, -1, 6, 1, 4, 1, 132, 1, 1654, 1,
'Expansive Mind',
'Racial',
'Maximum Rage increased by 5%.',
'');

DELETE FROM `spell_dbc` WHERE `ID` = 910024;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`, `EquippedItemClass`, `Effect_1`,
`EffectDieSides_1`, `EffectBasePoints_1`, `ImplicitTargetA_1`, `EffectAura_1`, `EffectMiscValue_1`, `SpellIconID`,
`SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`, `Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(910024, 80, 1, 21, 1, -1, 6, 1, 4, 1, 132, 3, 1654, 1,
'Expansive Mind',
'Racial',
'Maximum Energy increased by 5%.',
'');

DELETE FROM `spell_dbc` WHERE `ID` = 910042;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`, `EquippedItemClass`, `Effect_1`,
`EffectDieSides_1`, `EffectBasePoints_1`, `ImplicitTargetA_1`, `EffectAura_1`, `EffectMiscValue_1`, `SpellIconID`,
`SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`, `Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(910042, 80, 1, 21, 1, -1, 6, 1, 4, 1, 132, 6, 1654, 1,
'Expansive Mind',
'Racial',
'Maximum Runic Power increased by 5%.',
'');

DELETE FROM `spell_dbc` WHERE `ID` = 20593;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`, `EquippedItemClass`, `Effect_1`,
`EffectDieSides_1`, `EffectBasePoints_1`, `ImplicitTargetA_1`, `EffectAura_1`, `SpellIconID`, `SchoolMask`,
`Name_Lang_enUS`, `NameSubtext_Lang_enUS`, `Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(20593, 80, 1, 21, 1, -1, 6, 1, 19, 1, 4, 353, 1,
'Engineering Specialization',
'Racial',
CONCAT('Your gnomish ingenuity reduces the rate of engineering devices failing or backfiring when you use ',
'them by 20%.'),
'');

DELETE FROM `spell_dbc` WHERE `ID` = 910025;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `CastingTimeIndex`, `RecoveryTime`, `RangeIndex`, `EquippedItemClass`, `Effect_1`,
`ImplicitTargetA_1`, `EffectTriggerSpell_1`, `SpellIconID`, `SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`,
`Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(910025, 16, 1, 120000, 1, -1, 64, 1, 910037, 517, 8,
'Eureka!',
'Racial',
CONCAT('Your next 3 damaging abilities have their Energy cost reduced by 10% and deal 10% more damage. Lasts ',
'15 sec.'),
'');

DELETE FROM `spell_dbc` WHERE `ID` = 910037;
INSERT INTO `spell_dbc`
(`ID`, `DispelType`, `Attributes`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`, `ProcChance`, `ProcCharges`,
`EquippedItemClass`, `Effect_1`, `Effect_2`, `Effect_3`, `EffectDieSides_1`, `EffectDieSides_2`, `EffectDieSides_3`,
`EffectBasePoints_1`, `EffectBasePoints_2`, `EffectBasePoints_3`, `ImplicitTargetA_1`, `ImplicitTargetA_2`,
`ImplicitTargetA_3`, `EffectAura_1`, `EffectAura_2`, `EffectAura_3`, `EffectMiscValue_1`, `EffectMiscValue_2`,
`EffectMiscValue_3`, `SpellIconID`, `SpellClassSet`, `EffectSpellClassMaskA_1`, `EffectSpellClassMaskA_2`, `EffectSpellClassMaskA_3`, `EffectSpellClassMaskB_1`, `EffectSpellClassMaskB_2`, `EffectSpellClassMaskB_3`, `EffectSpellClassMaskC_1`, `EffectSpellClassMaskC_2`, `EffectSpellClassMaskC_3`, `SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`,
`Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(910037, 1, 16, 1, 8, 1, 100, 3, -1, 6, 6, 6, 1, 1, 1, -11, 9, 9, 1, 1, 1, 108, 108, 108, 14, 0, 22, 517, 0, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 8,
'Eureka!',
'Racial',
CONCAT('Your next 3 damaging abilities have their Energy cost reduced by 10% and deal 10% more damage. Lasts ',
'15 sec.'),
'Next damaging abilities cost 10% less Energy and deal 10% more damage.');

DELETE FROM `spell_dbc` WHERE `ID` = 910026;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `CastingTimeIndex`, `RecoveryTime`, `RangeIndex`, `EquippedItemClass`, `Effect_1`,
`ImplicitTargetA_1`, `EffectTriggerSpell_1`, `SpellIconID`, `SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`,
`Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(910026, 16, 1, 120000, 1, -1, 64, 1, 910038, 1321, 8,
'Eureka!',
'Racial',
CONCAT('Your next 3 damaging abilities have their Rage cost reduced by 10% and deal 10% more damage. Lasts ',
'15 sec.'),
'');

DELETE FROM `spell_dbc` WHERE `ID` = 910038;
INSERT INTO `spell_dbc`
(`ID`, `DispelType`, `Attributes`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`, `ProcChance`, `ProcCharges`,
`EquippedItemClass`, `Effect_1`, `Effect_2`, `Effect_3`, `EffectDieSides_1`, `EffectDieSides_2`, `EffectDieSides_3`,
`EffectBasePoints_1`, `EffectBasePoints_2`, `EffectBasePoints_3`, `ImplicitTargetA_1`, `ImplicitTargetA_2`,
`ImplicitTargetA_3`, `EffectAura_1`, `EffectAura_2`, `EffectAura_3`, `EffectMiscValue_1`, `EffectMiscValue_2`,
`EffectMiscValue_3`, `SpellIconID`, `SpellClassSet`, `EffectSpellClassMaskA_1`, `EffectSpellClassMaskA_2`, `EffectSpellClassMaskA_3`, `EffectSpellClassMaskB_1`, `EffectSpellClassMaskB_2`, `EffectSpellClassMaskB_3`, `EffectSpellClassMaskC_1`, `EffectSpellClassMaskC_2`, `EffectSpellClassMaskC_3`, `SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`,
`Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(910038, 1, 16, 1, 8, 1, 100, 3, -1, 6, 6, 6, 1, 1, 1, -11, 9, 9, 1, 1, 1, 108, 108, 108, 14, 0, 22, 1321, 0, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 8,
'Eureka!',
'Racial',
CONCAT('Your next 3 damaging abilities have their Rage cost reduced by 10% and deal 10% more damage. Lasts ',
'15 sec.'),
'Next damaging abilities cost 10% less Rage and deal 10% more damage.');

DELETE FROM `spell_dbc` WHERE `ID` = 910027;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `CastingTimeIndex`, `RecoveryTime`, `RangeIndex`, `EquippedItemClass`, `Effect_1`,
`ImplicitTargetA_1`, `EffectTriggerSpell_1`, `SpellIconID`, `SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`,
`Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(910027, 16, 1, 120000, 1, -1, 64, 1, 910039, 144, 8,
'Eureka!',
'Racial',
CONCAT('Your next 3 damaging abilities have their Mana cost reduced by 10% and deal 10% more damage. Lasts ',
'15 sec.'),
'');

DELETE FROM `spell_dbc` WHERE `ID` = 910039;
INSERT INTO `spell_dbc`
(`ID`, `DispelType`, `Attributes`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`, `ProcChance`, `ProcCharges`,
`EquippedItemClass`, `Effect_1`, `Effect_2`, `Effect_3`, `EffectDieSides_1`, `EffectDieSides_2`, `EffectDieSides_3`,
`EffectBasePoints_1`, `EffectBasePoints_2`, `EffectBasePoints_3`, `ImplicitTargetA_1`, `ImplicitTargetA_2`,
`ImplicitTargetA_3`, `EffectAura_1`, `EffectAura_2`, `EffectAura_3`, `EffectMiscValue_1`, `EffectMiscValue_2`,
`EffectMiscValue_3`, `SpellIconID`, `SpellClassSet`, `EffectSpellClassMaskA_1`, `EffectSpellClassMaskA_2`, `EffectSpellClassMaskA_3`, `EffectSpellClassMaskB_1`, `EffectSpellClassMaskB_2`, `EffectSpellClassMaskB_3`, `EffectSpellClassMaskC_1`, `EffectSpellClassMaskC_2`, `EffectSpellClassMaskC_3`, `SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`,
`Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(910039, 1, 16, 1, 8, 1, 100, 3, -1, 6, 6, 6, 1, 1, 1, -11, 9, 9, 1, 1, 1, 108, 108, 108, 14, 0, 22, 144, 0, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 8,
'Eureka!',
'Racial',
CONCAT('Your next 3 damaging abilities have their Mana cost reduced by 10% and deal 10% more damage. Lasts ',
'15 sec.'),
'Next damaging abilities cost 10% less Mana and deal 10% more damage.');

DELETE FROM `spell_dbc` WHERE `ID` = 910028;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `CastingTimeIndex`, `RecoveryTime`, `RangeIndex`, `EquippedItemClass`, `Effect_1`,
`ImplicitTargetA_1`, `EffectTriggerSpell_1`, `SpellIconID`, `SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`,
`Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(910028, 16, 1, 120000, 1, -1, 64, 1, 910040, 1352, 8,
'Eureka!',
'Racial',
CONCAT('Your next 3 damaging or healing abilities have their Mana cost reduced by 10% and deal 10% more ',
'damage or healing. Lasts 15 sec.'),
'');

DELETE FROM `spell_dbc` WHERE `ID` = 910040;
INSERT INTO `spell_dbc`
(`ID`, `DispelType`, `Attributes`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`, `ProcChance`, `ProcCharges`,
`EquippedItemClass`, `Effect_1`, `Effect_2`, `Effect_3`, `EffectDieSides_1`, `EffectDieSides_2`, `EffectDieSides_3`,
`EffectBasePoints_1`, `EffectBasePoints_2`, `EffectBasePoints_3`, `ImplicitTargetA_1`, `ImplicitTargetA_2`,
`ImplicitTargetA_3`, `EffectAura_1`, `EffectAura_2`, `EffectAura_3`, `EffectMiscValue_1`, `EffectMiscValue_2`,
`EffectMiscValue_3`, `SpellIconID`, `SpellClassSet`, `EffectSpellClassMaskA_1`, `EffectSpellClassMaskA_2`, `EffectSpellClassMaskA_3`, `EffectSpellClassMaskB_1`, `EffectSpellClassMaskB_2`, `EffectSpellClassMaskB_3`, `EffectSpellClassMaskC_1`, `EffectSpellClassMaskC_2`, `EffectSpellClassMaskC_3`, `SchoolMask`, `Name_Lang_enUS`, `NameSubtext_Lang_enUS`,
`Description_Lang_enUS`, `AuraDescription_Lang_enUS`) VALUES
(910040, 1, 16, 1, 8, 1, 100, 3, -1, 6, 6, 6, 1, 1, 1, -11, 9, 9, 1, 1, 1, 108, 108, 108, 14, 0, 22, 1352, 0, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 8,
'Eureka!',
'Racial',
CONCAT('Your next 3 damaging or healing abilities have their Mana cost reduced by 10% and deal 10% more ',
'damage or healing. Lasts 15 sec.'),
'Next damaging or healing abilities cost 10% less Mana and deal 10% more damage or healing.');

-- Disable the stock learning record instead of deleting its SQL override.
DELETE FROM `skilllineability_dbc` WHERE `ID` BETWEEN 11720 AND 11723 OR `ID` BETWEEN 910023 AND 910028 OR `ID` = 910042;
INSERT INTO `skilllineability_dbc`
(`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `MinSkillLineRank`, `AcquireMethod`) VALUES
(11720, 753, 20589, 64, 0, 1, 2),
(11721, 753, 20591, 64, 1494, 1, 2),
(11722, 753, 20593, 64, 0, 1, 2),
(11723, 753, 20592, 64, 0, 1, 0),
(910023, 753, 910023, 64, 1, 1, 2),
(910024, 753, 910024, 64, 8, 1, 2),
(910042, 753, 910042, 64, 32, 1, 2),
(910025, 753, 910025, 64, 8, 1, 2),
(910026, 753, 910026, 64, 1, 1, 2),
(910027, 753, 910027, 64, 256, 1, 2),
(910028, 753, 910028, 64, 16, 1, 2);

-- The trigger/aura pair replaces the former script-effect binding.
DELETE FROM `spell_script_names` WHERE `spell_id` = 20589 AND `ScriptName` = 'spell_gen_remove_impairing_auras';

-- No proc event entry: native charged spellmods consume one charge per spell, not per target/tick.
DELETE FROM `spell_proc` WHERE `SpellId` IN (910037, 910038, 910039, 910040);

DELETE FROM `playercreateinfo_spell_custom` WHERE `racemask` = 64 AND `Spell` BETWEEN 20589 AND 20593;
DELETE FROM `playercreateinfo_spell_custom` WHERE `racemask` = 64 AND `Spell` BETWEEN 910023 AND 910028;
DELETE FROM `playercreateinfo_spell_custom` WHERE `racemask` = 64 AND `Spell` = 910042;
INSERT INTO `playercreateinfo_spell_custom` (`racemask`, `classmask`, `Spell`, `Note`) VALUES
(64, 0, 20589, 'Gnome - Escape Artist'),
(64, 0, 20593, 'Gnome - Engineering Specialization'),
(64, 1494, 20591, 'Gnome - Expansive Mind (Mana)'),
(64, 1, 910023, 'Gnome - Expansive Mind (Rage)'),
(64, 8, 910024, 'Gnome - Expansive Mind (Energy)'),
(64, 32, 910042, 'Gnome - Expansive Mind (Runic Power)'),
(64, 8, 910025, 'Gnome - Eureka (Rogue)'),
(64, 1, 910026, 'Gnome - Eureka (Warrior)'),
(64, 256, 910027, 'Gnome - Eureka (Warlock)'),
(64, 16, 910028, 'Gnome - Eureka (Priest)');

UPDATE `spell_dbc` SET `SpellIconID` = 502 WHERE `ID` IN (910025, 910026, 910027, 910028, 910037, 910038, 910039, 910040);
UPDATE `spell_dbc` SET `SpellVisualID_1` = 4370 WHERE `ID` IN (910037, 910038, 910039, 910040);

-- Night Elf active racials: replace the stock Shadowmeld and provide a native timed Elune aura.
DELETE FROM `spell_dbc` WHERE `ID` = 20580;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `AttributesEx`, `CastingTimeIndex`, `RecoveryTime`, `DurationIndex`, `PowerType`, `RangeIndex`,
`SpellLevel`, `Effect_1`, `Effect_2`, `Effect_3`, `EffectDieSides_1`, `EffectDieSides_2`, `EffectDieSides_3`,
`EffectBasePoints_1`, `EffectBasePoints_2`, `EffectBasePoints_3`, `EffectAura_1`, `EffectAura_2`, `EffectAura_3`,
`EffectAuraPeriod_1`, `EffectAuraPeriod_2`, `EffectAuraPeriod_3`, `ImplicitTargetA_1`, `ImplicitTargetA_2`,
`ImplicitTargetA_3`, `EffectMiscValue_1`, `EffectMiscValue_2`,
`EffectMiscValue_3`, `EffectTriggerSpell_1`, `SpellIconID`, `Name_Lang_enUS`, `Description_Lang_enUS`,
`AuraDescription_Lang_enUS`, `StartRecoveryCategory`, `StartRecoveryTime`, `PreventionType`, `SchoolMask`) VALUES
(20580, 34930704, 132112, 1, 10000, 21, 0, 1, 1, 6, 6, 0, 1, 1, 0, 0, -999999, 0, 16, 103, 0,
0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 103, 'Shadowmeld', CONCAT('Activate to slip into the shadows, reducing the chance ',
'for enemies to detect your presence. Lasts until cancelled or upon moving. Using this ability in combat discourages ',
'enemies from attacking you, but increases the cooldown to 2 min.'), 'Shadowmelded.', 0, 0, 2, 1);

UPDATE `spell_dbc` SET `AttributesEx2` = 2621444 WHERE `ID` = 20580;

UPDATE `spell_dbc` SET `SpellVisualID_1` = 184, `EquippedItemClass` = -1 WHERE `ID` = 20580;

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_wf_racial_shadowmeld';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(20580, 'spell_wf_racial_shadowmeld');

DELETE FROM `spell_dbc` WHERE `ID` IN (910031, 910036);
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `AttributesEx`, `AttributesEx2`, `CastingTimeIndex`, `RecoveryTime`, `DurationIndex`,
`RangeIndex`, `EquippedItemClass`, `Effect_1`, `EffectDieSides_1`, `EffectBasePoints_1`, `EffectAura_1`,
`ImplicitTargetA_1`, `EffectTriggerSpell_1`, `SpellVisualID_1`, `SpellIconID`, `Name_Lang_enUS`,
`Description_Lang_enUS`, `AuraDescription_Lang_enUS`, `SchoolMask`) VALUES
(910031, 16, 32, 16384, 1, 180000, 0, 1, -1, 64, 0, 0, 0, 1, 910036, 0, 46, 'Elune''s Light',
'Increases your critical strike chance with all spells and attacks by 10% for 15 sec.', '', 1),
(910036, 16, 32, 16384, 1, 0, 8, 1, -1, 6, 1, 9, 290, 1, 0, 11571, 46, 'Elune''s Light',
'Increases your critical strike chance with all spells and attacks by 10% for 15 sec.',
'Critical strike chance with all spells and attacks increased by 10%.', 1);

-- Override the actual stock DBC learning ID; deleting a SQL row alone leaves it enabled.
DELETE FROM `skilllineability_dbc` WHERE `ID` IN (20207, 1259800, 1259799);
INSERT INTO `skilllineability_dbc`
(`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`,
`SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`,
`CharacterPoints_1`, `CharacterPoints_2`) VALUES
(20207, 126, 20580, 8, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(1259799, 126, 910031, 8, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0);

DELETE FROM `playercreateinfo_spell_custom` WHERE `Spell` IN (58984, 20580, 910031);
INSERT INTO `playercreateinfo_spell_custom` (`racemask`, `classmask`, `Spell`, `Note`) VALUES
(8, 1535, 20580, 'WoW Forever - Shadowmeld'),
(8, 1535, 910031, 'WoW Forever - Elune''s Light');

UPDATE `playercreateinfo_action` SET `action` = 20580 WHERE `race` = 4 AND `action` = 58984 AND `type` = 0;

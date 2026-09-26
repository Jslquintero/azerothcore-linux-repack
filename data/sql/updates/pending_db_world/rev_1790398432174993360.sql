-- Human Perception: restore the active racial and replace the stock passive learning record.
DELETE FROM `spell_dbc` WHERE `ID` = 20600;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `AttributesEx`, `AttributesEx2`, `CastingTimeIndex`, `RecoveryTime`, `DurationIndex`,
`RangeIndex`, `EquippedItemClass`, `Effect_1`, `EffectDieSides_1`, `EffectBasePoints_1`, `EffectAura_1`,
`ImplicitTargetA_1`, `SpellVisualID_1`, `SpellIconID`, `Name_Lang_enUS`, `Description_Lang_enUS`,
`AuraDescription_Lang_enUS`, `StartRecoveryCategory`, `StartRecoveryTime`, `SchoolMask`) VALUES
(20600, 262160, 32, 524288, 1, 180000, 18, 1, -1, 6, 1, 50, 17, 1, 5727, 44, 'Perception',
'Dramatically increases stealth detection for 20 sec.', 'Stealth detection dramatically increased.', 133, 1500, 1);

-- Deleting a SQL row does not remove ID 20114 from the server's stock SkillLineAbility.dbc.
-- Override that same ID so humans learn 20600 instead of passive Perception (58985).
DELETE FROM `skilllineability_dbc` WHERE `ID` IN (20114, 910030);
INSERT INTO `skilllineability_dbc`
(`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`,
`SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`,
`CharacterPoints_1`, `CharacterPoints_2`) VALUES
(20114, 754, 20600, 1, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0);

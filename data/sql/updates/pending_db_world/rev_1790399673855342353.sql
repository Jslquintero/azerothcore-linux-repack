-- Disable stock human racial learning records that remain in the server's SkillLineAbility.dbc.
-- AcquireMethod 0 prevents automatic learning; deleting only SQL rows leaves the DBC records active.
-- Keep custom Will to Survive (910029) as the sole learned version.
DELETE FROM `skilllineability_dbc` WHERE `ID` IN (11728, 11861, 20205);
INSERT INTO `skilllineability_dbc`
(`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`,
`SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`,
`CharacterPoints_1`, `CharacterPoints_2`) VALUES
(11728, 754, 20599, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
(11861, 754, 20864, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
(20205, 754, 59752, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

DELETE FROM `playercreateinfo_spell_custom` WHERE `racemask` = 1 AND `Spell` IN (20599, 20864, 59752);
DELETE FROM `playercreateinfo_action` WHERE `race` = 1 AND `type` = 0 AND `action` IN (20599, 20864, 59752);

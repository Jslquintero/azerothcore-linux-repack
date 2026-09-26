-- Disable the original dwarf racials; deleting SQL rows exposes the server DBC learning records again.
-- Keep Big Game Hunter (910020) and the mace-dependent critical strike passive (910021).
DELETE FROM `skilllineability_dbc` WHERE `ID` IN (11726, 20143);
INSERT INTO `skilllineability_dbc`
(`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`,
`SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`,
`CharacterPoints_1`, `CharacterPoints_2`) VALUES
(11726, 101, 20595, 4, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
(20143, 101, 59224, 4, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

DELETE FROM `playercreateinfo_spell_custom` WHERE `racemask` = 4 AND `Spell` IN (20595, 59224);
DELETE FROM `playercreateinfo_action` WHERE `race` = 3 AND `type` = 0 AND `action` IN (20595, 59224);

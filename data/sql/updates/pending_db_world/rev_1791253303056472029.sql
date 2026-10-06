-- Caster Blood Fury: include the added Orc Priest and Mage alongside Warlock.
-- Keep the racial skill learning record synchronized with client SkillLineAbility.dbc.
-- Loading the racial skill also repairs existing characters at login.
DELETE FROM `skilllineability_dbc` WHERE `ID` = 15034;
INSERT INTO `skilllineability_dbc`
(`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`,
`SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`,
`CharacterPoints_1`, `CharacterPoints_2`) VALUES
(15034, 125, 33702, 2, 400, 0, 0, 1, 0, 2, 0, 0, 0, 0);

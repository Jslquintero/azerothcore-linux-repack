-- Add Hunter to the physical Touch of the Grave variant for Undead characters.
-- Keep the server learning masks synchronized with client SkillLineAbility.dbc.
DELETE FROM `playercreateinfo_spell_custom` WHERE `racemask` = 16 AND `Spell` = 910018;
INSERT INTO `playercreateinfo_spell_custom` (`racemask`, `classmask`, `Spell`, `Note`) VALUES
(16, 15, 910018, 'WoW Forever - Touch of the Grave');

DELETE FROM `skilllineability_dbc` WHERE `ID` = 910018;
INSERT INTO `skilllineability_dbc`
(`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`,
`SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`,
`CharacterPoints_1`, `CharacterPoints_2`) VALUES
(910018, 220, 910018, 16, 15, 0, 0, 1, 0, 2, 0, 0, 0, 0);

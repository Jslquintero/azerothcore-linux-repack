-- Extend existing physical/caster Draenei racials to Rogue and Warlock.
-- Disable retired racials that are already removed from the custom client SkillLineAbility.dbc.
-- SQL overrides must use the original DBC IDs; deleting SQL rows leaves the DBC defaults active.
DELETE FROM `skilllineability_dbc` WHERE `ID` IN (14022, 14023, 20172, 20173, 20178, 20179);
DELETE FROM `skilllineability_dbc` WHERE `ID` IN (11725, 11717, 20665, 11714);
INSERT INTO `skilllineability_dbc`
(`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`,
`SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`,
`CharacterPoints_1`, `CharacterPoints_2`) VALUES
(14022, 760, 6562, 1024, 47, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(14023, 760, 28878, 1024, 464, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(20172, 760, 59536, 1024, 12, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(20173, 760, 59541, 1024, 384, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(20178, 760, 59543, 1024, 12, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(20179, 760, 59548, 1024, 384, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(11725, 101, 20596, 4, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
(11717, 126, 20583, 8, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
(20665, 126, 21009, 8, 1085, 0, 0, 1, 0, 0, 0, 0, 0, 0),
(11714, 220, 20579, 16, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

-- Put Gift of the Naaru alongside the other initial Draenei racial action.
DELETE FROM `playercreateinfo_action` WHERE `race` = 11 AND `class` = 4 AND `button` = 4;
DELETE FROM `playercreateinfo_action` WHERE `race` = 11 AND `class` = 9 AND `button` = 2;
INSERT INTO `playercreateinfo_action` (`race`, `class`, `button`, `action`, `type`) VALUES
(11, 4, 4, 59543, 0),
(11, 9, 2, 59548, 0);

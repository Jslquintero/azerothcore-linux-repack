--
-- Rapid Regeneration: native six-second channel with Healing Touch's healing visual.
UPDATE `spell_dbc` SET `AttributesEx` = 4, `ChannelInterruptFlags` = 15374,
`SpellVisualID_1` = 58, `SpellVisualID_2` = 0
WHERE `ID` = 910017;

-- Remove Da Voodoo Shuffle from racial learning, including the stock DBC override.
DELETE FROM `playercreateinfo_spell_custom` WHERE `Spell` = 58943;
DELETE FROM `skilllineability_dbc` WHERE `ID` = 20111 OR `Spell` = 58943;
INSERT INTO `skilllineability_dbc`
(`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`,
`TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(20111, 733, 58943, 128, 0, 0, 0, 0, 0, 0, 0, 0);

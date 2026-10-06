-- Remaining Retail combinations for the races and classes available in WotLK.
-- Keep the existing starting zones and provide actions and skills matching CharStartOutfit.dbc.
DELETE FROM `playercreateinfo` WHERE `race` = 2 AND `class` = 5;
DELETE FROM `playercreateinfo` WHERE `race` IN (3, 4) AND `class` IN (8, 9);
DELETE FROM `playercreateinfo` WHERE `race` = 6 AND `class` IN (4, 8, 9);
DELETE FROM `playercreateinfo` WHERE `race` = 7 AND `class` = 3;
DELETE FROM `playercreateinfo` WHERE `race` = 11 AND `class` IN (4, 9);
INSERT INTO `playercreateinfo` (`race`, `class`, `map`, `zone`, `position_x`, `position_y`, `position_z`, `orientation`) VALUES
(2, 5, 1, 14, -618.518, -4251.67, 38.718, 0),
(3, 8, 0, 1, -6240.32, 331.033, 382.758, 6.17716),
(3, 9, 0, 1, -6240.32, 331.033, 382.758, 6.17716),
(4, 8, 1, 141, 10311.3, 832.463, 1326.41, 5.69632),
(4, 9, 1, 141, 10311.3, 832.463, 1326.41, 5.69632),
(6, 4, 1, 215, -2917.58, -257.98, 52.9968, 0),
(6, 8, 1, 215, -2917.58, -257.98, 52.9968, 0),
(6, 9, 1, 215, -2917.58, -257.98, 52.9968, 0),
(7, 3, 0, 1, -6240.32, 331.033, 382.758, 0),
(11, 4, 530, 3526, -3961.64, -13931.2, 100.615, 2.08364),
(11, 9, 530, 3526, -3961.64, -13931.2, 100.615, 2.08364);

DELETE FROM `playercreateinfo_action` WHERE `race` = 2 AND `class` = 5;
DELETE FROM `playercreateinfo_action` WHERE `race` IN (3, 4) AND `class` IN (8, 9);
DELETE FROM `playercreateinfo_action` WHERE `race` = 6 AND `class` IN (4, 8, 9);
DELETE FROM `playercreateinfo_action` WHERE `race` = 7 AND `class` = 3;
DELETE FROM `playercreateinfo_action` WHERE `race` = 11 AND `class` IN (4, 9);
INSERT INTO `playercreateinfo_action` (`race`, `class`, `button`, `action`, `type`) VALUES
-- Orc Priest
(2, 5, 0, 585, 0),
(2, 5, 1, 2050, 0),
(2, 5, 2, 33702, 0),
(2, 5, 75, 910001, 0),
-- Dwarf Mage / Warlock
(3, 8, 0, 133, 0),
(3, 8, 1, 168, 0),
(3, 8, 2, 20594, 0),
(3, 8, 3, 2481, 0),
(3, 9, 0, 686, 0),
(3, 9, 1, 687, 0),
(3, 9, 2, 20594, 0),
(3, 9, 3, 2481, 0),
-- Night Elf Mage / Warlock
(4, 8, 0, 133, 0),
(4, 8, 1, 168, 0),
(4, 8, 75, 20580, 0),
(4, 8, 76, 910031, 0),
(4, 9, 0, 686, 0),
(4, 9, 1, 687, 0),
(4, 9, 75, 20580, 0),
(4, 9, 76, 910031, 0),
-- Tauren Rogue / Mage / Warlock
(6, 4, 0, 6603, 0),
(6, 4, 1, 1752, 0),
(6, 4, 2, 2098, 0),
(6, 4, 3, 2764, 0),
(6, 4, 4, 20549, 0),
(6, 4, 75, 20552, 0),
(6, 8, 0, 133, 0),
(6, 8, 1, 168, 0),
(6, 8, 2, 20549, 0),
(6, 8, 75, 20552, 0),
(6, 9, 0, 686, 0),
(6, 9, 1, 687, 0),
(6, 9, 2, 20549, 0),
(6, 9, 75, 20552, 0),
-- Gnome Hunter
(7, 3, 0, 6603, 0),
(7, 3, 1, 2973, 0),
(7, 3, 2, 75, 0),
(7, 3, 3, 20589, 0),
-- Draenei Rogue / Warlock
(11, 4, 0, 6603, 0),
(11, 4, 1, 1752, 0),
(11, 4, 2, 2098, 0),
(11, 4, 3, 2764, 0),
(11, 4, 75, 910033, 0),
(11, 9, 0, 686, 0),
(11, 9, 1, 687, 0),
(11, 9, 75, 910033, 0);

-- Weapon skills omitted by Individual Progression's pre-3.3 defaults.
DELETE FROM `playercreateinfo_skills` WHERE `raceMask` = 2 AND `classMask` = 16 AND `skill` = 136;
DELETE FROM `playercreateinfo_skills` WHERE `raceMask` = 1068 AND `classMask` = 256 AND `skill` = 136;
DELETE FROM `playercreateinfo_skills` WHERE `raceMask` = 64 AND `classMask` = 4 AND `skill` IN (46, 172);
INSERT INTO `playercreateinfo_skills` (`raceMask`, `classMask`, `skill`, `rank`, `comment`) VALUES
(2, 16, 136, 0, 'Orc Priest - Starting Staff'),
(1068, 256, 136, 0, 'Dwarf/Night Elf/Tauren/Draenei Warlock - Starting Staff'),
(64, 4, 46, 0, 'Gnome Hunter - Starting Gun'),
(64, 4, 172, 0, 'Gnome Hunter - Starting Two-Handed Axe');

-- The stock caster Blood Fury learning record only covers warlocks.
DELETE FROM `playercreateinfo_spell_custom` WHERE `racemask` = 2 AND `classmask` = 16 AND `Spell` = 33702;
INSERT INTO `playercreateinfo_spell_custom` (`racemask`, `classmask`, `Spell`, `Note`) VALUES
(2, 16, 33702, 'Orc Priest - Blood Fury');

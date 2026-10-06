-- Starting action bars for the additional race/class combinations from rev_20261005_000001.sql.
-- Keep the class defaults and the WoW Forever racial buttons used by the existing combinations.
-- Warrior and druid form bars require their own attack buttons.
DELETE FROM `playercreateinfo_action` WHERE `race` = 1 AND `class` = 3;
DELETE FROM `playercreateinfo_action` WHERE `race` = 2 AND `class` = 8;
DELETE FROM `playercreateinfo_action` WHERE `race` = 3 AND `class` = 7;
DELETE FROM `playercreateinfo_action` WHERE `race` = 5 AND `class` IN (2, 3);
DELETE FROM `playercreateinfo_action` WHERE `race` = 6 AND `class` IN (2, 5);
DELETE FROM `playercreateinfo_action` WHERE `race` = 7 AND `class` = 5;
DELETE FROM `playercreateinfo_action` WHERE `race` = 8 AND `class` IN (9, 11);
DELETE FROM `playercreateinfo_action` WHERE `race` = 10 AND `class` = 1;
INSERT INTO `playercreateinfo_action` (`race`, `class`, `button`, `action`, `type`) VALUES
-- Human Hunter
(1, 3, 0, 6603, 0),
(1, 3, 1, 2973, 0),
(1, 3, 2, 75, 0),
(1, 3, 75, 20600, 0),
(1, 3, 76, 910029, 0),
-- Orc Mage
(2, 8, 0, 133, 0),
(2, 8, 1, 168, 0),
(2, 8, 2, 33702, 0),
(2, 8, 75, 910001, 0),
-- Dwarf Shaman
(3, 7, 0, 6603, 0),
(3, 7, 1, 403, 0),
(3, 7, 2, 331, 0),
(3, 7, 3, 20594, 0),
(3, 7, 4, 2481, 0),
-- Undead Hunter
(5, 3, 0, 6603, 0),
(5, 3, 1, 2973, 0),
(5, 3, 2, 75, 0),
(5, 3, 3, 20577, 0),
-- Undead Paladin
(5, 2, 0, 6603, 0),
(5, 2, 1, 21084, 0),
(5, 2, 2, 635, 0),
(5, 2, 3, 20577, 0),
-- Tauren Paladin
(6, 2, 0, 6603, 0),
(6, 2, 1, 21084, 0),
(6, 2, 2, 635, 0),
(6, 2, 3, 20549, 0),
(6, 2, 75, 20552, 0),
-- Tauren Priest
(6, 5, 0, 585, 0),
(6, 5, 1, 2050, 0),
(6, 5, 2, 20549, 0),
(6, 5, 75, 20552, 0),
-- Gnome Priest
(7, 5, 0, 585, 0),
(7, 5, 1, 2050, 0),
(7, 5, 75, 910028, 0),
-- Troll Warlock
(8, 9, 0, 686, 0),
(8, 9, 1, 687, 0),
(8, 9, 2, 26297, 0),
(8, 9, 75, 20554, 0),
(8, 9, 76, 910017, 0),
-- Troll Druid
(8, 11, 0, 5176, 0),
(8, 11, 1, 5185, 0),
(8, 11, 2, 26297, 0),
(8, 11, 72, 6603, 0),
(8, 11, 75, 20554, 0),
(8, 11, 76, 910017, 0),
(8, 11, 96, 6603, 0),
-- Blood Elf Warrior
(10, 1, 72, 6603, 0),
(10, 1, 73, 78, 0),
(10, 1, 75, 910033, 0),
(10, 1, 84, 6603, 0),
(10, 1, 96, 6603, 0);

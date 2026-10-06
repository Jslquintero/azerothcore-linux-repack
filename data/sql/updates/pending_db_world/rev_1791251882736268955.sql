-- Match the added race/class combinations to their generated CharStartOutfit.dbc weapons.
-- Individual Progression replaces the WotLK starting skills with pre-3.3 defaults.
-- Add only the missing skills for these combinations, preserving the other starting templates.
DELETE FROM `playercreateinfo_skills` WHERE `raceMask` = 17 AND `classMask` = 4 AND `skill` IN (45, 172);
DELETE FROM `playercreateinfo_skills` WHERE `raceMask` = 96 AND `classMask` = 16 AND `skill` = 136;
DELETE FROM `playercreateinfo_skills` WHERE `raceMask` = 128 AND `classMask` = 256 AND `skill` = 136;
DELETE FROM `playercreateinfo_skills` WHERE `raceMask` = 512 AND `classMask` = 1 AND `skill` = 55;
INSERT INTO `playercreateinfo_skills` (`raceMask`, `classMask`, `skill`, `rank`, `comment`) VALUES
(17, 4, 45, 0, 'Human/Undead Hunter - Starting Bow'),
(17, 4, 172, 0, 'Human/Undead Hunter - Starting Two-Handed Axe'),
(96, 16, 136, 0, 'Tauren/Gnome Priest - Starting Staff'),
(128, 256, 136, 0, 'Troll Warlock - Starting Staff'),
(512, 1, 55, 0, 'Blood Elf Warrior - Starting Two-Handed Sword');

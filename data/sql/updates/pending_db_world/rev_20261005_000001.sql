-- Allow the Cataclysm and WoW: Forever race/class combinations supported by WotLK race data.
-- Worgen, Goblin, and Skyborne are omitted because this client/core has no corresponding race data.

DELETE FROM `playercreateinfo` WHERE (`race`, `class`) IN
((1, 3), (2, 8), (3, 7), (5, 3), (5, 2), (6, 2), (6, 5), (7, 5), (8, 9), (8, 11), (10, 1));

INSERT INTO `playercreateinfo` (`race`, `class`, `map`, `zone`, `position_x`, `position_y`, `position_z`, `orientation`) VALUES
(1, 3, 0, 12, -8949.95, -132.493, 83.5312, 0), -- Human Hunter (Cataclysm / Forever)
(2, 8, 1, 14, -618.518, -4251.67, 38.718, 0), -- Orc Mage (Forever)
(3, 7, 0, 1, -6240.32, 331.033, 382.758, 6.17716), -- Dwarf Shaman (Cataclysm / Forever)
(5, 3, 0, 85, 1676.71, 1678.31, 121.67, 2.70526), -- Undead Hunter (Cataclysm)
(5, 2, 0, 85, 1676.71, 1678.31, 121.67, 2.70526), -- Undead Paladin (Forever)
(6, 2, 1, 215, -2917.58, -257.98, 52.9968, 0), -- Tauren Paladin (Cataclysm)
(6, 5, 1, 215, -2917.58, -257.98, 52.9968, 0), -- Tauren Priest (Cataclysm)
(7, 5, 0, 1, -6240, 331, 383, 0), -- Gnome Priest (Cataclysm / Forever)
(8, 9, 1, 14, -618.518, -4251.67, 38.718, 0), -- Troll Warlock (Forever)
(8, 11, 1, 14, -618.518, -4251.67, 38.718, 0), -- Troll Druid (Cataclysm)
(10, 1, 530, 3431, 10349.6, -6357.29, 33.4026, 5.31605); -- Blood Elf Warrior (Cataclysm)

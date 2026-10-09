-- Troll druid forms using existing 3.3.5a creature displays.
-- Customization 255 and gender 2 apply to every skin color and both genders.
-- Replace all troll overrides for these forms so specific variants cannot mask the defaults.
DELETE FROM `player_shapeshift_model` WHERE `RaceID` = 8 AND `ShapeshiftID` IN (1, 2, 3, 4, 5, 8, 27, 29, 31);
INSERT INTO `player_shapeshift_model` (`ShapeshiftID`, `RaceID`, `CustomizationID`, `GenderID`, `ModelID`) VALUES
(1, 8, 255, 2, 788), -- Cat: orange Stranglethorn raptor, without a saddle
(2, 8, 255, 2, 9590), -- Tree of Life: brown treant
(3, 8, 255, 2, 320), -- Travel: Stranglethorn tiger
(4, 8, 255, 2, 1039), -- Aquatic: river crocolisk
(5, 8, 255, 2, 22466), -- Bear: black Amani bear with green armor, display scale 1.25
(8, 8, 255, 2, 22466), -- Dire Bear: same Amani bear
(27, 8, 255, 2, 7894), -- Swift Flight: violet bat
(29, 8, 255, 2, 3956), -- Flight: brown bat
(31, 8, 255, 2, 17573); -- Moonkin: arakkoa sage

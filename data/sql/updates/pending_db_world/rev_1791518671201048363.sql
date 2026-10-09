--
-- Night elf druid Travel Form uses the standard deer model.
DELETE FROM `player_shapeshift_model` WHERE `RaceID` = 4 AND `ShapeshiftID` = 3;
INSERT INTO `player_shapeshift_model` (`ShapeshiftID`, `RaceID`, `CustomizationID`, `GenderID`, `ModelID`) VALUES
(3, 4, 255, 2, 347); -- Deer

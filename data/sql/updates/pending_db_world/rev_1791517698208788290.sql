--
-- Preserve night elf cat-form models and use the standard furbolg model for both bear forms.
DELETE FROM `player_shapeshift_model` WHERE `RaceID` = 4 AND `ShapeshiftID` IN (1, 5, 8);
INSERT INTO `player_shapeshift_model` (`ShapeshiftID`, `RaceID`, `CustomizationID`, `GenderID`, `ModelID`) VALUES
(1, 4, 0, 2, 29407),
(1, 4, 1, 2, 29407),
(1, 4, 2, 2, 29407),
(1, 4, 3, 2, 29406),
(1, 4, 4, 2, 29408),
(1, 4, 5, 2, 29406),
(1, 4, 6, 2, 892),
(1, 4, 7, 2, 29405),
(1, 4, 255, 2, 892),
(5, 4, 255, 2, 145), -- Bear Form
(8, 4, 255, 2, 145); -- Dire Bear Form

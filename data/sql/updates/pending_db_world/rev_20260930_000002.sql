SET @LEAFRE_RESISTANCE_RING := 274978;

DELETE FROM `fishing_loot_template` WHERE `Item` = @LEAFRE_RESISTANCE_RING;
INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `BuyPrice`, `SellPrice`, `InventoryType`,
    `ItemLevel`, `RequiredLevel`, `arcane_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `bonding`,
    `description`, `VerifiedBuild`
) VALUES (
    @LEAFRE_RESISTANCE_RING, 4, 0, 'Leafre\'s Ring of Great Resistance', 31657, 3, 0, 0, 11,
    1, 1, 150, 150, 150, 150, 150, 1, '', 0
)
ON DUPLICATE KEY UPDATE
    `class` = 4, `subclass` = 0, `name` = 'Leafre\'s Ring of Great Resistance', `displayid` = 31657,
    `Quality` = 3, `BuyPrice` = 0, `SellPrice` = 0, `InventoryType` = 11, `ItemLevel` = 1,
    `RequiredLevel` = 1, `arcane_res` = 150, `fire_res` = 150, `nature_res` = 150, `frost_res` = 150,
    `shadow_res` = 150, `bonding` = 1, `description` = '', `VerifiedBuild` = 0;

DELETE FROM `fishing_loot_template` WHERE `Item` = @LEAFRE_RESISTANCE_RING;
INSERT INTO `fishing_loot_template` (`Entry`, `Item`, `Chance`, `Comment`)
SELECT DISTINCT `Entry`, @LEAFRE_RESISTANCE_RING, 0.05, 'Leafre\'s Ring of Great Resistance'
FROM `fishing_loot_template`
WHERE `Entry` > 0;

DELETE FROM `item_dbc` WHERE `ID` = @LEAFRE_RESISTANCE_RING;
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`, `InventoryType`, `SheatheType`) VALUES
(@LEAFRE_RESISTANCE_RING, 4, 0, -1, 1, 31657, 11, 0);

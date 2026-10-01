SET @LEAFRE_ARMOR_PENETRATION_RING := 285326;

DELETE FROM `fishing_loot_template` WHERE `Item` = @LEAFRE_ARMOR_PENETRATION_RING;
INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `BuyPrice`, `SellPrice`, `InventoryType`,
    `ItemLevel`, `RequiredLevel`, `stat_type1`, `stat_value1`, `bonding`, `description`, `VerifiedBuild`
) VALUES (
    @LEAFRE_ARMOR_PENETRATION_RING, 4, 0, 'Leafre\'s Ring of Armor Piercing', 31657, 3, 0, 2, 11,
    1, 1, 44, 50, 0, '', 0
)
ON DUPLICATE KEY UPDATE
    `class` = 4, `subclass` = 0, `name` = 'Leafre\'s Ring of Armor Piercing', `displayid` = 31657,
    `Quality` = 3, `BuyPrice` = 0, `SellPrice` = 2, `InventoryType` = 11, `ItemLevel` = 1,
    `RequiredLevel` = 1, `stat_type1` = 44, `stat_value1` = 50, `bonding` = 0, `description` = '',
    `VerifiedBuild` = 0;

DELETE FROM `fishing_loot_template` WHERE `Item` = @LEAFRE_ARMOR_PENETRATION_RING;
INSERT INTO `fishing_loot_template` (`Entry`, `Item`, `Chance`, `Comment`)
SELECT DISTINCT `Entry`, @LEAFRE_ARMOR_PENETRATION_RING, 0.05, 'Leafre\'s Ring of Armor Piercing'
FROM `fishing_loot_template`
WHERE `Entry` > 0;

DELETE FROM `item_dbc` WHERE `ID` = @LEAFRE_ARMOR_PENETRATION_RING;
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`, `InventoryType`, `SheatheType`) VALUES
(@LEAFRE_ARMOR_PENETRATION_RING, 4, 0, -1, 1, 31657, 11, 0);

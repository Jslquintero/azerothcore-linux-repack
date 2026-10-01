SET @LEAFRE_RING := 276765;

UPDATE `item_template` SET `class` = 4, `subclass` = 0, `name` = 'Leafre\'s Ring of Precise Spell Power',
    `displayid` = 31664,
    `Quality` = 3, `BuyPrice` = 0, `SellPrice` = 91453, `InventoryType` = 11, `ItemLevel` = 66,
    `RequiredLevel` = 0, `stat_type1` = 45, `stat_value1` = 99, `bonding` = 1, `description` = '', `VerifiedBuild` = 0
WHERE `entry` = @LEAFRE_RING;

DELETE FROM `fishing_loot_template` WHERE `Item` = @LEAFRE_RING;
INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `BuyPrice`, `SellPrice`, `InventoryType`,
    `ItemLevel`, `RequiredLevel`, `stat_type1`, `stat_value1`, `bonding`, `description`, `VerifiedBuild`
) VALUES (
    @LEAFRE_RING, 4, 0, 'Leafre\'s Ring of Precise Spell Power', 31664, 3, 0, 91453, 11, 66,
    0, 45, 99, 1, '', 0
)
ON DUPLICATE KEY UPDATE
    `class` = 4, `subclass` = 0, `name` = 'Leafre\'s Ring of Precise Spell Power', `displayid` = 31664,
    `Quality` = 3, `BuyPrice` = 0, `SellPrice` = 91453, `InventoryType` = 11, `ItemLevel` = 66,
    `RequiredLevel` = 0, `stat_type1` = 45, `stat_value1` = 99, `bonding` = 1, `description` = '', `VerifiedBuild` = 0;

DELETE FROM `fishing_loot_template` WHERE `Item` = @LEAFRE_RING;
INSERT INTO `fishing_loot_template` (`Entry`, `Item`, `Chance`, `Comment`)
SELECT DISTINCT `Entry`, @LEAFRE_RING, 0.05, 'Leafre\'s Ring of Precise Spell Power'
FROM `fishing_loot_template`
WHERE `Entry` > 0;

DELETE FROM `item_dbc` WHERE `ID` = @LEAFRE_RING;
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`, `InventoryType`, `SheatheType`) VALUES
(@LEAFRE_RING, 4, 0, -1, 1, 31664, 11, 0);

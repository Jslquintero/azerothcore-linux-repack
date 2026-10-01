SET @ASHBRINGER := 13262;
SET @CORRUPTED_ASHBRINGER := 22691;
SET @ICHOR_OF_UNDEATH := 7972;
SET @ALTAR_ENTRY := 910110;
SET @ALTAR_MENU := 910110;
SET @LICHKING_VISION := 910102;
SET @KELTHUZAD_WHISPER := 910103;
SET @HAUNTING_MEMORIES_SCREEN_EFFECT := 50153;
-- Offsets from the altar; adjust these to position the Utgarde-style Arthas apparition.
SET @LICHKING_OFFSET_X := 7;
SET @LICHKING_OFFSET_Y := 0;
SET @LICHKING_OFFSET_Z := 0;
SET @LICHKING_OFFSET_O := 0;
SET @LICHKING_VOICELINE := 14760;
SET @KELTHUZAD_VOICELINE := 8818;

DELETE FROM `fishing_loot_template` WHERE `Item` = @ASHBRINGER;
INSERT INTO `fishing_loot_template` (`Entry`, `Item`, `Chance`, `Comment`)
SELECT DISTINCT `Entry`, @ASHBRINGER, 0.01, 'Ashbringer - rare fishing drop'
FROM `fishing_loot_template`
WHERE `Entry` > 0;

-- Retire the old Herald NPC and clean up any manual spawn made during testing.
DELETE FROM `creature` WHERE `id` = 910100;
UPDATE `creature_template` SET `npcflag` = 0 WHERE `entry` = 910100;
DELETE FROM `creature_text` WHERE `CreatureID` = 910100;
DELETE FROM `smart_scripts` WHERE (`entryorguid` = 910100 AND `source_type` = 0) OR (`entryorguid` = 910101 AND `source_type` = 9);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (@LICHKING_VISION, @KELTHUZAD_WHISPER);
INSERT INTO `creature_template` (
    `entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`,
    `unit_flags`, `type`, `AIName`, `MovementType`, `VerifiedBuild`
) VALUES
    (@LICHKING_VISION, 'Image of Arthas', 'A glimpse beyond the veil', 0, 80, 80, 35, 0, 1, 33554434, 7, 'SmartAI', 0, 0),
    (@KELTHUZAD_WHISPER, 'Kel\'Thuzad', NULL, 0, 80, 80, 35, 0, 1, 33554434, 7, 'SmartAI', 0, 0)
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`),
    `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`),
    `npcflag` = VALUES(`npcflag`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`),
    `type` = VALUES(`type`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`),
    `VerifiedBuild` = VALUES(`VerifiedBuild`);

REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data19`, `AIName`, `VerifiedBuild`)
VALUES (@ALTAR_ENTRY, 10, 206, 'Ritual Altar', 1, @ALTAR_MENU, 'SmartGameObjectAI', 0);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (@LICHKING_VISION, @KELTHUZAD_WHISPER);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
    (@LICHKING_VISION, 0, 11686, 1, 1, 0),
    (@KELTHUZAD_WHISPER, 0, 11686, 1, 1, 0);

DELETE FROM `npc_text` WHERE `ID` IN (910110, 910111);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `lang0`, `Probability0`)
VALUES (
    910110,
    'That light... I know what sleeps beneath it. Something old stirs within the relic you bear, yet its shadow is not its own. Follow the grave\'s cold whisper, and the truth will find you.',
    '', 0, 100
), (
    910111,
    'The dead stir in your wake, though no relic hangs at your side. Seek the light that once defied the grave, and bring what the earth keeps in its cold embrace. Only then will silence yield its secret.',
    '', 0, 100
);

DELETE FROM `gossip_menu` WHERE `MenuID` = @ALTAR_MENU;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES (@ALTAR_MENU, 910110), (@ALTAR_MENU, 910111);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = @ALTAR_MENU;
INSERT INTO `gossip_menu_option` (
    `MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`,
    `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`
) VALUES (
    @ALTAR_MENU, 0, 0, 'The relic and its shadow are prepared. Begin the rite.', 0, 1, 0,
    0, 0, 0, 0, '', 0, 0
);

DELETE FROM `conditions` WHERE (`SourceTypeOrReferenceId` IN (14, 15) AND `SourceGroup` = @ALTAR_MENU)
    OR (`SourceTypeOrReferenceId` = 22 AND `SourceEntry` = @ALTAR_ENTRY AND `SourceId` = 1 AND `SourceGroup` = 1);
DELETE FROM `conditions` WHERE `SourceGroup` = @ALTAR_MENU;
INSERT INTO `conditions` (
    `SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`,
    `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `Comment`
) VALUES
    (14, @ALTAR_MENU, 910110, 0, 0, 2, 0, @ASHBRINGER, 1, 0, 0, 'Show ritual lore greeting when player carries Ashbringer'),
    (14, @ALTAR_MENU, 910111, 0, 0, 2, 0, @ASHBRINGER, 1, 0, 1, 'Show cryptic greeting when player lacks Ashbringer'),
    (15, @ALTAR_MENU, 0, 0, 0, 2, 0, @ASHBRINGER, 1, 0, 0, 'Ritual requires Ashbringer'),
    (15, @ALTAR_MENU, 0, 0, 0, 2, 0, @ICHOR_OF_UNDEATH, 10, 0, 0, 'Ritual requires 10 Ichor of Undeath'),
    (15, @ALTAR_MENU, 0, 0, 0, 3, 0, @ASHBRINGER, 0, 0, 1, 'Ashbringer must be unequipped before the ritual'),
    (22, 1, @ALTAR_ENTRY, 1, 0, 2, 0, @ASHBRINGER, 1, 0, 0, 'Verify Ashbringer when altar option is selected'),
    (22, 1, @ALTAR_ENTRY, 1, 0, 2, 0, @ICHOR_OF_UNDEATH, 10, 0, 0, 'Verify 10 Ichor of Undeath when altar option is selected'),
    (22, 1, @ALTAR_ENTRY, 1, 0, 3, 0, @ASHBRINGER, 0, 0, 1, 'Ashbringer must remain unequipped when altar option is selected');

DELETE FROM `creature_text` WHERE `CreatureID` = @KELTHUZAD_WHISPER;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES (@KELTHUZAD_WHISPER, 0, 0, 'Even the brightest flame casts a shadow.', 15, 0, 100, 0, 0, @KELTHUZAD_VOICELINE, 0, 0, 'Kel\'Thuzad whispers to the player');

DELETE FROM `smart_scripts` WHERE (`entryorguid` = @ALTAR_ENTRY AND `source_type` = 1)
    OR (`entryorguid` IN (@LICHKING_VISION, @KELTHUZAD_WHISPER) AND `source_type` = 0)
    OR (`entryorguid` IN (910111, 910104) AND `source_type` = 9);
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (@ALTAR_ENTRY, @LICHKING_VISION, @KELTHUZAD_WHISPER, 910111, 910104);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`,
    `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`
) VALUES
    (@ALTAR_ENTRY, 1, 0, 1, 62, 0, 100, 0, @ALTAR_MENU, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Altar - Ritual - Close gossip'),
    (@ALTAR_ENTRY, 1, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 57, @ASHBRINGER, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Altar - Ritual - Consume Ashbringer'),
    (@ALTAR_ENTRY, 1, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 57, @ICHOR_OF_UNDEATH, 10, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Altar - Ritual - Consume 10 Ichor of Undeath'),
    (@ALTAR_ENTRY, 1, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 105, 16, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Altar - Ritual - Disable altar while ritual runs'),
    (@ALTAR_ENTRY, 1, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 910111, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Altar - Ritual - Begin roleplay'),
    (910111, 9, 0, 0, 1, 0, 100, 0, 0, 0, 0, 0, 0, 0, 75, @HAUNTING_MEMORIES_SCREEN_EFFECT, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Altar - Ritual - Darken the player screen'),
    (910111, 9, 1, 0, 1, 0, 100, 0, 6500, 6500, 0, 0, 0, 0, 12, @KELTHUZAD_WHISPER, 3, 3000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Altar - Ritual - Summon Kel\'Thuzad whisper'),
    (910111, 9, 2, 0, 1, 0, 100, 0, 13000, 13000, 0, 0, 0, 0, 12, @LICHKING_VISION, 3, 9000, 0, 0, 0, 1, 0, 0, 0, 0, @LICHKING_OFFSET_X, @LICHKING_OFFSET_Y, @LICHKING_OFFSET_Z, @LICHKING_OFFSET_O, 'Altar - Ritual - Summon Arthas apparition'),
    (910111, 9, 3, 0, 1, 0, 100, 0, 18000, 18000, 0, 0, 0, 0, 28, @HAUNTING_MEMORIES_SCREEN_EFFECT, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Altar - Ritual - Restore the player screen'),
    (910111, 9, 4, 0, 1, 0, 100, 0, 20000, 20000, 0, 0, 0, 0, 106, 16, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Altar - Ritual - Re-enable altar'),
    (@LICHKING_VISION, 0, 0, 0, 63, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 910104, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Arthas - Begin appearance and reward'),
    (910104, 9, 0, 0, 1, 0, 100, 0, 1500, 1500, 0, 0, 0, 0, 3, 0, 26100, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Arthas - Appear as Utgarde Pinnacle Image of Arthas'),
    (910104, 9, 1, 0, 1, 0, 100, 0, 1501, 1501, 0, 0, 0, 0, 227, 65, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Arthas - Set apparition scale to 65 percent'),
    (910104, 9, 2, 0, 1, 0, 100, 0, 1600, 1600, 0, 0, 0, 0, 4, @LICHKING_VOICELINE, 1, 0, 0, 0, 0, 21, 30, 0, 0, 0, 0, 0, 0, 0, 'Arthas - Play Lich King farewell voiceline'),
    (910104, 9, 3, 0, 1, 0, 100, 0, 3500, 3500, 0, 0, 0, 0, 56, @CORRUPTED_ASHBRINGER, 1, 0, 0, 0, 0, 21, 30, 0, 0, 0, 0, 0, 0, 0, 'Arthas - Give Corrupted Ashbringer to the player'),
    (910104, 9, 4, 0, 1, 0, 100, 0, 6500, 6500, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Arthas - Despawn after five seconds'),
    (@KELTHUZAD_WHISPER, 0, 0, 0, 63, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 21, 30, 0, 0, 0, 0, 0, 0, 0, 'Kel\'Thuzad - Whisper to the nearest player');

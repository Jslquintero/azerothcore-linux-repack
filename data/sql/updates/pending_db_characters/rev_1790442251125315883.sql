-- Preserve existing Night Elf action buttons while replacing the stock WotLK Shadowmeld.
UPDATE `character_action` `ca`
INNER JOIN `characters` `c` ON `c`.`guid` = `ca`.`guid` SET `ca`.`action` = 20580
WHERE `c`.`race` = 4 AND `ca`.`type` = 0 AND `ca`.`action` = 58984;

DELETE `ca`
FROM `character_aura` `ca`
INNER JOIN `characters` `c` ON `c`.`guid` = `ca`.`guid`
WHERE `c`.`race` = 4 AND `ca`.`spell` IN (58984, 910031);

DELETE `cs`
FROM `character_spell` `cs`
INNER JOIN `characters` `c` ON `c`.`guid` = `cs`.`guid`
WHERE `c`.`race` = 4 AND `cs`.`spell` = 58984;

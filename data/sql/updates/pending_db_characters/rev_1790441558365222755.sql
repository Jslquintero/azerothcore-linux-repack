-- Remove obsolete dwarf racials saved before their original DBC learning records were disabled.
DELETE `ca`
FROM `character_action` `ca`
INNER JOIN `characters` `c` ON `c`.`guid` = `ca`.`guid`
WHERE `c`.`race` = 3 AND `ca`.`type` = 0 AND `ca`.`action` IN (20595, 59224);

DELETE `ca`
FROM `character_aura` `ca`
INNER JOIN `characters` `c` ON `c`.`guid` = `ca`.`guid`
WHERE `c`.`race` = 3 AND `ca`.`spell` IN (20595, 59224);

DELETE `cs`
FROM `character_spell` `cs`
INNER JOIN `characters` `c` ON `c`.`guid` = `cs`.`guid`
WHERE `c`.`race` = 3 AND `cs`.`spell` IN (20595, 59224);

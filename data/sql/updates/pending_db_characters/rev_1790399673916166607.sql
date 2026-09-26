-- Remove obsolete human racials if they were explicitly saved on existing characters.
DELETE `ca`
FROM `character_action` `ca`
INNER JOIN `characters` `c` ON `c`.`guid` = `ca`.`guid`
WHERE `c`.`race` = 1 AND `ca`.`type` = 0 AND `ca`.`action` IN (20599, 20864, 59752);

DELETE `ca`
FROM `character_aura` `ca`
INNER JOIN `characters` `c` ON `c`.`guid` = `ca`.`guid`
WHERE `c`.`race` = 1 AND `ca`.`spell` IN (20599, 20864, 59752);

DELETE `cs`
FROM `character_spell` `cs`
INNER JOIN `characters` `c` ON `c`.`guid` = `cs`.`guid`
WHERE `c`.`race` = 1 AND `cs`.`spell` IN (20599, 20864, 59752);

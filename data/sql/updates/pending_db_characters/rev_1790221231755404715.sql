--
DELETE `ca`
FROM `character_action` `ca`
INNER JOIN `characters` `c` ON `c`.`guid` = `ca`.`guid`
WHERE `c`.`race` = 5 AND `ca`.`action` = 910017;

DELETE `csc`
FROM `character_spell_cooldown` `csc`
INNER JOIN `characters` `c` ON `c`.`guid` = `csc`.`guid`
WHERE `c`.`race` = 5 AND `csc`.`spell` = 910017;

DELETE `ca`
FROM `character_aura` `ca`
INNER JOIN `characters` `c` ON `c`.`guid` = `ca`.`guid`
WHERE `c`.`race` = 5 AND `ca`.`spell` = 910017;

DELETE `cs`
FROM `character_spell` `cs`
INNER JOIN `characters` `c` ON `c`.`guid` = `cs`.`guid`
WHERE `c`.`race` = 5 AND `cs`.`spell` = 910017;

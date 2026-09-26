--
-- Remove Da Voodoo Shuffle from existing trolls and their saved passive auras.
DELETE `cs`
FROM `character_spell` `cs`
INNER JOIN `characters` `c` ON `c`.`guid` = `cs`.`guid`
WHERE `c`.`race` = 8 AND `cs`.`spell` = 58943;

DELETE `ca`
FROM `character_aura` `ca`
INNER JOIN `characters` `c` ON `c`.`guid` = `ca`.`guid`
WHERE `c`.`race` = 8 AND `ca`.`spell` = 58943;

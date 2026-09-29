-- Apply with characters offline. Racial skill records and the login script restore the correct variants.

DELETE `r`
FROM `character_action` `r`
INNER JOIN `characters` `c` ON `c`.`guid` = `r`.`guid`
WHERE `c`.`race` = 7 AND `r`.`type` = 0
AND (`r`.`action` = 20592 OR (`r`.`action` = 20591 AND `c`.`class` NOT IN (2, 3, 5, 7, 8, 9, 11)));

DELETE `r`
FROM `character_aura` `r`
INNER JOIN `characters` `c` ON `c`.`guid` = `r`.`guid`
WHERE `c`.`race` = 7
AND (`r`.`spell` = 20592 OR (`r`.`spell` = 20591 AND `c`.`class` NOT IN (2, 3, 5, 7, 8, 9, 11)));

DELETE `r`
FROM `character_spell` `r`
INNER JOIN `characters` `c` ON `c`.`guid` = `r`.`guid`
WHERE `c`.`race` = 7
AND (`r`.`spell` = 20592 OR (`r`.`spell` = 20591 AND `c`.`class` NOT IN (2, 3, 5, 7, 8, 9, 11)));

DELETE `r`
FROM `character_aura` `r`
INNER JOIN `characters` `c` ON `c`.`guid` = `r`.`guid`
WHERE `c`.`race` = 7 AND `r`.`spell` IN (910025, 910026, 910027, 910028);

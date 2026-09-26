-- Tauren: active Cultivation and visible, stacking Plainsrunning.
-- The stock Cultivation exists only in Spell.dbc; UPDATE alone cannot override it.
DELETE FROM `spell_dbc` WHERE `ID` = 20552;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `CastingTimeIndex`, `RangeIndex`, `EquippedItemClass`, `Effect_1`, `EffectDieSides_1`,
`EffectBasePoints_1`, `ImplicitTargetA_1`, `EffectRadiusIndex_1`, `SpellIconID`, `Name_Lang_enUS`,
`Description_Lang_enUS`, `StartRecoveryCategory`, `StartRecoveryTime`, `PreventionType`, `SchoolMask`) VALUES
(20552, 16, 1, 1, -1, 3, 1, 15, 1, 8, 1626, 'Cultivation',
CONCAT('Cultivate a nearby herb, growing a duplicate you can harvest without requiring Herbalism skill. ',
'Each herb may only be cultivated once.'),
133, 1500, 1, 1);

UPDATE `spell_dbc` SET `AttributesEx` = 0, `CumulativeAura` = 30,
`AuraDescription_Lang_enUS` = 'Movement speed increased by $s1%.' WHERE `ID` = 910016;

-- Reserve original entry + 1000000 for unlocked, single-use Cultivation copies.
-- Herbalism lock IDs are from the server's 3.3.5a Lock.dbc (skill lock type 2).
-- Keep the original appearance and loot table; omit events, traps, quest and profession restrictions.
DELETE FROM `gameobject_template` WHERE `entry` >= 1000000 AND `castBarCaption` = 'Cultivation';
INSERT INTO `gameobject_template`
(`entry`, `type`, `displayId`, `name`, `castBarCaption`, `size`, `Data1`, `Data3`, `Data4`, `Data5`)
SELECT `entry` + 1000000, 3, `displayId`, `name`, 'Cultivation', `size`, `Data1`, 1, 1, 1
FROM `gameobject_template`
WHERE `entry` < 1000000 AND `type` = 3 AND `Data0` IN
(8, 9, 10, 11, 26, 27, 29, 30, 31, 32, 33, 34, 35, 45, 47, 48, 49, 50, 51, 259, 439, 440, 441, 442, 443, 444,
519, 521, 1119, 1120, 1121, 1122, 1123, 1124, 1639, 1641, 1642, 1643, 1644, 1645, 1646, 1702, 1714, 1786, 1787,
1788, 1789, 1790, 1791, 1792, 1793);

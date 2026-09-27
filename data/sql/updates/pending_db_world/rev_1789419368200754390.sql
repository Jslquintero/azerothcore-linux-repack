--
-- WoW Forever Orc, Tauren, Troll, Undead, Dwarf, Gnome, Human, Night Elf, Blood Elf, and Draenei racial updates.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (20552, 20572, 20578, 20594, 33697, 33702);
DELETE FROM `spell_script_names` WHERE `spell_id` BETWEEN 910001 AND 910035;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(20552, 'spell_wf_racial_cultivation'),
(20572, 'spell_wf_racial_blood_fury'),
(20594, 'spell_wf_racial_stoneform'),
(33697, 'spell_wf_racial_blood_fury'),
(33702, 'spell_wf_racial_blood_fury'),
(910017, 'spell_wf_racial_rapid_regeneration');

UPDATE `spell_dbc` SET
`RecoveryTime` = 120000,
`DurationIndex` = 8,
`Effect_1` = 6, `Effect_2` = 6, `Effect_3` = 6,
`EffectDieSides_1` = 1, `EffectDieSides_2` = 1, `EffectDieSides_3` = 1,
`EffectBasePoints_1` = 9, `EffectBasePoints_2` = 9, `EffectBasePoints_3` = 9,
`EffectAura_1` = 166, `EffectAura_2` = 167, `EffectAura_3` = 4,
`ImplicitTargetA_1` = 1, `ImplicitTargetA_2` = 1, `ImplicitTargetA_3` = 1,
`SpellIconID` = 1662,
`Description_Lang_enUS` = 'Increases Attack Power and Spell Power by 10% for 15 sec.',
`AuraDescription_Lang_enUS` = 'Attack Power and Spell Power increased by 10%.',
`SchoolMask` = 1
WHERE `ID` IN (20572, 33697, 33702);

UPDATE `spell_dbc` SET
`EffectBasePoints_1` = -21,
`SpellIconID` = 1652,
`Description_Lang_enUS` = 'Duration of Stun effects on you reduced by 20%.'
WHERE `ID` = 20573;

UPDATE `spell_dbc` SET
`EquippedItemClass` = -1,
`EquippedItemSubclass` = 0,
`EquippedItemInvTypes` = 0,
`Effect_1` = 6,
`EffectBasePoints_1` = -1,
`EffectAura_1` = 4,
`ImplicitTargetA_1` = 1,
`SpellIconID` = 1628,
`Description_Lang_enUS` = CONCAT('Increases your critical strike chance with all spells and abilities by 1% ',
'while you have an axe or a two-handed axe equipped.')
WHERE `ID` = 20574;

UPDATE `spell_dbc` SET
`Attributes` = 327696,
`AttributesEx` = 136,
`CastingTimeIndex` = 3,
`RecoveryTime` = 120000,
`DurationIndex` = 39,
`Effect_1` = 6, `EffectBasePoints_1` = -1, `EffectAura_1` = 12,
`ImplicitTargetA_1` = 18,
`EffectRadiusIndex_1` = 14,
`MaxTargets` = 5,
`SpellIconID` = 129,
`Description_Lang_enUS` = 'Stuns up to 5 enemies within 8 yds for 2 sec.',
`AuraDescription_Lang_enUS` = 'Stunned.'
WHERE `ID` = 20549;

UPDATE `spell_dbc` SET
`Effect_1` = 6, `Effect_2` = 6, `Effect_3` = 6,
`EffectBasePoints_1` = 4, `EffectBasePoints_2` = 0, `EffectBasePoints_3` = 0,
`EffectAura_1` = 133, `EffectAura_2` = 54, `EffectAura_3` = 55,
`ImplicitTargetA_1` = 1, `ImplicitTargetA_2` = 1, `ImplicitTargetA_3` = 1,
`SpellIconID` = 312,
`Description_Lang_enUS` = 'Total Health increased by 5% and chance to hit increased by 1%.'
WHERE `ID` = 20550;

UPDATE `spell_dbc` SET
`Attributes` = 16,
`AttributesEx` = 0,
`DurationIndex` = 0,
`Effect_1` = 3, `Effect_2` = 0, `Effect_3` = 0,
`EffectBasePoints_1` = 15, `EffectBasePoints_2` = 0, `EffectBasePoints_3` = 0,
`EffectAura_1` = 0, `EffectAura_2` = 0, `EffectAura_3` = 0,
`ImplicitTargetA_1` = 1, `ImplicitTargetA_2` = 0, `ImplicitTargetA_3` = 0,
`EffectRadiusIndex_1` = 8,
`SpellIconID` = 1626,
`Description_Lang_enUS` = CONCAT('Cultivate a nearby herb, growing a duplicate you can harvest without requiring ',
'Herbalism skill. Each herb may only be cultivated once.'),
`AuraDescription_Lang_enUS` = '',
`StartRecoveryCategory` = 133,
`StartRecoveryTime` = 1500
WHERE `ID` = 20552;

DELETE FROM `spell_dbc` WHERE `ID` = 20554;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `AttributesEx`, `CastingTimeIndex`, `RecoveryTime`, `DurationIndex`, `PowerType`, `RangeIndex`,
`SpellLevel`, `Effect_1`, `Effect_2`, `Effect_3`, `EffectDieSides_1`, `EffectDieSides_2`, `EffectDieSides_3`,
`EffectBasePoints_1`, `EffectBasePoints_2`, `EffectBasePoints_3`, `EffectAura_1`, `EffectAura_2`, `EffectAura_3`,
`EffectAuraPeriod_1`, `EffectAuraPeriod_2`, `EffectAuraPeriod_3`, `ImplicitTargetA_1`, `ImplicitTargetA_2`,
`ImplicitTargetA_3`, `EffectMiscValue_1`, `EffectMiscValue_2`,
`EffectMiscValue_3`, `EffectTriggerSpell_1`, `SpellIconID`, `Name_Lang_enUS`, `Description_Lang_enUS`,
`AuraDescription_Lang_enUS`, `StartRecoveryCategory`, `StartRecoveryTime`, `PreventionType`, `SchoolMask`) VALUES
(20554, 16, 0, 1, 180000, 1, 0, 1, 1, 6, 6, 6, 1, 1, 1, 9, 9, 9, 138, 140, 65, 0, 0, 0, 1, 1, 1, 0, 0, 0,
0, 1814, 'Berserking', 'Increases your spellcasting and attack speed by 10% for 10 sec.',
'Spellcasting and attack speed increased by 10%.', 0, 0, 1, 1);

UPDATE `spell_dbc` SET
`Effect_1` = 6,
`EffectBasePoints_1` = 4,
`EffectAura_1` = 168,
`ImplicitTargetA_1` = 1,
`EffectMiscValue_1` = 1,
`SpellIconID` = 1653,
`Description_Lang_enUS` = 'Damage dealt versus Beasts increased by 5%.'
WHERE `ID` = 20557;

UPDATE `spell_dbc` SET
`Effect_1` = 6, `Effect_2` = 6, `Effect_3` = 0,
`EffectBasePoints_1` = 9, `EffectBasePoints_2` = 9, `EffectBasePoints_3` = 0,
`EffectAura_1` = 88, `EffectAura_2` = 116, `EffectAura_3` = 0,
`ImplicitTargetA_1` = 1, `ImplicitTargetA_2` = 1, `ImplicitTargetA_3` = 0,
`SpellIconID` = 149,
`Description_Lang_enUS` = CONCAT('Health regeneration rate increased by 10%. In addition, 10% of total Health ',
'regeneration will continue during combat.')
WHERE `ID` = 20555;

UPDATE `spell_dbc` SET
`Attributes` = 16,
`AttributesEx` = 0,
`RecoveryTime` = 120000,
`DurationIndex` = 0,
`Effect_1` = 108, `Effect_2` = 108, `Effect_3` = 108,
`EffectDieSides_1` = 1, `EffectDieSides_2` = 1, `EffectDieSides_3` = 1,
`EffectBasePoints_1` = 99, `EffectBasePoints_2` = 99, `EffectBasePoints_3` = 99,
`EffectAura_1` = 0, `EffectAura_2` = 0, `EffectAura_3` = 0,
`ImplicitTargetA_1` = 1, `ImplicitTargetA_2` = 1, `ImplicitTargetA_3` = 1,
`EffectMiscValue_1` = 5, `EffectMiscValue_2` = 10, `EffectMiscValue_3` = 1,
`SpellIconID` = 61,
`Description_Lang_enUS` = 'Removes any Charm, Fear, and Sleep effect. 2 min cooldown.',
`AuraDescription_Lang_enUS` = '',
`StartRecoveryCategory` = 133,
`StartRecoveryTime` = 0
WHERE `ID` = 7744;

-- Keep the native corpse check and cast behavior; only the triggered aura gains mana regeneration.
DELETE FROM `spell_dbc` WHERE `ID` = 20577;

DELETE FROM `spell_dbc` WHERE `ID` = 20578;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `AttributesEx`, `CastingTimeIndex`, `RecoveryTime`, `DurationIndex`, `PowerType`, `RangeIndex`,
`SpellLevel`, `Effect_1`, `Effect_2`, `Effect_3`, `EffectDieSides_1`, `EffectDieSides_2`, `EffectDieSides_3`,
`EffectBasePoints_1`, `EffectBasePoints_2`, `EffectBasePoints_3`, `EffectAura_1`, `EffectAura_2`, `EffectAura_3`,
`EffectAuraPeriod_1`, `EffectAuraPeriod_2`, `EffectAuraPeriod_3`, `ImplicitTargetA_1`, `ImplicitTargetA_2`,
`ImplicitTargetA_3`, `EffectMiscValue_1`, `EffectMiscValue_2`, `EffectMiscValue_3`, `EffectTriggerSpell_1`,
`SpellIconID`, `Name_Lang_enUS`, `Description_Lang_enUS`, `AuraDescription_Lang_enUS`, `StartRecoveryCategory`,
`StartRecoveryTime`, `PreventionType`, `SchoolMask`, `ChannelInterruptFlags`, `ProcChance`, `EquippedItemClass`,
`SpellVisualID_1`, `EffectChainAmplitude_1`, `EffectChainAmplitude_2`,
`EffectBonusMultiplier_2`, `EffectBonusMultiplier_3`) VALUES
(20578, 0, 536870976, 1, 0, 1, 0, 1, 0, 6, 6, 0, 1, 1, 0, 6, 6, 0, 20, 21, 0, 2000, 2000, 0, 1, 1, 0, 0, 0, 0,
0, 146, 'Cannibalize', '', 'Regenerating 7% of total Health and Mana every 2 sec.',
0, 0, 0, 1, 15374, 101, -1, 5724, 1, 1, 1, 1);

UPDATE `spell_dbc` SET
`Effect_1` = 6,
`EffectBasePoints_1` = 299,
`EffectAura_1` = 155,
`ImplicitTargetA_1` = 1,
`SpellIconID` = 545,
`Description_Lang_enUS` = 'Underwater breath lasts 300% longer than normal.'
WHERE `ID` = 5227;

UPDATE `spell_dbc` SET
`Attributes` = 688128016,
`AttributesEx` = 268566560,
`CastingTimeIndex` = 1,
`DurationIndex` = 21,
`Effect_1` = 6, `Effect_2` = 0, `Effect_3` = 0,
`EffectBasePoints_1` = 0,
`EffectAura_1` = 45, `EffectAura_2` = 0, `EffectAura_3` = 0,
`ImplicitTargetA_1` = 0, `ImplicitTargetA_2` = 0, `ImplicitTargetA_3` = 0,
`EffectMiscValue_1` = 6,
`SpellIconID` = 202,
`Description_Lang_enUS` = CONCAT('Allows the dwarf to sense nearby treasure, making it appear on the minimap. ',
'Lasts until canceled.'),
`StartRecoveryCategory` = 133,
`StartRecoveryTime` = 1500,
`SchoolMask` = 1
WHERE `ID` = 2481;

UPDATE `spell_dbc` SET
`Attributes` = 262400,
`AttributesEx` = 268566528,
`CastingTimeIndex` = 1,
`RecoveryTime` = 180000,
`DurationIndex` = 31,
`Effect_1` = 6, `Effect_2` = 6, `Effect_3` = 6,
`EffectDieSides_1` = 1, `EffectDieSides_2` = 1, `EffectDieSides_3` = 1,
`EffectBasePoints_1` = -1, `EffectBasePoints_2` = -1, `EffectBasePoints_3` = -1,
`EffectAura_1` = 41, `EffectAura_2` = 41, `EffectAura_3` = 77,
`ImplicitTargetA_1` = 1, `ImplicitTargetA_2` = 1, `ImplicitTargetA_3` = 1,
`EffectMiscValue_1` = 4, `EffectMiscValue_2` = 3, `EffectMiscValue_3` = 15,
`SpellVisualID_1` = 5787,
`SpellIconID` = 93,
`Description_Lang_enUS` = CONCAT('Instantly removes and grants immunity to all Bleed, Poison, and Disease effects, ',
'and reduces all Physical damage taken by 10% for 8 sec.'),
`AuraDescription_Lang_enUS` = CONCAT('Immune to Bleed, Poison, and Disease effects. Physical damage taken reduced ',
'by 10%.'),
`StartRecoveryCategory` = 133,
`StartRecoveryTime` = 0,
`PreventionType` = 2,
`SchoolMask` = 1
WHERE `ID` = 20594;

UPDATE `spell_dbc` SET
`Attributes` = 32784,
`AttributesEx` = 32768,
`CastingTimeIndex` = 1,
`RecoveryTime` = 120000,
`DurationIndex` = 28,
`Effect_1` = 6, `Effect_2` = 6, `Effect_3` = 0,
`EffectDieSides_1` = 1, `EffectDieSides_2` = 1, `EffectDieSides_3` = 0,
`EffectBasePoints_1` = 10, `EffectBasePoints_2` = 10, `EffectBasePoints_3` = 0,
`EffectAura_1` = 77, `EffectAura_2` = 77, `EffectAura_3` = 0,
`ImplicitTargetA_1` = 1, `ImplicitTargetA_2` = 1, `ImplicitTargetA_3` = 0,
`EffectMiscValue_1` = 7, `EffectMiscValue_2` = 11, `EffectMiscValue_3` = 0,
`SpellVisualID_1` = 1008,
`SpellIconID` = 517,
`Description_Lang_enUS` = CONCAT('Instantly escape the effects of any movement impairing effect and gain immunity ',
'to those effects for 3 sec.'),
`AuraDescription_Lang_enUS` = 'Immune to movement impairing effects.',
`StartRecoveryCategory` = 133,
`StartRecoveryTime` = 1500,
`PreventionType` = 2,
`SchoolMask` = 1
WHERE `ID` = 20589;

UPDATE `spell_dbc` SET
`Effect_1` = 6,
`EffectBasePoints_1` = 4,
`EffectAura_1` = 137,
`ImplicitTargetA_1` = 1,
`EffectMiscValue_1` = 3,
`SpellIconID` = 1654,
`Description_Lang_enUS` = 'Maximum Mana increased by 5%.'
WHERE `ID` = 20591;

UPDATE `spell_dbc` SET
`Effect_1` = 6,
`EffectBasePoints_1` = 20,
`EffectAura_1` = 4,
`ImplicitTargetA_1` = 1,
`SpellIconID` = 353,
`Description_Lang_enUS` = CONCAT('Your gnomish ingenuity reduces the rate of engineering devices failing or ',
'backfiring when you use them by 20%.')
WHERE `ID` = 20593;

UPDATE `spell_dbc` SET
`DurationIndex` = 0,
`Effect_1` = 6,
`EffectBasePoints_1` = 4,
`EffectAura_1` = 137,
`ImplicitTargetA_1` = 1,
`EffectMiscValue_1` = 4,
`SpellIconID` = 1656,
`Description_Lang_enUS` = 'Spirit increased by 5%.'
WHERE `ID` = 20598;

UPDATE `spell_dbc` SET
`EquippedItemClass` = -1,
`EquippedItemSubclass` = 0,
`EquippedItemInvTypes` = 0,
`DurationIndex` = 21,
`Effect_1` = 6,
`EffectBasePoints_1` = 1,
`EffectAura_1` = 4,
`ImplicitTargetA_1` = 1,
`SpellIconID` = 1462,
`Description_Lang_enUS` = CONCAT('Increases your critical strike chance with all spells and attacks by 2% ',
'while you have a sword or two-handed sword equipped.')
WHERE `ID` = 20597;

UPDATE `spell_dbc` SET
`Attributes` = 262160,
`AttributesEx` = 32,
`AttributesEx2` = 524288,
`CastingTimeIndex` = 1,
`RecoveryTime` = 180000,
`DurationIndex` = 18,
`Effect_1` = 6,
`EffectBasePoints_1` = 50,
`EffectAura_1` = 17,
`ImplicitTargetA_1` = 1,
`SpellVisualID_1` = 5727,
`SpellIconID` = 44,
`Description_Lang_enUS` = 'Dramatically increases stealth detection for 20 sec.',
`AuraDescription_Lang_enUS` = 'Stealth detection dramatically increased.',
`StartRecoveryCategory` = 133,
`StartRecoveryTime` = 1500,
`SchoolMask` = 1
WHERE `ID` = 20600;

DELETE FROM `spell_dbc` WHERE `ID` = 20580;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `AttributesEx`, `CastingTimeIndex`, `RecoveryTime`, `DurationIndex`, `PowerType`, `RangeIndex`,
`SpellLevel`, `Effect_1`, `Effect_2`, `Effect_3`, `EffectDieSides_1`, `EffectDieSides_2`, `EffectDieSides_3`,
`EffectBasePoints_1`, `EffectBasePoints_2`, `EffectBasePoints_3`, `EffectAura_1`, `EffectAura_2`, `EffectAura_3`,
`EffectAuraPeriod_1`, `EffectAuraPeriod_2`, `EffectAuraPeriod_3`, `ImplicitTargetA_1`, `ImplicitTargetA_2`,
`ImplicitTargetA_3`, `EffectMiscValue_1`, `EffectMiscValue_2`,
`EffectMiscValue_3`, `EffectTriggerSpell_1`, `SpellIconID`, `Name_Lang_enUS`, `Description_Lang_enUS`,
`AuraDescription_Lang_enUS`, `StartRecoveryCategory`, `StartRecoveryTime`, `PreventionType`, `SchoolMask`) VALUES
(20580, 1376272, 132112, 1, 10000, 21, 0, 1, 1, 6, 6, 0, 1, 1, 0, 0, -999999, 0, 16, 103, 0,
0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 103, 'Shadowmeld', CONCAT('Activate to slip into the shadows, reducing the chance ',
'for enemies to detect your presence. Lasts until cancelled or upon moving. Using this ability in combat discourages ',
'enemies from attacking you, but increases the cooldown to 2 min.'), 'Shadowmelded.', 0, 0, 2, 1);

UPDATE `spell_dbc` SET `AttributesEx2` = 2621444 WHERE `ID` = 20580;

UPDATE `spell_dbc` SET
`DurationIndex` = 21,
`Effect_1` = 6, `Effect_2` = 6, `Effect_3` = 6,
`EffectBasePoints_1` = 0, `EffectBasePoints_2` = 1, `EffectBasePoints_3` = 0,
`EffectAura_1` = 49, `EffectAura_2` = 31, `EffectAura_3` = 154,
`ImplicitTargetA_1` = 1, `ImplicitTargetA_2` = 1, `ImplicitTargetA_3` = 1,
`SpellIconID` = 131,
`Description_Lang_enUS` = CONCAT('Dodge chance increased by 1% and movement speed increased by 2%. Night Elf ',
'Rogues and Druids are harder to detect in Stealth as if they were 1 level higher.')
WHERE `ID` = 20582;

UPDATE `spell_dbc` SET
`Effect_1` = 3,
`EffectBasePoints_1` = 0,
`ImplicitTargetA_1` = 1,
`SpellIconID` = 122,
`Description_Lang_enUS` = 'Transform into a wisp upon death, increasing movement speed by 75%.'
WHERE `ID` = 20585;

DELETE FROM `spell_dbc` WHERE `ID` BETWEEN 910001 AND 910035;
INSERT INTO `spell_dbc`
(`ID`, `Attributes`, `AttributesEx`, `CastingTimeIndex`, `RecoveryTime`, `DurationIndex`, `PowerType`, `RangeIndex`,
`SpellLevel`, `Effect_1`, `Effect_2`, `Effect_3`, `EffectDieSides_1`, `EffectDieSides_2`, `EffectDieSides_3`,
`EffectBasePoints_1`, `EffectBasePoints_2`, `EffectBasePoints_3`, `EffectAura_1`, `EffectAura_2`, `EffectAura_3`,
`EffectAuraPeriod_1`, `EffectAuraPeriod_2`, `EffectAuraPeriod_3`, `ImplicitTargetA_1`, `ImplicitTargetA_2`,
`ImplicitTargetA_3`, `EffectMiscValue_1`, `EffectMiscValue_2`,
`EffectMiscValue_3`, `EffectTriggerSpell_1`, `SpellIconID`, `Name_Lang_enUS`, `Description_Lang_enUS`,
`AuraDescription_Lang_enUS`, `StartRecoveryCategory`, `StartRecoveryTime`, `PreventionType`, `SchoolMask`) VALUES
(910001, 16, 32768, 1, 180000, 0, 0, 1, 1, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
910002, 542,
'Shatter Curse', CONCAT('Instantly removes and grants immunity to all Curses and Banes, and reduces all Magical ',
'damage taken by 15% for 8 sec.'), '', 133, 1500, 1, 1),
(910002, 0, 32768, 1, 0, 31, 0, 1, 1, 6, 38, 6, 1, 1, 1, -16, 99, 0, 87, 0, 41, 0, 0, 0, 1, 1, 1, 126, 2, 2,
0, 542, 'Shatter Curse', '', 'Immune to Curses and Banes. Reduces Magical damage taken by 15%.', 0, 0, 1, 32),
(910013, 80, 268435456, 1, 0, 21, 0, 1, 1, 6, 6, 6, 1, 1, 1, 1, 5, 30, 226, 4, 4, 1000, 0, 0, 1, 1, 1, 0, 0,
0, 0, 2208, 'Plainsrunning', CONCAT('Gain 1% increased movement speed every 5 sec spent moving, up to a maximum ',
'of 30% increase. Taking damage or standing still will reduce this effect.'), '', 0, 0, 1, 1),
(910016, 0, 268435456, 1, 0, 21, 0, 1, 1, 6, 0, 0, 1, 0, 0, 0, 0, 0, 31, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
2208, 'Plainsrunning', '', 'Movement speed increased by $s1%.', 0, 0, 1, 1),
(910017, 65552, 0, 1, 180000, 32, 0, 1, 1, 6, 0, 0, 1, 0, 0, 9, 0, 0, 226, 0, 0, 1200, 0, 0, 1, 0, 0, 0, 0, 0,
0, 149, 'Rapid Regeneration', CONCAT('Regenerate 50% of your maximum Health over 6 sec. Any movement, action, or ',
'damage taken will cancel the effect.'), 'Regenerating 50% of maximum Health over 6 sec.', 0, 0, 1, 1),
(910018, 80, 0, 1, 0, 21, 0, 1, 1, 6, 0, 0, 1, 0, 0, 5, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
0, 76, 'Touch of the Grave', CONCAT('Your spells and attacks have a 5% chance to drain Health from the target, ',
'up to 5% of your maximum Health. This effect has a 1 sec cooldown.'),
'', 0, 0, 0, 1),
(910019, 80, 0, 1, 0, 21, 0, 1, 1, 6, 0, 0, 1, 0, 0, 5, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
0, 76, 'Touch of the Grave', CONCAT('Your spells and attacks have a 10% chance to drain Health from the target, ',
'up to 5% of your maximum Health. This effect has a 1 sec cooldown.'),
'', 0, 0, 0, 1),
(910020, 80, 0, 1, 0, 21, 0, 1, 1, 6, 0, 0, 1, 0, 0, 4, 0, 0, 168, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0,
0, 346, 'Big Game Hunter', 'Damage dealt versus Beasts increased by 5%.', '', 0, 0, 0, 1),
(910021, 80, 0, 1, 0, 21, 0, 1, 1, 6, 0, 0, 1, 0, 0, -1, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
0, 1663, 'Mace Specialization', CONCAT('Increases your critical strike chance with all spells and attacks by 1% ',
'while you have a mace or two-handed mace equipped.'), '', 0, 0, 0, 1),
(910022, 0, 0, 1, 0, 31, 0, 1, 1, 6, 0, 0, 1, 0, 0, -11, 0, 0, 87, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0,
0, 93, 'Stoneform', '', 'Physical damage taken reduced by 10%.', 0, 0, 0, 32),
(910023, 80, 0, 1, 0, 21, 0, 1, 1, 6, 0, 0, 1, 0, 0, 4, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
0, 1654, 'Expansive Mind', 'Maximum Rage increased by 5%.', '', 0, 0, 0, 1),
(910024, 80, 0, 1, 0, 21, 0, 1, 1, 6, 0, 0, 1, 0, 0, 4, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
0, 1654, 'Expansive Mind', 'Maximum Energy increased by 5%.', '', 0, 0, 0, 1),
(910025, 16, 0, 1, 120000, 8, 0, 1, 1, 6, 6, 6, 1, 1, 1, -21, 9, 9, 72, 79, 136, 0, 0, 0, 1, 1, 1,
127, 127, 127, 0, 517, 'Eureka!', CONCAT('Your next 3 damaging abilities have their Energy cost reduced by 20% ',
'and deal 10% more damage.'), 'Next damaging abilities cost 20% less Energy and deal 10% more damage.', 0, 0, 1, 8),
(910026, 16, 0, 1, 120000, 8, 0, 1, 1, 6, 6, 6, 1, 1, 1, -41, 9, 9, 72, 79, 136, 0, 0, 0, 1, 1, 1,
127, 127, 127, 0, 1321, 'Eureka!', CONCAT('Your next 3 damaging abilities have their Rage cost reduced by 40% ',
'and deal 10% more damage.'), 'Next damaging abilities cost 40% less Rage and deal 10% more damage.', 0, 0, 1, 8),
(910027, 16, 0, 1, 120000, 8, 0, 1, 1, 6, 6, 6, 1, 1, 1, -51, 9, 9, 72, 79, 136, 0, 0, 0, 1, 1, 1,
127, 127, 127, 0, 144, 'Eureka!', CONCAT('Your next 3 damaging abilities have their Mana cost reduced by 50% ',
'and deal 10% more damage.'), 'Next damaging abilities cost 50% less Mana and deal 10% more damage.', 0, 0, 1, 8),
(910028, 16, 0, 1, 120000, 8, 0, 1, 1, 6, 6, 6, 1, 1, 1, -16, 9, 9, 72, 79, 136, 0, 0, 0, 1, 1, 1,
127, 127, 127, 0, 1352, 'Eureka!', CONCAT('Your next 3 damaging or healing abilities have their Mana cost ',
'reduced by 15% and deal 10% more damage or healing.'), CONCAT('Next damaging or healing abilities cost 15% ',
'less Mana and deal 10% more damage or healing.'), 0, 0, 1, 8),
(910029, 16, 163840, 1, 180000, 0, 0, 1, 1, 108, 0, 0, 1, 0, 0, 99, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
12, 0, 0, 0, 71, 'Will to Survive', 'Instantly removes all Stun effects.', '', 133, 1500, 1, 1),
(910031, 16, 0, 1, 180000, 8, 0, 1, 1, 6, 0, 0, 1, 0, 0, 9, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 0,
0, 0, 0, 0, 1352, 'Elune''s Light', CONCAT('Increases your critical strike chance with all spells and attacks ',
'by 10% for 15 sec.'), 'Critical strike chance with all spells and attacks increased by 10%.', 0, 0, 1, 1),
(910032, 0, 0, 1, 0, 21, 0, 1, 1, 6, 0, 0, 1, 0, 0, 74, 0, 0, 31, 0, 0, 0, 0, 0, 1, 0, 0,
0, 0, 0, 0, 122, 'Wisp Spirit', '', 'Movement speed increased by 75%.', 0, 0, 0, 32),
(910033, 16, 0, 1, 120000, 0, 0, 1, 1, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
0, 0, 0, 910034, 79, 'Walk on Air', 'Glide downward through the air for 10 sec.', '', 133, 1500, 1, 8),
(910034, 0, 0, 1, 0, 1, 0, 1, 1, 6, 0, 0, 1, 0, 0, 0, 0, 0, 105, 0, 0, 0, 0, 0, 1, 0, 0,
0, 0, 0, 0, 79, 'Walk on Air', '', 'Walking on air.', 0, 0, 1, 8),
(910035, 80, 0, 1, 0, 21, 0, 1, 1, 6, 6, 6, 1, 1, 1, 0, 0, 0, 138, 140, 216, 0, 0, 0, 1, 1, 1,
0, 0, 0, 0, 136, 'Wind Blessed', 'Increases your spellcasting, melee, and ranged Haste by 1%.', '', 0, 0, 0, 8);

UPDATE `spell_dbc` SET `EquippedItemClass` = -1, `EquippedItemSubclass` = 0, `EquippedItemInvTypes` = 0
WHERE `ID` IN (20554, 910001, 910002, 910013, 910016, 910017, 910018, 910019, 910020, 910021, 910022,
910023, 910024, 910025, 910026, 910027, 910028, 910029, 910031, 910032, 910033, 910034, 910035);

UPDATE `spell_dbc` SET `SpellVisualID_1` = 9750 WHERE `ID` = 910002;
UPDATE `spell_dbc` SET `SpellVisualID_1` = 6768 WHERE `ID` = 910034;
UPDATE `spell_dbc` SET `ProcChance` = 5 WHERE `ID` = 910018;
UPDATE `spell_dbc` SET `ProcChance` = 10 WHERE `ID` = 910019;

DELETE FROM `playercreateinfo_spell_custom` WHERE `Spell` BETWEEN 910001 AND 910035;
DELETE FROM `playercreateinfo_spell_custom` WHERE `Spell` IN (20554, 20580, 26290, 58984, 59752);
INSERT INTO `playercreateinfo_spell_custom` (`racemask`, `classmask`, `Spell`, `Note`) VALUES
(2, 1535, 910001, 'WoW Forever - Shatter Curse'),
(32, 1535, 910013, 'WoW Forever - Plainsrunning'),
(128, 1535, 20554, 'WoW Forever - Berserking'),
(128, 1535, 910017, 'WoW Forever - Rapid Regeneration'),
(16, 11, 910018, 'WoW Forever - Touch of the Grave'),
(16, 400, 910019, 'WoW Forever - Touch of the Grave'),
(4, 1535, 910020, 'WoW Forever - Big Game Hunter'),
(4, 1535, 910021, 'WoW Forever - Mace Specialization'),
(64, 1, 910023, 'WoW Forever - Expansive Mind'),
(64, 8, 910024, 'WoW Forever - Expansive Mind'),
(64, 8, 910025, 'WoW Forever - Eureka!'),
(64, 1, 910026, 'WoW Forever - Eureka!'),
(64, 256, 910027, 'WoW Forever - Eureka!'),
(64, 16, 910028, 'WoW Forever - Eureka!'),
(1, 1535, 910029, 'WoW Forever - Will to Survive'),
(8, 1535, 20580, 'WoW Forever - Shadowmeld'),
(8, 1535, 910031, 'WoW Forever - Elune''s Light'),
(512, 1535, 910033, 'WoW Forever - Walk on Air'),
(512, 1535, 910035, 'WoW Forever - Wind Blessed'),
(1024, 1535, 910033, 'WoW Forever - Walk on Air'),
(1024, 1535, 910035, 'WoW Forever - Wind Blessed');

DELETE FROM `skilllineability_dbc` WHERE `ID` BETWEEN 910001 AND 910037;
DELETE FROM `skilllineability_dbc` WHERE `ID` IN (1259799, 1259800);
DELETE FROM `skilllineability_dbc` WHERE `ID` IN (13418, 26290) OR `Spell` IN (20554, 26290);
DELETE FROM `skilllineability_dbc` WHERE `RaceMask` = 16 AND `Spell` IN (20579, 17737);
DELETE FROM `skilllineability_dbc` WHERE `RaceMask` = 4 AND `Spell` IN (20595, 20596, 59224);
DELETE FROM `skilllineability_dbc` WHERE `RaceMask` = 64 AND `Spell` = 20592;
DELETE FROM `skilllineability_dbc` WHERE `RaceMask` = 1 AND `Spell` IN (20599, 20864, 58985, 59752);
DELETE FROM `skilllineability_dbc` WHERE `RaceMask` = 8 AND `Spell` IN (20583, 58984, 21009);
INSERT INTO `skilllineability_dbc` (`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`,
`ExcludeClass`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`,
`TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(910001, 125, 910001, 2, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910013, 124, 910013, 32, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(13418, 733, 20554, 128, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910017, 733, 910017, 128, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910018, 220, 910018, 16, 11, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910019, 220, 910019, 16, 400, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910020, 101, 910020, 4, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910021, 101, 910021, 4, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910023, 753, 910023, 64, 1, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910024, 753, 910024, 64, 8, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910025, 753, 910025, 64, 8, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910026, 753, 910026, 64, 1, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910027, 753, 910027, 64, 256, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910028, 753, 910028, 64, 16, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910030, 754, 20600, 1, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910029, 754, 910029, 1, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(1259800, 126, 20580, 8, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(1259799, 126, 910031, 8, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910033, 756, 910033, 512, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910035, 756, 910035, 512, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910036, 760, 910033, 1024, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0),
(910037, 760, 910035, 1024, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0);
UPDATE `skilllineability_dbc` SET `ClassMask` = 400 WHERE `RaceMask` = 64 AND `Spell` = 20591;

DELETE FROM `playercreateinfo_action` WHERE `action` BETWEEN 910001 AND 910035;
DELETE FROM `playercreateinfo_action` WHERE `action` = 20552;
DELETE FROM `playercreateinfo_action` WHERE `action` IN (20554, 20580, 26290, 58984);
DELETE FROM `playercreateinfo_action` WHERE `race` = 1 AND `action` IN (20600, 59752);
INSERT INTO `playercreateinfo_action` (`race`, `class`, `button`, `action`, `type`) VALUES
(2, 1, 75, 910001, 0), (2, 3, 75, 910001, 0), (2, 4, 75, 910001, 0), (2, 6, 75, 910001, 0),
(2, 7, 75, 910001, 0), (2, 8, 75, 910001, 0), (2, 9, 75, 910001, 0),
(6, 1, 75, 20552, 0), (6, 3, 75, 20552, 0), (6, 7, 75, 20552, 0), (6, 11, 75, 20552, 0),
(8, 1, 75, 20554, 0), (8, 3, 75, 20554, 0), (8, 4, 75, 20554, 0), (8, 5, 75, 20554, 0),
(8, 7, 75, 20554, 0), (8, 8, 75, 20554, 0), (8, 9, 75, 20554, 0),
(8, 1, 76, 910017, 0), (8, 3, 76, 910017, 0), (8, 4, 76, 910017, 0), (8, 5, 76, 910017, 0),
(8, 7, 76, 910017, 0), (8, 8, 76, 910017, 0), (8, 9, 76, 910017, 0),
(7, 1, 75, 910026, 0), (7, 4, 75, 910025, 0), (7, 5, 75, 910028, 0), (7, 9, 75, 910027, 0),
(1, 1, 75, 20600, 0), (1, 2, 75, 20600, 0), (1, 4, 75, 20600, 0), (1, 5, 75, 20600, 0),
(1, 8, 75, 20600, 0), (1, 9, 75, 20600, 0),
(1, 1, 76, 910029, 0), (1, 2, 76, 910029, 0), (1, 4, 76, 910029, 0), (1, 5, 76, 910029, 0),
(1, 8, 76, 910029, 0), (1, 9, 76, 910029, 0),
(4, 1, 75, 20580, 0), (4, 3, 75, 20580, 0), (4, 4, 75, 20580, 0), (4, 5, 75, 20580, 0),
(4, 11, 75, 20580, 0),
(4, 1, 76, 910031, 0), (4, 3, 76, 910031, 0), (4, 4, 76, 910031, 0), (4, 5, 76, 910031, 0),
(4, 11, 76, 910031, 0),
(10, 2, 75, 910033, 0), (10, 3, 75, 910033, 0), (10, 4, 75, 910033, 0), (10, 5, 75, 910033, 0),
(10, 6, 75, 910033, 0), (10, 8, 75, 910033, 0), (10, 9, 75, 910033, 0),
(11, 1, 75, 910033, 0), (11, 2, 75, 910033, 0), (11, 3, 75, 910033, 0), (11, 5, 75, 910033, 0),
(11, 6, 75, 910033, 0), (11, 7, 75, 910033, 0), (11, 8, 75, 910033, 0);

DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 20580;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(20580, 59646, 0, 'Shadowmeld: Sanctuary'),
(20580, 62196, 0, 'Shadowmeld: Force deselect');

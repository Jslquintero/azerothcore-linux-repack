-- Restore native Cannibalize behavior and visual, adding only periodic mana regeneration.
DELETE FROM `spell_dbc` WHERE `ID` IN (20577, 20578);
INSERT INTO `spell_dbc`
(`ID`, `AttributesEx`, `CastingTimeIndex`, `ChannelInterruptFlags`, `ProcChance`, `DurationIndex`,
`RangeIndex`, `EquippedItemClass`, `Effect_1`, `Effect_2`, `EffectDieSides_1`, `EffectDieSides_2`,
`EffectBasePoints_1`, `EffectBasePoints_2`, `ImplicitTargetA_1`, `ImplicitTargetA_2`,
`EffectAura_1`, `EffectAura_2`, `EffectAuraPeriod_1`, `EffectAuraPeriod_2`, `SpellVisualID_1`, `SpellIconID`,
`Name_Lang_enUS`, `AuraDescription_Lang_enUS`, `SchoolMask`, `EffectChainAmplitude_1`, `EffectChainAmplitude_2`,
`EffectBonusMultiplier_2`, `EffectBonusMultiplier_3`) VALUES
(20578, 536870976, 1, 15374, 101, 1, 1, -1, 6, 6, 1, 1, 6, 6, 1, 1, 20, 21, 2000, 2000, 5724, 146,
'Cannibalize', 'Regenerating 7% of total Health and Mana every 2 sec.', 1, 1, 1, 1, 1);

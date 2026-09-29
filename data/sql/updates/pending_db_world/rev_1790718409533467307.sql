-- WoW Forever: update the Blood Elf and Draenei racial spell icons and clear Walk on Air costs.

UPDATE `spell_dbc` SET `ManaCost` = 0, `ManaCostPerLevel` = 0, `ManaPerSecond` = 0, `ManaPerSecondPerLevel` = 0,
    `Totem_1` = 0, `Totem_2` = 0,
    `Reagent_1` = 0, `Reagent_2` = 0, `Reagent_3` = 0, `Reagent_4` = 0,
    `Reagent_5` = 0, `Reagent_6` = 0, `Reagent_7` = 0, `Reagent_8` = 0,
    `ReagentCount_1` = 0, `ReagentCount_2` = 0, `ReagentCount_3` = 0, `ReagentCount_4` = 0,
    `ReagentCount_5` = 0, `ReagentCount_6` = 0, `ReagentCount_7` = 0, `ReagentCount_8` = 0
WHERE `ID` = 910033;

UPDATE `spell_dbc` SET `SpellIconID` = 220 WHERE `ID` IN (910033, 910034);
UPDATE `spell_dbc` SET `SpellIconID` = 174 WHERE `ID` = 910035;

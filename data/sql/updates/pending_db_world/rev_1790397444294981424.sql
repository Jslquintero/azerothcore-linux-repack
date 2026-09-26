--
-- Healing Touch particles with a dedicated channel loop in the matching client DBC patch.
UPDATE `spell_dbc` SET `SpellVisualID_1` = 910017, `SpellVisualID_2` = 0 WHERE `ID` = 910017;

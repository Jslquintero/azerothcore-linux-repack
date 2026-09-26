--
-- Replace Renew with Healing Touch for Rapid Regeneration on existing installations.
UPDATE `spell_dbc` SET `SpellVisualID_1` = 58, `SpellVisualID_2` = 0 WHERE `ID` = 910017;

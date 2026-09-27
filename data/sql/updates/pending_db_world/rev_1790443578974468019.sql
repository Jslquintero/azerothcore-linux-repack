-- Restore Shadowmeld's stock interruption flags, matching the existing client Spell.dbc.
-- AuraInterruptFlags includes movement (0x8) and the normal attack/cast/mount interruptions.
-- Keep the conditional 10/120-second cooldown and cooldown-on-aura-expiry attribute unchanged.
UPDATE `spell_dbc` SET `InterruptFlags` = 9, `AuraInterruptFlags` = 146444 WHERE `ID` = 20580;

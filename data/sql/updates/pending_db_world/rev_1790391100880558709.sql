-- Cultivation copies need a valid opening lock: Spell::CheckCast rejects LockId 0.
-- Lock.dbc 57 permits ordinary opening (LOCKTYPE_OPEN), with no profession or key required.
UPDATE `gameobject_template` SET `Data0` = 57
WHERE `entry` BETWEEN 1000000 AND 1999999 AND `type` = 3 AND `castBarCaption` = 'Cultivation';

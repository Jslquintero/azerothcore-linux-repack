# mod-class-paladin-sacred-flame

Adds the custom Paladin passive `Sacred Flame`.

## Spell IDs

- `900001` - Sacred Flame passive, learned from the custom quest.
- `900002` - Sacred Flame Holy damage pulse used by the module.

## Quest IDs

- `900001` - Alliance quest from Lord Grayson Shadowbreaker.
- `900003` - Horde quest from Champion Vranesh, sending the player to Deatholme in Ghostlands.

## Gameplay

- Ticks every 2 seconds.
- Hits hostile attackable units within 4 yards.
- Melee hits grant 1 stack for 5 seconds.
- Stacks up to 3 times.
- Each stack increases the pulse damage by 5%.
- Damage is intentionally low: level, attack power, and spell power have small coefficients.

## DBC/client note

The world SQL adds `spell_dbc` and `skilllineability_dbc` rows for server-side loading.
For players to see the spell cleanly in the spellbook/client, export the matching DBC rows
into the client patch as well.

The damage pulse uses `SpellVisualID_1 = 29512` as a short Holy-themed impact. Keep the
passive row visual-free so it does not create constant ambient effects around the player.

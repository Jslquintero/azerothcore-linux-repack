# Custom Active Racials With Timed Auras

This guide describes how to add a custom racial ability that has an instant cast, a cooldown, a visible timed
buff, gameplay effects, and persistent character VFX in a WoW 3.3.5a client. Shatter Curse is the reference
implementation:

- Spell `910001` is the learned active ability and owns the 3-minute cooldown.
- Spell `910002` is an internal 8-second aura and owns the gameplay effects, buff icon, countdown, and VFX.

The current SQL implementation is in
`data/sql/updates/pending_db_world/rev_1789419368200754390.sql`. The generated client records are in
`client-patches/DBFilesClient/Spell.dbc` and `client-patches/DBFilesClient/SkillLineAbility.dbc`.

## Why Use Two Spells

Use a native trigger-and-aura pair for active racials with timed effects:

1. The active spell is placed in the spellbook/action bar, starts the cooldown, and triggers the helper spell.
2. The helper spell is a normal timed aura sent to the client with its own icon, duration, effects, and visual.

This separates two different lifetimes. The ability button has a long cooldown, while the buff has a short
duration. It also avoids a C++ script for effects that the spell system already supports.

Do not teach the helper spell to the player, add it to `SkillLineAbility.dbc`, or place it on the action bar.

## Server Spell Records

Create both records in `spell_dbc` through an idempotent pending world SQL update. Delete the custom IDs before
inserting them, as required by the repository SQL conventions.

### Active Spell

The learned spell should have:

- `RecoveryTime`: the racial cooldown in milliseconds.
- `CastingTimeIndex = 1`: instant cast.
- `RangeIndex = 1`: self range.
- `Effect_1 = 64`: `SPELL_EFFECT_TRIGGER_SPELL`.
- `ImplicitTargetA_1 = 1`: caster/self.
- `EffectTriggerSpell_1`: the helper aura spell ID.
- `DurationIndex = 0`: the active spell is not the timed aura.
- `SpellIconID`: the racial's action-bar icon.
- No aura effects and normally no visual. The triggered aura owns those fields.

For Shatter Curse, spell `910001` triggers spell `910002` and has `RecoveryTime = 180000`.

### Helper Aura

The helper spell should have:

- `RecoveryTime = 0`: never give the internal aura its own cooldown.
- A verified `DurationIndex` for the desired duration.
- `Effect_N = 6`: `SPELL_EFFECT_APPLY_AURA` for each aura effect.
- `ImplicitTargetA_N = 1`: apply each effect to the caster.
- `SpellIconID`: the icon displayed in the buff bar.
- `SpellVisualID_1`: a visual known to remain attached for a timed aura.
- `Attributes` without `SPELL_ATTR0_PASSIVE` or `SPELL_ATTR0_DO_NOT_DISPLAY`.
- `AttributesEx` without `SPELL_ATTR1_NO_AURA_ICON`.

Shatter Curse uses these effects on `910002`:

| Field | Value | Meaning |
| --- | ---: | --- |
| `DurationIndex` | `31` | 8,000 ms in this client's `SpellDuration.dbc` |
| `Effect_1` | `6` | Apply aura |
| `EffectAura_1` | `87` | Modify damage percent taken |
| `EffectBasePoints_1` | `-16` | 15% damage reduction after DBC base-point evaluation |
| `EffectMiscValue_1` | `126` | All magical school bits, excluding physical |
| `Effect_2` | `6` | Apply aura |
| `EffectAura_2` | `41` | Dispel-type immunity |
| `EffectBasePoints_2` | `-1` | Immunity aura amount used by the client/core |
| `EffectMiscValue_2` | `2` | `DISPEL_CURSE` |
| `AttributesEx` | `32768` | Purge matching existing auras when immunity is applied |
| `SpellVisualID_1` | `9750` | Persistent Nether Protection-style magic ward |
| `SpellIconID` | `542` | Shatter Curse buff icon |

WoW DBC base points use an internal `value - 1` convention for many effects. Verify the evaluated result in the
core instead of assuming the raw value is the displayed percentage.

## Verify Durations From Data

Never infer a duration from the name or tooltip of another spell. `DurationIndex` is a foreign key into
`SpellDuration.dbc`; it is not a duration in seconds.

For example, in the current 3.3.5a data:

- Duration index `31` is 8,000 ms.
- Duration index `407` is 100 ms.

Using `407` made the Shatter Curse aura appear for a fraction of a second. Inspect the actual DBC record and
verify its `Duration`, `DurationPerLevel`, and `MaxDuration` values before using an index. The server and client
must use compatible `SpellDuration.dbc` data.

## Choose Persistent VFX

`SpellVisualID_1` does not guarantee a visual for the full aura duration. Some spell visuals contain only an
application or impact burst. Copying one of those produces a correct buff icon but no sustained character VFX.

Choose a visual from an existing spell that:

- Is itself a timed aura, not an instant cast or impact spell.
- Keeps a visible attachment on the character for its full duration.
- Fits the racial's theme without borrowing an unwanted class identity.
- Is available in the target 3.3.5a client.

Shatter Curse first used Shadow Ward visual `343`, but that visual only produced a short application effect in
this client. It now uses visual `9750`, taken from Nether Protection's 8-second magical protection auras.

Put the persistent visual on the helper aura. Test the helper directly with `.aura <helper spell ID>` before
testing the active spell and cooldown.

## Client DBC Requirements

Server SQL does not update the WoW client. Generate matching client records and package them into the custom MPQ:

- `Spell.dbc` must contain both the active and helper spell records.
- `SkillLineAbility.dbc` should expose only the learned active spell for the racial skill line.
- The active record must trigger the same helper ID used by the server.
- The helper record must contain the same duration index, icon, and visual used by the server.

After rebuilding the MPQ, fully close and restart the WoW client. DBC files are loaded at client startup. Check
MPQ load order if the spellbook tooltip or aura behavior still reflects an older record.

## Learning And Action Bars

Add only the active spell to server-side racial learning data:

- `playercreateinfo_spell_custom` teaches it to the intended race/class masks.
- `playercreateinfo_action` can place it on new characters' action bars.
- `skilllineability_dbc` and client `SkillLineAbility.dbc` expose it in the racial skill line.

Existing characters may need the active spell taught manually or refreshed according to the project's racial
migration process. The helper must remain internal.

## When C++ Is Needed

Prefer native spell effects for triggering, timed auras, standard immunities, dispels, and damage modifiers. Add
a `SpellScript` or `AuraScript` only when the behavior cannot be represented by DBC effects.

Examples that may require C++ include custom Bane classification, conditional stat calculations, equipment-based
logic, or effects that scale from runtime state. Register the script in `spell_script_names`, add it to the script
loader, and rebuild the server. A source edit alone does not alter an already built worldserver.

WoW 3.3.5a has `DISPEL_CURSE` but no native `DISPEL_BANE` category. A project-specific Bane system therefore needs
an explicit definition and custom removal/immunity handling.

## Apply And Test

1. Apply the pending world SQL update.
2. Restart worldserver so `spell_dbc` is reloaded.
3. Package the generated DBC files into the custom MPQ.
4. Fully restart the WoW client.
5. Run `.aura <helper spell ID>` and verify the icon, tooltip, countdown, effects, and persistent VFX.
6. Remove the test aura, clear the active cooldown if necessary, and cast the learned racial.
7. Apply a matching debuff before casting and verify both removal and immunity during the full aura duration.
8. Confirm the mitigation with controlled magical damage, not only with tooltip text.

For Shatter Curse, `.aura 910002` should show an 8-second buff using icon `542` and visual `9750`.

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| Aura flashes and disappears | The duration index maps to a very short duration; inspect `SpellDuration.dbc`. |
| Aura appears without a countdown | No positive max duration, or `SPELL_ATTR5_DO_NOT_DISPLAY_DURATION` is set. |
| Gameplay works but no buff icon appears | The client helper is missing, hidden, or overridden by an older MPQ. |
| Buff icon counts down but VFX ends immediately | The visual is application-only; use a persistent aura visual. |
| Cooldown starts but no buff appears | The trigger, target, or helper records are missing or mismatched. |
| Tooltip differs from behavior | Server and client spell records are out of sync. |
| Native SQL changes work but scripted behavior does not | The C++ script was not registered, built, or deployed. |

Treat server behavior, client presentation, and MPQ delivery as one feature. A custom racial is not complete until
all three are verified together.

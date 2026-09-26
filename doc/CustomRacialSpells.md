# Custom Racial Spells

This guide describes how to add a custom racial ability that has an instant cast, a cooldown, a visible timed
buff, gameplay effects, and persistent character VFX in a WoW 3.3.5a client. Shatter Curse is the reference
implementation for timed active racials:

- Spell `910001` is the learned active ability and owns the 3-minute cooldown.
- Spell `910002` is an internal 8-second aura and owns the gameplay effects, buff icon, countdown, and VFX.

The current SQL implementation is in
`data/sql/updates/pending_db_world/rev_1789419368200754390.sql`. The generated client records are in
`client-patches/DBFilesClient/Spell.dbc` and `client-patches/DBFilesClient/SkillLineAbility.dbc`.

This guide also covers stacking passive racials (Plainsrunning) and scripted gathering abilities (Cultivation).
Their C++ implementation is in `src/server/scripts/Spells/spell_racial.cpp`; client records are maintained by
`client-patches/generate_racial_dbc.py`.

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

### Rapid Regeneration Channel Visual

Rapid Regeneration (`910017`) uses custom visual `910017`, cloned from Healing Touch visual `58`.
Healing Touch has no channel kit, so assigning visual `58` alone only plays its one-shot cast animation.
The custom visual clears `CastKit` and assigns `ChannelKit = 910017`. That kit clones Healing Touch's
precast kit `100`, retaining the nature particles on both hands, with animation `125` (`ChannelCastOmni`).
It does not borrow Tranquility's area impact effect or change the original Healing Touch spell.

`generate_racial_dbc.py` also updates `SpellVisual.dbc` (32 fields) and `SpellVisualKit.dbc` (38 fields)
using the 3.3.5a layouts. Include both files in the MPQ alongside `Spell.dbc` and `SkillLineAbility.dbc`.
Deploy the matching `SpellVisual.dbc` to the server DBC directory before restarting worldserver.
Apply `rev_1790397444294981424.sql` after the earlier Rapid Regeneration updates.
Verify the channel animation for all six seconds and that movement or damage stops it immediately.

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

## Replacing A Stock Racial: Perception

Human Perception uses active spell `20600`: 20 seconds (verified duration index `18`), a 180-second cooldown,
and +51 stealth detection (`EffectBasePoints_1 = 50`, `EffectDieSides_1 = 1`). The server override is inserted
by `rev_1790398432174993360.sql`; an UPDATE alone cannot override a spell absent from `spell_dbc`.

The stock server `SkillLineAbility.dbc` teaches passive Perception (`58985`) through record `20114`.
Deleting that row from SQL does not remove the underlying DBC record. Override **the same ID**, `20114`,
to teach `20600`, and remove the redundant custom SQL record `910030`. The client generator uses `20114`
as well. Humans learn the active on creation and when their racial skill is loaded at login.

Human Diplomacy (`20599`), Mace Specialization (`20864`), and stock Will to Survive (`59752`) have the
same fallback behavior. `rev_1790399673855342353.sql` overrides their original learning records (`11728`,
`11861`, `20205`) with `AcquireMethod = 0` to disable automatic learning. Keep custom Will to Survive
(`910029`) enabled. The client generator already excludes the three stock abilities from its racial skill
line. The companion character migration `rev_1790399673916166607.sql` removes any explicitly saved copies,
auras, and spell action buttons from humans; skill-granted spells are relearned from the corrected data at login.

## When C++ Is Needed

Prefer native spell effects for triggering, timed auras, standard immunities, dispels, and damage modifiers. Add
a `SpellScript` or `AuraScript` only when the behavior cannot be represented by DBC effects.

Examples that may require C++ include custom Bane classification, conditional stat calculations, equipment-based
logic, or effects that scale from runtime state. Register the script in `spell_script_names`, add it to the script
loader, and rebuild the server. A source edit alone does not alter an already built worldserver.

WoW 3.3.5a has `DISPEL_CURSE` but no native `DISPEL_BANE` category. A project-specific Bane system therefore needs
an explicit definition and custom removal/immunity handling.

## Stacking Movement Racials: Plainsrunning

Separate the learned passive spell (`910013`) from the visible movement aura (`910016`). The passive grants
access to the behavior; the internal aura carries the speed bonus and its client presentation. Teach only the
passive spell and expose only that spell through `SkillLineAbility.dbc`.

Represent each 1% increase as one stack. The server and client helper records must agree:

| Server `spell_dbc` field | Value | Purpose |
| --- | ---: | --- |
| `Attributes` | `0` | The helper is visible and is not passive. |
| `AttributesEx` | `0` | Clear `SPELL_ATTR1_NO_AURA_ICON` (`0x10000000`). |
| `DurationIndex` | `21` | Indefinite aura; the script manages its lifetime. |
| `CumulativeAura` | `30` | Maximum stack count; called `StackAmount` in C++ and DBC field 49. |
| `Effect_1` | `6` | Apply aura. |
| `EffectAura_1` | `31` | `SPELL_AURA_MOD_INCREASE_SPEED`. |
| `EffectDieSides_1` | `1` | Adds one to the raw base points. |
| `EffectBasePoints_1` | `0` | Evaluates to 1% per stack. |
| `ImplicitTargetA_1` | `1` | Apply to self. |
| `SpellIconID` | `2208` | Plainsrunning icon. |

Set `AuraDescription_Lang_enUS` and the client aura description to `Movement speed increased by $s1%.`.
Use the effect placeholder for the calculated bonus; a literal `1% per stack` does not display the current total.

Maintain the aura and change its stack count instead of removing it and casting a custom amount every tick:

```cpp
if (!bonus)
{
    player->RemoveAura(SPELL_WF_PLAINSRUNNING_SPEED);
    return;
}

Aura* aura = player->GetAura(SPELL_WF_PLAINSRUNNING_SPEED);
if (!aura)
    aura = player->AddAura(SPELL_WF_PLAINSRUNNING_SPEED, player);

if (aura && aura->GetStackAmount() != bonus)
    aura->SetStackAmount(bonus);
```

`SetStackAmount` recalculates the aura effects and schedules a client update. Keep `bonus` within 0–30.
Do not subtract one when passing an evaluated amount to `CastCustomSpell`: its spell-value setter already
converts the amount to raw base points. Confusing these representations previously made the first bonus zero.

The current controller gains one stack every five seconds of eligible movement, caps at 30, and reduces stacks
when standing still or taking damage. Keep eligibility checks, gain, decay, and aura removal consistent. Test
running, stopping, damage, mounting, swimming, death, and relogging. Check both the displayed percentage and
actual movement speed; another movement modifier can affect the final speed under the core's stacking rules.

## Gathering Racials: Cultivation

Cultivation (`20552`) replaces a stock passive with an active dummy spell. A stock spell may exist only in
`Spell.dbc`, with no row in `spell_dbc`. An `UPDATE` against a missing row silently changes nothing. Use an
idempotent `DELETE`/`INSERT` override and verify that the row exists after applying the migration.

The active record needs `Attributes = 16`, `AttributesEx = 0`, instant casting, self targeting,
`Effect_1 = 3` (`SPELL_EFFECT_DUMMY`), and no passive aura effects. Mirror this in the client DBC. Bind
`spell_wf_racial_cultivation` in `spell_script_names`, and register its `OnEffectHitTarget` handler for
`EFFECT_0` and `SPELL_EFFECT_DUMMY`. A log message saying the handler does not match the DBC effect means
that the server is still loading the wrong spell definition; the clone handler will not run.

### Find And Duplicate A Herb

Search within five yards for a chest whose `Lock.dbc` requirements identify Herbalism. Require a spawned,
ready, unowned object within line of sight, and reject an already cultivated source. Mark the source as used
only after successfully creating the duplicate. The current implementation tracks source GUIDs in memory;
this restriction is not persisted across server restarts.

Summoning the original entry preserves its Herbalism requirement. Instead, create dedicated templates using
`original entry + 1000000`, after checking for entry collisions. Preserve the source name, display ID, size,
and `Data1` loot-table ID. Configure each duplicate as follows:

| Template field | Value | Purpose |
| --- | ---: | --- |
| `type` | `3` | Chest with ordinary loot handling. |
| `Data0` | `57` | Standard opening lock from this client's `Lock.dbc`; no profession or key required. |
| `Data1` | Source value | Reuse the original herb's loot table. |
| `Data3` | `1` | Consume the clone after looting. |
| `Data4`, `Data5` | `1` | Single-use opening values. |
| `castBarCaption` | `Cultivation` | Identify the custom templates for scoped updates. |

Do not copy source events, traps, or profession restrictions. Do not set `Data0 = 0` to bypass Herbalism:
`Spell::CheckCast` rejects an open-lock spell targeting a gameobject without a lock ID. That produces a
visible clone which cannot be harvested. Lock 57 provides the ordinary opening path without a gathering skill.
Verify the lock against the actual `Lock.dbc` before reusing this approach with different client data.

Summon the duplicate near the player using its custom entry. The `SummonGameObject` lifetime parameter is in
**seconds**: use `10 * MINUTE` for ten minutes, not a millisecond value. Use `getLootState()` with a lowercase
`g` when checking a gameobject; `GetLootState()` is not an AzerothCore method.

Test with a Tauren who has no Herbalism: cast near a herb, right-click the clone, collect its loot, and verify
that the original herb remains intact. Confirm that the source cannot be cultivated again and that the clone
cannot itself be cultivated. Test ordinary herbs with non-quest loot so quest eligibility does not mask results.

The implementation is split across these pending world updates; apply them in order:

1. `rev_1790306766218153738.sql`: active Cultivation override, clone templates, and stacking Plainsrunning aura.
2. `rev_1790391100880558709.sql`: standard opening lock for the Cultivation clones.

## Generate And Deploy All Parts

Regenerate the client data with:

```bash
python client-patches/generate_racial_dbc.py
```

Keep `*.dbc binary` in `.gitattributes`. Text newline conversion can corrupt record boundaries and string offsets.
Check the DBC header and file length, and verify the relevant spell records after generation and MPQ extraction.

Apply the SQL, deploy the compiled C++ changes when needed, and restart worldserver to reload spell and
object templates. Compilation alone does not replace an existing Docker container. After building the image,
activate it with the project's Compose configuration, for example:

```bash
docker compose up -d --no-deps --no-build ac-worldserver
```

Check that the running container uses the new image and that startup no longer reports script/effect mismatches.
Follow the repository's authorization rules before compiling, and coordinate restarts with connected players.

Package the generated DBC files into the installed custom MPQ and fully restart WoW. If an existing gameobject
entry changed, clear the client's `Cache` folder while WoW is closed so stale template data is not reused.
A prepared MPQ outside the client's `Data` directory does not update the installed client.

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

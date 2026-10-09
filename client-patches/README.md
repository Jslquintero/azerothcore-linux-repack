# Client patches

## Troll druid appearances

World update `rev_1791498378705496622.sql` assigns existing 3.3.5a creature displays to troll druids
through `player_shapeshift_model`. No client patch, DBC generation, or server rebuild is required.
Restart worldserver after applying the SQL to load the assignments.

| Form | Appearance | Display ID |
| --- | --- | --- |
| Cat | Orange Stranglethorn raptor | 788 |
| Tree of Life | Brown treant | 9590 |
| Travel | Stranglethorn tiger | 320 |
| Aquatic | River crocolisk | 1039 |
| Bear / Dire Bear | Black Amani bear with green armor | 22466 |
| Flight | Brown bat | 3956 |
| Swift Flight | Violet bat | 7894 |
| Moonkin | Arakkoa sage | 17573 |

These defaults apply to male and female trolls with any skin color. The Amani bear uses the existing
mount model, including its equipment, at display scale 1.25; it does not grant a mount or mounted state.
Abilities, form restrictions, and movement speeds continue to use the original shapeshift spells.

Display IDs, model paths, textures, and scales were checked against the server's DBCs. In-game visual
validation is still required: check attacks and stealth in Cat Form, swimming and land transitions in
Aquatic Form, takeoff and landing in both flight forms, and spell animations in Tree and Moonkin forms.
Also check bear size and camera placement. Creature displays can differ from player druid models in
their animation coverage and proportions.

## Night elf druid appearances

World update `rev_1791517698208788290.sql` assigns the existing Furbolg display 145 to both Bear and Dire
Bear forms for night elf druids. Customization 255 and gender 2 cover every customization and both genders.
The Furbolg model path is `Creature\\furbolg\\Furbolg.mdx`; no DBC, client patch, or sound change is needed.
Restart worldserver after applying the SQL. Check both bear forms in game for animation and camera fit.

World update `rev_1791518671201048363.sql` assigns Deer display 347 (`Creature\\Deer\\Deer.mdx`) to night
elf Travel Form, using the same all-customization and both-gender default. No client patch or sound change is
needed; restart worldserver after applying the SQL.

### Troll transformation sounds

`generate_troll_druid_sounds.py` creates two internal transformation variants and the feral presentation
aliases described below, while preserving every original record:

| Learned spell | Internal spell / visual / impact kit | Transformation sound |
| --- | --- | --- |
| Cat Form (768) | 910100 | RaptorAggro (708) |
| Aquatic Form (1066) | 910101 | BasiliskAggro (570), the crocolisk model's native sound |

The variants copy all spell fields, including names, costs, family masks, and effects. Only their IDs and
visual references differ. Each copied visual replaces only its impact kit, and that kit changes only its
sound. Other races and the shared original sound records are unaffected.

`SpellMgr::GetRacialShapeshiftSpell` selects these variants for troll druid casts, including bot casts.
Players continue to learn and cast the original spells through existing trainers, macros, and action bars.
The cancel-aura handler accepts the original form button or the variant aura, and playerbots recognize and
remove the variant forms. The server falls back to the original spell if its variant is absent from the DBC.
Do not teach the internal variants or add them to `SkillLineAbility.dbc`.

Generate from the current DBCs of each target, preserving any existing local customizations:

```bash
python3 -B client-patches/generate_troll_druid_sounds.py \
  --dbc-dir /path/to/current/DBFilesClient \
  --sound-entries /path/to/original/SoundEntries.dbc
```

Unlike the SQL appearance assignments above, sound routing requires rebuilding and deploying worldserver.
Install the generated `Spell.dbc` and `SpellVisual.dbc` in the server's configured DBC directory, and all three
generated files (`Spell.dbc`, `SpellVisual.dbc`, `SpellVisualKit.dbc`) in the client MPQ under `DBFilesClient/`.
The new spell definitions are loaded from the server DBC; no `spell_dbc` SQL overrides are needed.
Every client observing the forms needs the updated MPQ and a full client restart. Restart worldserver after
deploying the matching binary and DBCs. Installing only the client patch does not enable racial routing.

The local deployment artifacts are under `env/dist/client-patches/troll-druid-sounds/`: `patch-z.mpq`
matches the installed client, `published-patch-z.mpq` preserves the distribution archive's customizations,
and `server-dbc/` preserves the server's own source data. The compiled image and server DBCs were deployed,
the installed client's variants were verified, and the local distribution archive was updated. Checksums
are in `SHA256SUMS`; the previous server executable, DBCs, and client/distribution archives are in
`backup-before-deploy/`. The client, distribution patch, and server had different source DBCs, so replacing
them wholesale with the repository's copies would lose existing customizations.

Generation validates that every original record remains byte-identical and that each variant differs only
in its declared fields. The Docker build and server startup passed. In-game acceptance still needs testing:
test male/female trolls,
night elves and tauren as controls, mana costs, Furor, Natural Shapeshifter, aquatic glyph/speed, form-bar
toggles, `/cancelform`, aura cancellation, relogging in either form, nearby listeners, and bot form switching.
Also confirm the client accepts the variant cast response for the original action button without leaving
it locked or replaying the original impact sound.

### Troll feral ability sounds

The same generator adds presentation aliases for all 50 player ranks whose cast kits use `CatAttack`:

| Ability | Ranks | Original visual | Original cast kit |
| --- | --- | --- | --- |
| Claw | 8 | 3882 | 3370 |
| Rake | 7 | 750 | 269 |
| Shred | 9 | 3950 | 3373 |
| Ravage | 7 | 2275 | 2109 |
| Cower | 6 | 3883 | 3294 |
| Ferocious Bite | 8 | 6587 | 5891 |
| Mangle (Cat) | 5 | 8634 | 5890 |

Each presentation spell ID is `1000000 + original spell ID`; copied visuals and kits use the same offset
in their respective tables. Only the cast kit's sound changes, from CatAttack (4121) to RaptorAttack (704).
Animations, impact effects, and the three native raptor attack samples are retained. NPC abilities and
abilities without the feline sound are not cloned.

`SpellMgr::GetRacialCastVisualSpellId` selects the alias for a troll druid in Cat Form, using the original
rank chain and checking that the alias is loaded. `Spell` captures this ID at construction and uses it in
`SMSG_SPELL_START`, `SMSG_SPELL_GO`, and their visual interruption packets. The actual `m_spellInfo` stays
on the original combat spell: damage, energy, combo points, bleed auras, talents, glyphs, scripts, cooldowns,
cast errors, and combat logs use the original IDs. Client cast notifications may expose the presentation
alias; addons that track those notifications by numeric spell ID may need to normalize it. Do not teach
these aliases, add them to rank chains, or route gameplay casts through them.

Generate and install the same three DBCs described above and deploy the matching worldserver build.
The local feral deployment artifacts live in `env/dist/client-patches/troll-feral-sounds/`, with separate
client/distribution archives, `server-dbc/`, and `backup/` containing the previous files. The rollback image
is `acore/ac-wotlk-worldserver:before-feral-sounds`. All clients must fully restart to load the new DBCs.

Verify each ability in game, including low and maximum ranks, successful and failed casts, energy costs,
combo-point generation and consumption, Rake ticks, Mangle's debuff, glyph/talent procs, action-button
cooldowns, and nearby listeners. Compare a troll in raptor form with a night elf or tauren in Cat Form.
The generator checks every copied field and preserves the original records; runtime audio and UI behavior
still require these in-game checks.

## Leafre fishing rings

The server updates register these rings:

- Item `276765` uses display `31664` and icon `INV_Jewelry_Ring_38`.
- Item `274978` uses display `31657` and icon `INV_Jewelry_Ring_39`.
- Item `285326` uses display `31657` and icon `INV_Jewelry_Ring_39`.

Both icons exist in the standard 3.3.5a `ItemDisplayInfo.dbc`.

To recreate the client record from an original WoW 3.3.5a `Item.dbc`:

```bash
python client-patches/generate_leafre_ring_dbc.py --source /path/to/original/Item.dbc
```

Package `client-patches/DBFilesClient/Item.dbc` in the custom MPQ at `DBFilesClient/Item.dbc`, then fully
close and restart the WoW client so it loads the new record.

## Additional race/class combinations

`generate_race_class_dbc.py` adds the supported Retail and WoW: Forever combinations to
`CharBaseInfo.dbc` and adds male and female starting outfit records to `CharStartOutfit.dbc`.
It also extends `SkillRaceClassInfo.dbc` so Gnome Hunters can use their starting guns.
Provide original 3.3.5a source files; generated files are written to `DBFilesClient/` by default:

```bash
python client-patches/generate_race_class_dbc.py \
  --char-base-info /path/to/original/CharBaseInfo.dbc \
  --char-start-outfit /path/to/original/CharStartOutfit.dbc \
  --skill-race-class-info /path/to/original/SkillRaceClassInfo.dbc
```

Package all three generated files in the client MPQ under `DBFilesClient/`. The server must also load
the generated `CharStartOutfit.dbc` and `SkillRaceClassInfo.dbc` from its configured DBC directory.
Fully close and restart the WoW client after installing the MPQ. This covers only the ten playable
WotLK races and classes present in 3.3.5a; later races, Monk, Demon Hunter, and Evoker require additional
client and core support. The existing custom Undead Paladin combination is retained.

The world database updates must also be applied: `rev_20261005_000001.sql` enables character creation,
and `rev_1791250210630561681.sql` supplies the initial action bars for all eleven combinations.
Restart worldserver after applying them so it reloads the creation templates. Action bars are populated
only when a character is created; existing characters with empty bars must place their abilities from
the spellbook manually.

`rev_1791251882736268955.sql` adds the weapon skills needed by the generated outfits when Individual
Progression's pre-3.3 starting skills are installed. Apply it after the module's base SQL and restart
worldserver before creating characters. It covers bows and two-handed axes for Human/Undead Hunters,
staves for Tauren/Gnome Priests and Troll Warlocks, and two-handed swords for Blood Elf Warriors.
Existing characters need the missing weapon skill taught before equipping the weapon already in their bags.

`rev_1791252289788530902.sql` adds the remaining eleven Retail combinations, including starting locations,
action bars, weapon skills compatible with Individual Progression, and caster Blood Fury for Orc Priests:

| Race | Additional classes |
| --- | --- |
| Orc | Priest |
| Dwarf | Mage, Warlock |
| Night Elf | Mage, Warlock |
| Tauren | Rogue, Mage, Warlock |
| Gnome | Hunter |
| Draenei | Rogue, Warlock |

Apply the world updates after the module's base SQL, install all three DBCs in the client MPQ and the two
server DBCs described above, then restart worldserver. Existing records for either outfit gender are
preserved when rerunning the generator. Adding a combination does not add class trainers or class quests
to its starting zone; those remain the WotLK content provided by the core and installed modules.

Retail references: Blizzard's [race/class table](https://news.blizzard.com/en-us/article/23865973/play-as-a-mage-priest-or-rogue-of-any-race),
[Warlock expansion](https://worldofwarcraft.blizzard.com/en-us/news/23973735/level-up-your-warlock-and-pets),
and [Gnome Hunters](https://worldofwarcraft.blizzard.com/en-us/news/20151961/world-of-warcraft-legion-patch-notes).

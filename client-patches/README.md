# Client patches

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

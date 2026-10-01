# Leafre's Ring of Precise Spell Power

This document records how item `276765` was added for WoW 3.3.5a, including its server data, fishing drop, and
client icon.

## Server item data

The world update is `data/sql/updates/pending_db_world/rev_20260930_000001.sql`. It defines the ring in both
`item_template` and `item_dbc`:

- Quality 3 (rare), item level 66, and no required character level.
- Inventory type 11 (`INVTYPE_FINGER`), so it is an equippable ring.
- Stat type 45 (`ITEM_MOD_SPELL_POWER`) with value 99.
- Binding value 1 (binds when picked up).
- Display ID 31664, which selects the `INV_Jewelry_Ring_38` icon.

The `item_dbc` entry is required for the server to accept the custom item ID while loading item templates. Keep its
class, subclass, inventory type, and display ID synchronized with both `item_template` and the client `Item.dbc`.
Restart worldserver after applying the update so it loads the custom DBC row and item template.

## Fishing drop

The update adds the ring at `0.05` percent chance to every distinct positive `Entry` in
`fishing_loot_template`. This applies the same rare chance to each fishing loot table in the database. The live
world database contained 218 such entries when the update was applied.

## Client DBC and icon

The 3.3.5a `Item.dbc` has eight fields. The generator clones the standard ring record `20624`, which already uses
display ID `31664` and finger inventory type `11`, changes its ID to `276765`, and validates the complete record:

```bash
python client-patches/generate_leafre_ring_dbc.py --source /path/to/original/Item.dbc
```

The generated file is `client-patches/DBFilesClient/Item.dbc`. The standard `ItemDisplayInfo.dbc` already contains
display ID `31664` with inventory icon `INV_Jewelry_Ring_38` (Wowhead icon 133380), so no new
`ItemDisplayInfo.dbc` record is needed.

For the icon to appear in game, package the generated file into the client's custom MPQ with the internal path
`DBFilesClient/Item.dbc`, then fully restart the WoW client. Server SQL cannot update a player's client files.

## Leafre's Ring of Great Resistance

Item `274978` follows the same server DBC, item template, and fishing loot setup. The Wowhead page lists item
level 1, bind-on-pickup, the finger slot, and +150 Arcane, Fire, Nature, Frost, and Shadow Resistance. The pending
world update sets required level 1 and the same 0.05 percent chance in every fishing loot table.

The client record uses display ID `31657` (`INV_Jewelry_Ring_39`), which is present in the 3.3.5a
`ItemDisplayInfo.dbc`. This icon was selected from the ring icons available in the base DBC because Wowhead's
text view does not expose this item's direct icon URL; replace display `31657` in the SQL and generator if the
visual icon should differ.

## Leafre's Ring of Armor Piercing

Item `285326` is rare, item level 1, requires level 1, and grants 50 armor penetration. Its Wowhead page shows
no binding requirement and a sell price of 2, so the item is configured without binding. The world update adds
it at a 0.05 percent chance to every distinct positive fishing loot entry.

Wowhead's item page identifies its icon as `inv_11xp_generic_blizzardphoenixring01`, which is not present in
the standard 3.3.5a `ItemDisplayInfo.dbc`. The client record currently uses the available ring icon
`INV_Jewelry_Ring_39` (display ID `31657`) so the item has a valid icon in the 3.3.5a client. The custom
Forever icon requires adding its texture to the client patch separately.

## Verification

The server database can be checked with:

```sql
SELECT `entry`, `displayid`, `InventoryType`, `RequiredLevel`, `ItemLevel`, `stat_type1`, `stat_value1`
FROM `item_template`
WHERE `entry` = 276765;

SELECT COUNT(*), MIN(`Chance`), MAX(`Chance`)
FROM `fishing_loot_template`
WHERE `Item` = 276765;
```

Expected fishing results are 218 rows with both minimum and maximum chance equal to `0.05` for the current world
database. After restarting worldserver, `.additem 276765 1` should create the item and it should equip into a
finger slot. The icon check requires the client MPQ step above.

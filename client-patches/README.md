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

`generate_race_class_dbc.py` adds the supported Cataclysm and WoW: Forever combinations to
`CharBaseInfo.dbc` and adds male and female starting outfit records to `CharStartOutfit.dbc`.
Provide original 3.3.5a source files; generated files are written to `DBFilesClient/` by default:

```bash
python client-patches/generate_race_class_dbc.py \
  --char-base-info /path/to/original/CharBaseInfo.dbc \
  --char-start-outfit /path/to/original/CharStartOutfit.dbc
```

Package both generated files in the client MPQ under `DBFilesClient/`. The server must also load the
generated `CharStartOutfit.dbc` from its configured DBC directory. Worgen, Goblin, and Skyborne are
not included because this core does not provide those playable races.

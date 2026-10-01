# Client patches

## Leafre's Ring of Precise Spell Power

The server update registers item `276765` with `Item.dbc` display `31664`, whose existing
`ItemDisplayInfo.dbc` record uses the `INV_Jewelry_Ring_38` icon.

To recreate the client record from an original WoW 3.3.5a `Item.dbc`:

```bash
python client-patches/generate_leafre_ring_dbc.py --source /path/to/original/Item.dbc
```

Package `client-patches/DBFilesClient/Item.dbc` in the custom MPQ at `DBFilesClient/Item.dbc`, then fully
close and restart the WoW client so it loads the new record.

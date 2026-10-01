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

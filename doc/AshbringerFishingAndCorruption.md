# Ashbringer Fishing and Corruption

World update `data/sql/updates/pending_db_world/rev_20260930_000004.sql` adds the original Ashbringer (item
`13262`) at a `0.01` percent chance to every positive fishing loot table. Its existing item template remains intact,
including its level requirement, two-handed sword slot, and bind-on-pickup setting.

The corruption interaction uses a neutral ritual altar with gameobject entry `910110`. The previous Herald of
Scholomance NPC entry `910100` is disabled and any database spawn created for it is removed by the update. Spawn
the altar wherever you want with:

```text
.gobject add 910110
```

The altar uses a cryptic greeting. The ritual option appears only when the player carries Ashbringer and 10 Ichor
of Undeath (`7972`) in their bags, with Ashbringer unequipped. Selecting it consumes the items, darkens the player's
view, summons Kel'Thuzad to whisper “Even the brightest flame casts a shadow” with sound `8818`, and then summons
the spectral Image of Arthas (`26100`). Arthas plays the Lich King farewell sound entry `14760` and gives the player
Corrupted Ashbringer (`22691`). The altar becomes usable again after the sequence. The ritual no longer relies on
an NPC dying or despawning.

Arthas appears seven yards along the world X axis from the altar by default, keeps the altar's facing, and uses
65 percent scale. Adjust `@LICHKING_OFFSET_X`, `@LICHKING_OFFSET_Y`, `@LICHKING_OFFSET_Z`, and `@LICHKING_OFFSET_O`
near the top of the SQL update to reposition him. These are world-axis offsets from the altar, not offsets rotated
by its facing. He remains visible for five seconds. Faction `35` allows both Alliance and Horde players to interact
with the altar.

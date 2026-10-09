#!/usr/bin/env python3
"""Generate troll transformation sounds and feral cast presentation aliases for WoW 3.3.5a."""

import argparse
from pathlib import Path

from generate_racial_dbc import ensure_cloned_record, find_record, get_u32, read_wdbc, set_u32


# Spell, visual, and visual-kit IDs use separate tables but share the variant ID for clarity.
# Crocolisks use CreatureSoundData 136, whose native aggro sound is named BasiliskAggro.
VARIANTS = (
    (768, 4228, 3610, 910100, 708),  # Cat Form -> RaptorAggro
    (1066, 775, 837, 910101, 570),  # Aquatic Form -> native crocolisk aggro
)
TABLES = {"Spell": 234, "SpellVisual": 32, "SpellVisualKit": 38}
FERAL_ALIAS_OFFSET = 1000000
FERAL_ATTACK_SOUND = 704  # RaptorAttack: three native attack samples
# Visual, cast kit, and all player ranks. NPC spells with the same visuals are deliberately excluded.
FERAL_ABILITIES = (
    (3882, 3370, (1082, 3029, 5201, 9849, 9850, 27000, 48569, 48570)),  # Claw
    (750, 269, (1822, 1823, 1824, 9904, 27003, 48573, 48574)),  # Rake
    (3950, 3373, (5221, 6800, 8992, 9829, 9830, 27001, 27002, 48571, 48572)),  # Shred
    (2275, 2109, (6785, 6787, 9866, 9867, 27005, 48578, 48579)),  # Ravage
    (3883, 3294, (8998, 9000, 9892, 31709, 27004, 48575)),  # Cower
    (6587, 5891, (22568, 22827, 22828, 22829, 31018, 24248, 48576, 48577)),  # Ferocious Bite
    (8634, 5890, (33876, 33982, 33983, 48565, 48566)),  # Mangle (Cat)
)


def clone(table, source_id, variant_id, changes):
    data, count, size, end = table
    source = find_record(data, count, size, source_id)
    original = bytes(data[source:source + size])
    record, count, end = ensure_cloned_record(data, count, size, end, source_id, variant_id)
    # Refresh the entire clone on reruns so future source-spell updates are retained.
    data[record:record + size] = original
    set_u32(data, record, 0, variant_id)
    for field, value in changes.items():
        set_u32(data, record, field, value)
    return data, count, size, end


def generate(dbc_dir, sounds_path):
    sounds, sound_count, sound_size, _ = read_wdbc(sounds_path, 30, 120)
    tables = {
        name: read_wdbc(dbc_dir / f"{name}.dbc", fields, fields * 4)
        for name, fields in TABLES.items()
    }
    plans = {name: {} for name in TABLES}
    for spell, visual, kit, variant, sound in VARIANTS:
        find_record(sounds, sound_count, sound_size, sound)
        plans["Spell"][variant] = (spell, {131: variant})
        plans["SpellVisual"][variant] = (visual, {3: variant})
        plans["SpellVisualKit"][variant] = (kit, {15: sound})

    find_record(sounds, sound_count, sound_size, FERAL_ATTACK_SOUND)
    for visual, kit, ranks in FERAL_ABILITIES:
        plans["SpellVisual"][FERAL_ALIAS_OFFSET + visual] = (visual, {2: FERAL_ALIAS_OFFSET + kit})
        plans["SpellVisualKit"][FERAL_ALIAS_OFFSET + kit] = (kit, {15: FERAL_ATTACK_SOUND})
        for spell in ranks:
            plans["Spell"][FERAL_ALIAS_OFFSET + spell] = (spell, {131: FERAL_ALIAS_OFFSET + visual})

    original_records = {}
    for name, (data, count, size, _) in tables.items():
        original_records[name] = {
            get_u32(data, 20 + index * size, 0): bytes(data[20 + index * size:20 + (index + 1) * size])
            for index in range(count)
            if get_u32(data, 20 + index * size, 0) not in plans[name]
        }

    for spell, visual, kit, variant, sound in VARIANTS:
        find_record(sounds, sound_count, sound_size, sound)
        for name, source, field, expected in (
            ("Spell", spell, 131, visual),
            ("SpellVisual", visual, 3, kit),
        ):
            data, count, size, _ = tables[name]
            record = find_record(data, count, size, source)
            if get_u32(data, record, field) != expected:
                raise ValueError(f"{name} {source}: unexpected visual chain; review before generating")

    for visual, kit, ranks in FERAL_ABILITIES:
        data, count, size, _ = tables["SpellVisual"]
        record = find_record(data, count, size, visual)
        if get_u32(data, record, 2) != kit:
            raise ValueError(f"SpellVisual {visual}: unexpected cast kit")
        data, count, size, _ = tables["SpellVisualKit"]
        record = find_record(data, count, size, kit)
        if get_u32(data, record, 15) != 4121:
            raise ValueError(f"SpellVisualKit {kit}: expected the original CatAttack sound")
        data, count, size, _ = tables["Spell"]
        for spell in ranks:
            record = find_record(data, count, size, spell)
            if (get_u32(data, record, 131), get_u32(data, record, 208), get_u32(data, record, 12)) != (
                visual, 7, 1
            ):
                raise ValueError(f"Spell {spell}: expected a druid Cat Form spell with visual {visual}")

    for name in TABLES:
        for variant, (source, changes) in plans[name].items():
            tables[name] = clone(tables[name], source, variant, changes)

    # Validate all original records and every clone before writing any output.
    for name, (data, count, size, _) in tables.items():
        offsets = {get_u32(data, 20 + index * size, 0): 20 + index * size for index in range(count)}
        if len(offsets) != count:
            raise ValueError(f"{name}: duplicate record IDs")
        for spell_id, original in original_records[name].items():
            record = offsets[spell_id]
            if data[record:record + size] != original:
                raise ValueError(f"{name}: original record {spell_id} changed")
        for variant, (source, changes) in plans[name].items():
            source_record = offsets[source]
            cloned_record = offsets[variant]
            for field in range(TABLES[name]):
                expected = variant if field == 0 else changes.get(field, get_u32(data, source_record, field))
                if get_u32(data, cloned_record, field) != expected:
                    raise ValueError(f"{name}: clone {variant}, field {field} differs")

    for name, (data, _, _, _) in tables.items():
        (dbc_dir / f"{name}.dbc").write_bytes(data)
        print(f"Updated {name}.dbc: {len(plans[name])} variants; all original records preserved")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dbc-dir", type=Path, default=Path(__file__).resolve().parent / "DBFilesClient")
    parser.add_argument("--sound-entries", required=True, type=Path, help="Original 3.3.5a SoundEntries.dbc")
    args = parser.parse_args()
    generate(args.dbc_dir, args.sound_entries)


if __name__ == "__main__":
    main()

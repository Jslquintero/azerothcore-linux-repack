#!/usr/bin/env python3

import argparse
import struct
from pathlib import Path


RACE_CLASS_PAIRS = (
    (1, 3),   # Human Hunter
    (2, 8),   # Orc Mage
    (3, 7),   # Dwarf Shaman
    (5, 3),   # Undead Hunter
    (5, 2),   # Undead Paladin
    (6, 2),   # Tauren Paladin
    (6, 5),   # Tauren Priest
    (7, 5),   # Gnome Priest
    (8, 9),   # Troll Warlock
    (8, 11),  # Troll Druid
    (10, 1),  # Blood Elf Warrior
)

# Choose existing outfits from the same faction where possible. The item IDs and
# display IDs are class-specific; the target race and gender are set per row.
OUTFIT_TEMPLATE_RACE = {
    (1, 3): 2,
    (2, 8): 8,
    (3, 7): 2,
    (5, 3): 8,
    (5, 2): 1,
    (6, 2): 1,
    (6, 5): 1,
    (7, 5): 1,
    (8, 9): 2,
    (8, 11): 6,
    (10, 1): 1,
}

HEADER_SIZE = 20


def read_wdbc(path: Path, expected_field_count: int, expected_record_size: int):
    data = bytearray(path.read_bytes())
    if len(data) < HEADER_SIZE:
        raise ValueError(f"{path}: truncated WDBC header")

    magic, record_count, field_count, record_size, string_size = struct.unpack_from("<4s4I", data)
    if magic != b"WDBC":
        raise ValueError(f"{path}: expected WDBC magic, found {magic!r}")
    if field_count != expected_field_count or record_size != expected_record_size:
        raise ValueError(
            f"{path}: expected {expected_field_count} fields/{expected_record_size} bytes, "
            f"found {field_count} fields/{record_size} bytes"
        )

    records_end = HEADER_SIZE + record_count * record_size
    if records_end + string_size != len(data):
        raise ValueError(f"{path}: header sizes do not match file length")

    return data, record_count, record_size, records_end


def patch_char_base_info(source: Path, destination: Path):
    data, record_count, record_size, records_end = read_wdbc(source, 2, 2)
    existing = {
        tuple(data[HEADER_SIZE + index * record_size:HEADER_SIZE + (index + 1) * record_size])
        for index in range(record_count)
    }

    additions = [bytes((race, class_id)) for race, class_id in RACE_CLASS_PAIRS if (race, class_id) not in existing]
    data[records_end:records_end] = b"".join(additions)
    struct.pack_into("<I", data, 4, record_count + len(additions))
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data)


def unpack_outfit_key(record: bytes):
    return record[4], record[5], record[6]


def patch_char_start_outfit(source: Path, destination: Path):
    data, record_count, record_size, records_end = read_wdbc(source, 77, 296)
    records = [
        bytes(data[HEADER_SIZE + index * record_size:HEADER_SIZE + (index + 1) * record_size])
        for index in range(record_count)
    ]
    outfit_by_key = {unpack_outfit_key(record): record for record in records}
    existing = {(race, class_id) for race, class_id, _gender in outfit_by_key}

    next_id = max(struct.unpack_from("<I", record)[0] for record in records) + 1
    additions = []
    for race, class_id in RACE_CLASS_PAIRS:
        if (race, class_id) in existing:
            continue

        template_race = OUTFIT_TEMPLATE_RACE[(race, class_id)]
        for gender in (0, 1):
            template = outfit_by_key.get((template_race, class_id, gender))
            if template is None:
                raise ValueError(
                    f"CharStartOutfit.dbc: no template outfit for race {template_race}, "
                    f"class {class_id}, gender {gender}"
                )

            record = bytearray(template)
            struct.pack_into("<I", record, 0, next_id)
            record[4] = race
            record[5] = class_id
            record[6] = gender
            additions.append(bytes(record))
            next_id += 1

    data[records_end:records_end] = b"".join(additions)
    struct.pack_into("<I", data, 4, record_count + len(additions))
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data)


def main():
    parser = argparse.ArgumentParser(description="Add supported race/class combinations to 3.3.5a DBC files.")
    parser.add_argument("--char-base-info", type=Path, required=True, help="Original 3.3.5a CharBaseInfo.dbc")
    parser.add_argument("--char-start-outfit", type=Path, required=True, help="Original 3.3.5a CharStartOutfit.dbc")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).parent / "DBFilesClient",
        help="Output directory for generated client DBC files",
    )
    args = parser.parse_args()

    patch_char_base_info(args.char_base_info, args.output_dir / "CharBaseInfo.dbc")
    patch_char_start_outfit(args.char_start_outfit, args.output_dir / "CharStartOutfit.dbc")


if __name__ == "__main__":
    main()

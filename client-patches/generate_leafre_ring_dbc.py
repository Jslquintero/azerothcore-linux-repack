#!/usr/bin/env python3

import argparse
import struct
from pathlib import Path


SOURCE_ITEM_ID = 20624
ITEM_FIELDS = 8
ITEM_RECORD_SIZE = ITEM_FIELDS * 4
RINGS = (
    (276765, 31664),
    (274978, 31657),
    (285326, 31657),
)


def read_item_dbc(path: Path):
    data = bytearray(path.read_bytes())
    if len(data) < 20:
        raise ValueError(f"{path}: truncated WDBC header")

    magic, record_count, field_count, record_size, string_size = struct.unpack_from("<4s4I", data)
    if magic != b"WDBC":
        raise ValueError(f"{path}: expected WDBC magic, found {magic!r}")
    if field_count != ITEM_FIELDS or record_size != ITEM_RECORD_SIZE:
        raise ValueError(
            f"{path}: expected {ITEM_FIELDS} fields/{ITEM_RECORD_SIZE} bytes, "
            f"found {field_count} fields/{record_size} bytes"
        )

    records_end = 20 + record_count * record_size
    if records_end + string_size != len(data):
        raise ValueError(f"{path}: header sizes do not match file length")

    return data, record_count, record_size, records_end


def find_record(data: bytearray, record_count: int, record_size: int, item_id: int):
    for index in range(record_count):
        offset = 20 + index * record_size
        if struct.unpack_from("<I", data, offset)[0] == item_id:
            return offset

    return None


def generate(source: Path, output: Path):
    data, record_count, record_size, records_end = read_item_dbc(source)
    source_offset = find_record(data, record_count, record_size, SOURCE_ITEM_ID)
    if source_offset is None:
        raise ValueError(f"{source}: source item {SOURCE_ITEM_ID} was not found")

    for item_id, display_id in RINGS:
        record_offset = find_record(data, record_count, record_size, item_id)
        if record_offset is None:
            new_record = bytearray(data[source_offset:source_offset + record_size])
            struct.pack_into("<I", new_record, 0, item_id)
            struct.pack_into("<I", new_record, 20, display_id)
            data[records_end:records_end] = new_record
            record_offset = records_end
            record_count += 1
            records_end += record_size
            struct.pack_into("<I", data, 4, record_count)

        record = struct.unpack_from("<8I", data, record_offset)
        expected = (item_id, 4, 0, 0xFFFFFFFF, 1, display_id, 11, 0)
        if record != expected:
            raise ValueError(f"{output}: item {item_id} has unexpected fields: {record}")

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(data)


def main():
    parser = argparse.ArgumentParser(description="Add custom Leafre ring records to a WoW 3.3.5a Item.dbc.")
    parser.add_argument("--source", type=Path, required=True, help="Original 3.3.5a Item.dbc")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parent / "DBFilesClient" / "Item.dbc",
        help="Output Item.dbc for the custom client patch",
    )
    args = parser.parse_args()
    generate(args.source, args.output)
    print(f"Generated {args.output}")


if __name__ == "__main__":
    main()

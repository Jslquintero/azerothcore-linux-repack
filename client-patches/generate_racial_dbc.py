#!/usr/bin/env python3

import argparse
import struct
from pathlib import Path


SPELL_FIELD_COUNT = 234
SPELL_RECORD_SIZE = SPELL_FIELD_COUNT * 4


def read_wdbc(path: Path, expected_fields: int, expected_record_size: int):
    data = bytearray(path.read_bytes())
    if len(data) < 20:
        raise ValueError(f"{path}: truncated WDBC header")

    magic, record_count, field_count, record_size, string_size = struct.unpack_from("<4s4I", data)
    if magic != b"WDBC":
        raise ValueError(f"{path}: expected WDBC magic, found {magic!r}")
    if field_count != expected_fields or record_size != expected_record_size:
        raise ValueError(
            f"{path}: expected {expected_fields} fields/{expected_record_size} bytes, "
            f"found {field_count} fields/{record_size} bytes"
        )

    records_end = 20 + record_count * record_size
    if records_end + string_size != len(data):
        raise ValueError(f"{path}: header sizes do not match file length")

    return data, record_count, record_size, records_end


def find_record(data: bytearray, record_count: int, record_size: int, spell_id: int) -> int:
    for index in range(record_count):
        offset = 20 + index * record_size
        if struct.unpack_from("<I", data, offset)[0] == spell_id:
            return offset

    raise ValueError(f"Spell.dbc: spell {spell_id} was not found")


def get_u32(data: bytearray, record_offset: int, field: int) -> int:
    return struct.unpack_from("<I", data, record_offset + field * 4)[0]


def set_u32(data: bytearray, record_offset: int, field: int, value: int):
    struct.pack_into("<I", data, record_offset + field * 4, value & 0xFFFFFFFF)


def ensure_cloned_record(
    data: bytearray,
    record_count: int,
    record_size: int,
    records_end: int,
    source_id: int,
    new_id: int,
):
    try:
        return find_record(data, record_count, record_size, new_id), record_count, records_end
    except ValueError:
        source = find_record(data, record_count, record_size, source_id)
        clone = bytes(data[source:source + record_size])
        data[records_end:records_end] = clone
        new_record = records_end
        record_count += 1
        records_end += record_size
        struct.pack_into("<I", data, 4, record_count)
        set_u32(data, new_record, 0, new_id)
        return new_record, record_count, records_end


def remove_record(data: bytearray, record_count: int, record_size: int, records_end: int, spell_id: int):
    for index in range(record_count):
        offset = 20 + index * record_size
        if get_u32(data, offset, 0) != spell_id:
            continue

        del data[offset:offset + record_size]
        record_count -= 1
        records_end -= record_size
        struct.pack_into("<I", data, 4, record_count)
        break

    return record_count, records_end


def set_string(data: bytearray, records_end: int, record_offset: int, field: int, value: str):
    encoded = value.encode("utf-8") + b"\0"
    strings = data[records_end:]
    string_offset = strings.find(encoded)
    if string_offset < 0:
        string_offset = len(strings)
        data.extend(encoded)
        struct.pack_into("<I", data, 16, len(data) - records_end)

    set_u32(data, record_offset, field, string_offset)


def require_fields(data: bytearray, record_offset: int, spell_id: int, expected: dict[int, int]):
    mismatches = []
    for field, value in expected.items():
        actual = get_u32(data, record_offset, field)
        if actual != value:
            mismatches.append(f"field {field}: expected {value}, found {actual}")

    if mismatches:
        raise ValueError(f"Spell.dbc: spell {spell_id} validation failed: " + "; ".join(mismatches))


def patch_blood_fury(data: bytearray, records_end: int, record_count: int, record_size: int):
    for spell_id in (20572, 33697, 33702):
        record = find_record(data, record_count, record_size, spell_id)
        fields = {
            4: 16,      # Is Ability.
            28: 1,      # Instant cast.
            29: 120000, # Two-minute cooldown.
            40: 8,      # Fifteen seconds in this client's SpellDuration.dbc.
            68: 0xFFFFFFFF,
            71: 6,
            72: 6,
            73: 6,
            74: 1,
            75: 1,
            76: 1,
            80: 9,
            81: 9,
            82: 9,
            86: 1,
            87: 1,
            88: 1,
            95: 166,    # Melee attack power percent.
            96: 167,    # Ranged attack power percent.
            97: 4,      # Dummy aura; server script applies 10% spell power.
            133: 1662,  # racial_orc_berserkerstrength.
            225: 1,
        }
        for field, value in fields.items():
            set_u32(data, record, field, value)
        set_string(data, records_end, record, 170, "Increases Attack Power and Spell Power by 10% for 15 sec.")
        set_string(data, records_end, record, 187, "Attack Power and Spell Power increased by 10%.")
        require_fields(data, record, spell_id, fields)


def patch_tauren_racials(data: bytearray, records_end: int, record_count: int, record_size: int):
    war_stomp = find_record(data, record_count, record_size, 20549)
    war_stomp_fields = {
        4: 327696,
        5: 136,
        28: 3,
        29: 120000,
        40: 39,
        46: 1,
        71: 6,
        74: 1,
        80: 0xFFFFFFFF,
        86: 18,
        92: 14,
        95: 12,
        133: 129,
        212: 5,
        225: 1,
    }
    for field, value in war_stomp_fields.items():
        set_u32(data, war_stomp, field, value)
    set_string(data, records_end, war_stomp, 170, "Stuns up to 5 enemies within 8 yds for 2 sec.")
    set_string(data, records_end, war_stomp, 187, "Stunned.")
    require_fields(data, war_stomp, 20549, war_stomp_fields)

    endurance = find_record(data, record_count, record_size, 20550)
    endurance_fields = {
        4: 80,
        40: 0,
        71: 6,
        72: 6,
        73: 6,
        74: 1,
        75: 1,
        76: 1,
        80: 4,
        81: 0,
        82: 0,
        86: 1,
        87: 1,
        88: 1,
        95: 133,
        96: 54,
        97: 55,
        133: 312,
        225: 1,
    }
    for field, value in endurance_fields.items():
        set_u32(data, endurance, field, value)
    set_string(data, records_end, endurance, 170, "Total Health increased by 5% and chance to hit increased by 1%.")
    require_fields(data, endurance, 20550, endurance_fields)

    cultivation = find_record(data, record_count, record_size, 20552)
    cultivation_fields = {
        4: 16,
        5: 0,
        28: 1,
        40: 0,
        46: 1,
        71: 3,
        74: 1,
        80: 15,
        86: 1,
        92: 8,
        133: 1626,
        205: 133,
        206: 1500,
        225: 1,
    }
    for field in range(71, 131):
        set_u32(data, cultivation, field, 0)
    for field, value in cultivation_fields.items():
        set_u32(data, cultivation, field, value)
    set_string(data, records_end, cultivation, 170, "Cultivate a nearby herb, growing a duplicate you can harvest "
        "without requiring Herbalism skill. Each herb may only be cultivated once.")
    set_string(data, records_end, cultivation, 187, "")
    require_fields(data, cultivation, 20552, cultivation_fields)

    plainsrunning, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 20550, 910013
    )
    plainsrunning_speed, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 910013, 910016
    )

    for record in (plainsrunning, plainsrunning_speed):
        for field in range(71, 131):
            set_u32(data, record, field, 0)

    plainsrunning_fields = {
        4: 80,
        5: 0x10000000,
        28: 1,
        40: 21,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        72: 6,
        73: 6,
        74: 1,
        75: 1,
        76: 1,
        80: 1,
        81: 5,
        82: 30,
        86: 1,
        87: 1,
        88: 1,
        95: 226,
        96: 4,
        97: 4,
        98: 1000,
        133: 2208,
        225: 1,
    }
    for field, value in plainsrunning_fields.items():
        set_u32(data, plainsrunning, field, value)
    set_string(data, records_end, plainsrunning, 136, "Plainsrunning")
    set_string(
        data,
        records_end,
        plainsrunning,
        170,
        "Gain 1% increased movement speed every 5 sec spent moving, up to a maximum of 30% increase. "
        "Taking damage or standing still will reduce this effect.",
    )
    set_string(data, records_end, plainsrunning, 187, "")
    require_fields(data, plainsrunning, 910013, plainsrunning_fields)

    speed_fields = {
        4: 0,
        5: 0,
        28: 1,
        40: 21,
        46: 1,
        49: 30,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 0,
        86: 1,
        95: 31,
        133: 2208,
        225: 1,
    }
    for field, value in speed_fields.items():
        set_u32(data, plainsrunning_speed, field, value)
    set_string(data, records_end, plainsrunning_speed, 136, "Plainsrunning")
    set_string(data, records_end, plainsrunning_speed, 170, "")
    set_string(data, records_end, plainsrunning_speed, 187, "Movement speed increased by $s1%.")
    require_fields(data, plainsrunning_speed, 910016, speed_fields)

    return record_count, records_end


def patch_troll_racials(data: bytearray, records_end: int, record_count: int, record_size: int):
    berserking, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 26290, 20554
    )
    for field in range(71, 131):
        set_u32(data, berserking, field, 0)

    berserking_fields = {
        4: 16,
        28: 1,
        29: 180000,
        40: 1,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        72: 6,
        73: 6,
        74: 1,
        75: 1,
        76: 1,
        80: 9,
        81: 9,
        82: 9,
        86: 1,
        87: 1,
        88: 1,
        95: 138,
        96: 140,
        97: 65,
        133: 1814,
        225: 1,
    }
    for field, value in berserking_fields.items():
        set_u32(data, berserking, field, value)
    set_string(data, records_end, berserking, 136, "Berserking")
    set_string(data, records_end, berserking, 170, "Increases your spellcasting and attack speed by 10% for 10 sec.")
    set_string(data, records_end, berserking, 187, "Spellcasting and attack speed increased by 10%.")
    require_fields(data, berserking, 20554, berserking_fields)

    beast_slaying = find_record(data, record_count, record_size, 20557)
    beast_slaying_fields = {
        4: 80,
        40: 21,
        71: 6,
        74: 1,
        80: 4,
        86: 1,
        95: 168,
        110: 1,
        133: 1653,
        225: 1,
    }
    for field, value in beast_slaying_fields.items():
        set_u32(data, beast_slaying, field, value)
    set_string(data, records_end, beast_slaying, 170, "Damage dealt versus Beasts increased by 5%.")
    require_fields(data, beast_slaying, 20557, beast_slaying_fields)

    regeneration = find_record(data, record_count, record_size, 20555)
    regeneration_fields = {
        4: 80,
        40: 21,
        71: 6,
        72: 6,
        73: 0,
        74: 1,
        75: 1,
        76: 0,
        80: 9,
        81: 9,
        82: 0,
        86: 1,
        87: 1,
        88: 0,
        95: 88,
        96: 116,
        97: 0,
        133: 149,
        225: 1,
    }
    for field, value in regeneration_fields.items():
        set_u32(data, regeneration, field, value)
    set_string(
        data,
        records_end,
        regeneration,
        170,
        "Health regeneration rate increased by 10%. In addition, 10% of total Health regeneration will continue "
        "during combat.",
    )
    require_fields(data, regeneration, 20555, regeneration_fields)

    rapid_regeneration, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 20555, 910017
    )
    for field in range(71, 131):
        set_u32(data, rapid_regeneration, field, 0)

    rapid_fields = {
        4: 65552,
        28: 1,
        29: 180000,
        40: 32,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 9,
        86: 1,
        95: 226,
        98: 1200,
        133: 149,
        214: 1,
        225: 1,
    }
    for field, value in rapid_fields.items():
        set_u32(data, rapid_regeneration, field, value)
    set_string(data, records_end, rapid_regeneration, 136, "Rapid Regeneration")
    set_string(
        data,
        records_end,
        rapid_regeneration,
        170,
        "Regenerate 50% of your maximum Health over 6 sec. Any movement, action, or damage taken will cancel "
        "the effect.",
    )
    set_string(data, records_end, rapid_regeneration, 187, "Regenerating 50% of maximum Health over 6 sec.")
    require_fields(data, rapid_regeneration, 910017, rapid_fields)

    return record_count, records_end


def patch_undead_racials(data: bytearray, records_end: int, record_count: int, record_size: int):
    will = find_record(data, record_count, record_size, 7744)
    for field in range(71, 131):
        set_u32(data, will, field, 0)
    will_fields = {
        4: 16,
        5: 0,
        28: 1,
        29: 120000,
        40: 0,
        46: 1,
        71: 108,
        72: 108,
        73: 108,
        74: 1,
        75: 1,
        76: 1,
        80: 99,
        81: 99,
        82: 99,
        86: 1,
        87: 1,
        88: 1,
        110: 5,
        111: 10,
        112: 1,
        133: 61,
        205: 133,
        206: 0,
        225: 1,
    }
    for field, value in will_fields.items():
        set_u32(data, will, field, value)
    set_string(data, records_end, will, 170, "Removes any Charm, Fear, and Sleep effect. 2 min cooldown.")
    set_string(data, records_end, will, 187, "")
    require_fields(data, will, 7744, will_fields)

    cannibalize = find_record(data, record_count, record_size, 20577)
    cannibalize_fields = {
        4: 16,
        5: 131072,
        6: 524289,
        28: 1,
        29: 120000,
        40: 0,
        46: 12,
        71: 3,
        74: 0,
        80: 0,
        92: 8,
        133: 146,
        205: 133,
        206: 1500,
        214: 2,
        225: 1,
    }
    for field, value in cannibalize_fields.items():
        set_u32(data, cannibalize, field, value)
    set_string(data, records_end, cannibalize, 170, "When activated, regenerates 7% of total Health and Mana every "
        "2 sec for 10 sec. Only works on Humanoid or Undead corpses within 5 yds. Moving, taking action, or any "
        "damage taken while Cannibalizing will cancel the effect.")
    set_string(data, records_end, cannibalize, 187, "")
    require_fields(data, cannibalize, 20577, cannibalize_fields)

    cannibalize_aura = find_record(data, record_count, record_size, 20578)
    for field in range(71, 131):
        set_u32(data, cannibalize_aura, field, 0)
    cannibalize_aura_fields = {
        5: 536870976,
        28: 1,
        33: 15374,
        35: 101,
        40: 1,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        72: 6,
        74: 1,
        75: 1,
        80: 6,
        81: 6,
        86: 1,
        87: 1,
        95: 20,
        96: 21,
        98: 2000,
        99: 2000,
        131: 5724,
        133: 146,
        225: 1,
    }
    for field, value in cannibalize_aura_fields.items():
        set_u32(data, cannibalize_aura, field, value)
    set_string(data, records_end, cannibalize_aura, 136, "Cannibalize")
    set_string(data, records_end, cannibalize_aura, 170, "")
    set_string(data, records_end, cannibalize_aura, 187, "Regenerating 7% of total Health and Mana every 2 sec.")
    require_fields(data, cannibalize_aura, 20578, cannibalize_aura_fields)

    underwater = find_record(data, record_count, record_size, 5227)
    underwater_fields = {
        4: 80,
        40: 0,
        71: 6,
        74: 1,
        80: 299,
        86: 1,
        95: 155,
        133: 545,
        225: 1,
    }
    for field, value in underwater_fields.items():
        set_u32(data, underwater, field, value)
    set_string(data, records_end, underwater, 170, "Underwater breath lasts 300% longer than normal.")
    require_fields(data, underwater, 5227, underwater_fields)

    touch_melee, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 5227, 910018
    )
    touch_caster, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 5227, 910019
    )
    for record in (touch_melee, touch_caster):
        for field in range(71, 131):
            set_u32(data, record, field, 0)

    touch_common = {
        4: 80,
        28: 1,
        40: 21,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 4,
        86: 1,
        95: 4,
        133: 61,
        225: 1,
    }
    for record, spell_id, chance in ((touch_melee, 910018, 5), (touch_caster, 910019, 10)):
        fields = dict(touch_common)
        fields[54] = chance
        for field, value in fields.items():
            set_u32(data, record, field, value)
        set_string(data, records_end, record, 136, "Touch of the Grave")
        set_string(data, records_end, record, 170, "Your attacks and damaging spells have a chance to drain the "
            "target, dealing up to 5% of your maximum Health in damage and healing you for the same amount. This "
            "effect has a 1 sec cooldown.")
        set_string(data, records_end, record, 187, "")
        require_fields(data, record, spell_id, fields)

    return record_count, records_end


def patch_dwarf_racials(data: bytearray, records_end: int, record_count: int, record_size: int):
    find_treasure = find_record(data, record_count, record_size, 2481)
    find_treasure_fields = {
        4: 688128016,
        5: 268566560,
        28: 1,
        40: 21,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 0,
        80: 0,
        86: 1,
        95: 45,
        110: 6,
        133: 202,
        205: 133,
        206: 1500,
        225: 1,
    }
    for field, value in find_treasure_fields.items():
        set_u32(data, find_treasure, field, value)
    set_string(data, records_end, find_treasure, 170, "Allows the dwarf to sense nearby treasure, making it appear "
        "on the minimap. Lasts until canceled.")
    require_fields(data, find_treasure, 2481, find_treasure_fields)

    stoneform = find_record(data, record_count, record_size, 20594)
    stoneform_fields = {
        4: 262400,
        5: 268566528,
        28: 1,
        29: 180000,
        40: 31,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        72: 6,
        73: 6,
        74: 1,
        75: 1,
        76: 1,
        80: 0xFFFFFFFF,
        81: 0xFFFFFFFF,
        82: 0xFFFFFFFF,
        86: 1,
        87: 1,
        88: 1,
        95: 41,
        96: 41,
        97: 77,
        110: 4,
        111: 3,
        112: 15,
        131: 5787,
        133: 93,
        205: 133,
        206: 0,
        214: 2,
        225: 1,
    }
    for field, value in stoneform_fields.items():
        set_u32(data, stoneform, field, value)
    set_string(data, records_end, stoneform, 170, "Instantly removes and grants immunity to all Bleed, Poison, "
        "and Disease effects, and reduces all Physical damage taken by 10% for 8 sec.")
    set_string(data, records_end, stoneform, 187, "Immune to Bleed, Poison, and Disease effects. Physical damage "
        "taken reduced by 10%.")
    require_fields(data, stoneform, 20594, stoneform_fields)

    big_game, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 20595, 910020
    )
    mace_specialization, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 59224, 910021
    )
    stoneform_reduction, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 20594, 910022
    )

    for record in (big_game, mace_specialization, stoneform_reduction):
        for field in range(71, 131):
            set_u32(data, record, field, 0)

    big_game_fields = {
        4: 80,
        28: 1,
        40: 21,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 4,
        86: 1,
        95: 168,
        110: 1,
        133: 346,
        225: 1,
    }
    for field, value in big_game_fields.items():
        set_u32(data, big_game, field, value)
    set_string(data, records_end, big_game, 136, "Big Game Hunter")
    set_string(data, records_end, big_game, 170, "Damage dealt versus Beasts increased by 5%.")
    set_string(data, records_end, big_game, 187, "")
    require_fields(data, big_game, 910020, big_game_fields)

    mace_fields = {
        4: 80,
        28: 1,
        40: 21,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 0xFFFFFFFF,
        86: 1,
        95: 4,
        133: 1663,
        225: 1,
    }
    for field, value in mace_fields.items():
        set_u32(data, mace_specialization, field, value)
    set_string(data, records_end, mace_specialization, 136, "Mace Specialization")
    set_string(data, records_end, mace_specialization, 170, "Increases your critical strike chance with all spells "
        "and attacks by 1% while you have a mace or two-handed mace equipped.")
    set_string(data, records_end, mace_specialization, 187, "")
    require_fields(data, mace_specialization, 910021, mace_fields)

    reduction_fields = {
        4: 0,
        5: 0,
        28: 1,
        29: 0,
        40: 31,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 0xFFFFFFF5,
        86: 1,
        95: 87,
        110: 1,
        131: 0,
        133: 93,
        205: 0,
        206: 0,
        214: 0,
        225: 32,
    }
    for field, value in reduction_fields.items():
        set_u32(data, stoneform_reduction, field, value)
    set_string(data, records_end, stoneform_reduction, 136, "Stoneform")
    set_string(data, records_end, stoneform_reduction, 170, "")
    set_string(data, records_end, stoneform_reduction, 187, "Physical damage taken reduced by 10%.")
    require_fields(data, stoneform_reduction, 910022, reduction_fields)

    return record_count, records_end


def patch_gnome_racials(data: bytearray, records_end: int, record_count: int, record_size: int):
    escape_artist = find_record(data, record_count, record_size, 20589)
    escape_fields = {
        4: 32784,
        5: 32768,
        28: 1,
        29: 120000,
        40: 28,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        72: 6,
        73: 0,
        74: 1,
        75: 1,
        76: 0,
        80: 10,
        81: 10,
        82: 0,
        86: 1,
        87: 1,
        88: 0,
        95: 77,
        96: 77,
        97: 0,
        110: 7,
        111: 11,
        112: 0,
        131: 1008,
        133: 517,
        205: 133,
        206: 1500,
        214: 2,
        225: 1,
    }
    for field, value in escape_fields.items():
        set_u32(data, escape_artist, field, value)
    set_string(data, records_end, escape_artist, 170, "Instantly escape the effects of any movement impairing "
        "effect and gain immunity to those effects for 3 sec.")
    set_string(data, records_end, escape_artist, 187, "Immune to movement impairing effects.")
    require_fields(data, escape_artist, 20589, escape_fields)

    expansive_mana = find_record(data, record_count, record_size, 20591)
    expansive_fields = {
        4: 80,
        28: 1,
        40: 21,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 4,
        86: 1,
        95: 137,
        110: 3,
        133: 1654,
        225: 1,
    }
    for field, value in expansive_fields.items():
        set_u32(data, expansive_mana, field, value)
    set_string(data, records_end, expansive_mana, 170, "Maximum Mana increased by 5%.")
    require_fields(data, expansive_mana, 20591, expansive_fields)

    engineering = find_record(data, record_count, record_size, 20593)
    engineering_fields = {
        4: 80,
        28: 1,
        40: 21,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 20,
        86: 1,
        95: 4,
        133: 353,
        225: 1,
    }
    for field, value in engineering_fields.items():
        set_u32(data, engineering, field, value)
    set_string(data, records_end, engineering, 170, "Your gnomish ingenuity reduces the rate of engineering "
        "devices failing or backfiring when you use them by 20%.")
    require_fields(data, engineering, 20593, engineering_fields)

    custom_sources = (
        (20591, 910023),
        (20591, 910024),
        (20589, 910025),
        (20589, 910026),
        (20589, 910027),
        (20589, 910028),
    )
    custom_records = {}
    for source_id, spell_id in custom_sources:
        custom_records[spell_id], record_count, records_end = ensure_cloned_record(
            data, record_count, record_size, records_end, source_id, spell_id
        )

    for spell_id in custom_records:
        for field in range(71, 131):
            set_u32(data, custom_records[spell_id], field, 0)

    for spell_id, description in (
        (910023, "Maximum Rage increased by 5%."),
        (910024, "Maximum Energy increased by 5%."),
    ):
        fields = {
            4: 80,
            28: 1,
            40: 21,
            46: 1,
            68: 0xFFFFFFFF,
            71: 6,
            74: 1,
            80: 4,
            86: 1,
            95: 4,
            133: 1654,
            225: 1,
        }
        record = custom_records[spell_id]
        for field, value in fields.items():
            set_u32(data, record, field, value)
        set_string(data, records_end, record, 136, "Expansive Mind")
        set_string(data, records_end, record, 170, description)
        set_string(data, records_end, record, 187, "")
        require_fields(data, record, spell_id, fields)

    eureka_data = {
        910025: (8, 20, 517, "Your next 3 damaging abilities have their Energy cost reduced by 20% and deal "
            "10% more damage.", "Next damaging abilities cost 20% less Energy and deal 10% more damage."),
        910026: (1, 40, 1321, "Your next 3 damaging abilities have their Rage cost reduced by 40% and deal "
            "10% more damage.", "Next damaging abilities cost 40% less Rage and deal 10% more damage."),
        910027: (256, 50, 144, "Your next 3 damaging abilities have their Mana cost reduced by 50% and deal "
            "10% more damage.", "Next damaging abilities cost 50% less Mana and deal 10% more damage."),
        910028: (16, 15, 1352, "Your next 3 damaging or healing abilities have their Mana cost reduced by 15% "
            "and deal 10% more damage or healing.", "Next damaging or healing abilities cost 15% less Mana and "
            "deal 10% more damage or healing."),
    }
    for spell_id, (_class_mask, cost_pct, icon_id, description, aura_description) in eureka_data.items():
        fields = {
            4: 16,
            5: 0,
            28: 1,
            29: 120000,
            40: 8,
            46: 1,
            54: 100,
            68: 0xFFFFFFFF,
            71: 6,
            72: 6,
            73: 6,
            74: 1,
            75: 1,
            76: 1,
            80: 0xFFFFFFFF - cost_pct,
            81: 9,
            82: 9,
            86: 1,
            87: 1,
            88: 1,
            95: 72,
            96: 79,
            97: 136,
            110: 127,
            111: 127,
            112: 127,
            133: icon_id,
            205: 0,
            206: 0,
            214: 1,
            225: 8,
        }
        record = custom_records[spell_id]
        for field, value in fields.items():
            set_u32(data, record, field, value)
        set_string(data, records_end, record, 136, "Eureka!")
        set_string(data, records_end, record, 170, description)
        set_string(data, records_end, record, 187, aura_description)
        require_fields(data, record, spell_id, fields)

    return record_count, records_end


def patch_human_racials(data: bytearray, records_end: int, record_count: int, record_size: int):
    human_spirit = find_record(data, record_count, record_size, 20598)
    spirit_fields = {
        4: 80,
        28: 1,
        40: 0,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 4,
        86: 1,
        95: 137,
        110: 4,
        133: 1656,
        225: 1,
    }
    for field, value in spirit_fields.items():
        set_u32(data, human_spirit, field, value)
    set_string(data, records_end, human_spirit, 170, "Spirit increased by 5%.")
    require_fields(data, human_spirit, 20598, spirit_fields)

    sword_specialization = find_record(data, record_count, record_size, 20597)
    sword_fields = {
        4: 80,
        28: 1,
        40: 21,
        46: 1,
        68: 0xFFFFFFFF,
        69: 0,
        70: 0,
        71: 6,
        74: 1,
        80: 1,
        86: 1,
        95: 4,
        133: 1462,
        225: 1,
    }
    for field, value in sword_fields.items():
        set_u32(data, sword_specialization, field, value)
    set_string(data, records_end, sword_specialization, 170, "Increases your critical strike chance with all spells "
        "and attacks by 2% while you have a sword or two-handed sword equipped.")
    require_fields(data, sword_specialization, 20597, sword_fields)

    perception = find_record(data, record_count, record_size, 20600)
    perception_fields = {
        4: 262160,
        5: 32,
        6: 524288,
        28: 1,
        29: 180000,
        40: 18,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 50,
        86: 1,
        95: 17,
        131: 5727,
        133: 44,
        205: 133,
        206: 1500,
        225: 1,
    }
    for field, value in perception_fields.items():
        set_u32(data, perception, field, value)
    set_string(data, records_end, perception, 170, "Dramatically increases stealth detection for 20 sec.")
    set_string(data, records_end, perception, 187, "Stealth detection dramatically increased.")
    require_fields(data, perception, 20600, perception_fields)

    will_to_survive, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 59752, 910029
    )
    for field in range(71, 131):
        set_u32(data, will_to_survive, field, 0)

    will_fields = {
        4: 16,
        5: 163840,
        28: 1,
        29: 180000,
        40: 0,
        46: 1,
        68: 0xFFFFFFFF,
        71: 108,
        74: 1,
        80: 99,
        86: 1,
        110: 12,
        131: 86,
        133: 71,
        205: 133,
        206: 1500,
        214: 1,
        225: 1,
    }
    for field, value in will_fields.items():
        set_u32(data, will_to_survive, field, value)
    set_string(data, records_end, will_to_survive, 136, "Will to Survive")
    set_string(data, records_end, will_to_survive, 170, "Instantly removes all Stun effects.")
    set_string(data, records_end, will_to_survive, 187, "")
    require_fields(data, will_to_survive, 910029, will_fields)

    return record_count, records_end


def patch_night_elf_racials(data: bytearray, records_end: int, record_count: int, record_size: int):
    shadowmeld, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 58984, 20580
    )
    elunes_light, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 20582, 910031
    )
    wisp_speed, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 20585, 910032
    )

    for record in (shadowmeld, elunes_light, wisp_speed):
        for field in range(71, 131):
            set_u32(data, record, field, 0)

    shadowmeld_fields = {
        4: 1376272,
        5: 132112,
        6: 2621444,
        28: 1,
        29: 10000,
        40: 21,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        72: 6,
        74: 1,
        75: 1,
        80: 0,
        81: 0xFFF0BDC1,
        86: 1,
        87: 1,
        95: 16,
        96: 103,
        131: 184,
        133: 103,
        214: 2,
        225: 1,
    }
    for field, value in shadowmeld_fields.items():
        set_u32(data, shadowmeld, field, value)
    set_string(data, records_end, shadowmeld, 136, "Shadowmeld")
    set_string(data, records_end, shadowmeld, 170, "Activate to slip into the shadows, reducing the chance for "
        "enemies to detect your presence. Lasts until cancelled or upon moving. Using this ability in combat "
        "discourages enemies from attacking you, but increases the cooldown to 2 min.")
    set_string(data, records_end, shadowmeld, 187, "Shadowmelded.")
    require_fields(data, shadowmeld, 20580, shadowmeld_fields)

    quickness = find_record(data, record_count, record_size, 20582)
    quickness_fields = {
        4: 80,
        28: 1,
        40: 21,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        72: 6,
        73: 6,
        74: 1,
        75: 1,
        76: 1,
        80: 0,
        81: 1,
        82: 0,
        86: 1,
        87: 1,
        88: 1,
        95: 49,
        96: 31,
        97: 154,
        133: 131,
        225: 1,
    }
    for field, value in quickness_fields.items():
        set_u32(data, quickness, field, value)
    set_string(data, records_end, quickness, 170, "Dodge chance increased by 1% and movement speed increased by "
        "2%. Night Elf Rogues and Druids are harder to detect in Stealth as if they were 1 level higher.")
    require_fields(data, quickness, 20582, quickness_fields)

    wisp = find_record(data, record_count, record_size, 20585)
    wisp_fields = {
        4: 80,
        28: 1,
        40: 0,
        46: 1,
        68: 0xFFFFFFFF,
        71: 3,
        74: 1,
        80: 0,
        86: 1,
        133: 122,
        225: 1,
    }
    for field, value in wisp_fields.items():
        set_u32(data, wisp, field, value)
    set_string(data, records_end, wisp, 170, "Transform into a wisp upon death, increasing movement speed by 75%.")
    require_fields(data, wisp, 20585, wisp_fields)

    elune_fields = {
        4: 16,
        5: 0,
        28: 1,
        29: 180000,
        40: 8,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 9,
        86: 1,
        95: 4,
        133: 1352,
        214: 1,
        225: 1,
    }
    for field, value in elune_fields.items():
        set_u32(data, elunes_light, field, value)
    set_string(data, records_end, elunes_light, 136, "Elune's Light")
    set_string(data, records_end, elunes_light, 170, "Increases your critical strike chance with all spells and "
        "attacks by 10% for 15 sec.")
    set_string(data, records_end, elunes_light, 187, "Critical strike chance with all spells and attacks increased "
        "by 10%.")
    require_fields(data, elunes_light, 910031, elune_fields)

    wisp_speed_fields = {
        4: 0,
        28: 1,
        40: 21,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 74,
        86: 1,
        95: 31,
        133: 122,
        225: 32,
    }
    for field, value in wisp_speed_fields.items():
        set_u32(data, wisp_speed, field, value)
    set_string(data, records_end, wisp_speed, 136, "Wisp Spirit")
    set_string(data, records_end, wisp_speed, 170, "")
    set_string(data, records_end, wisp_speed, 187, "Movement speed increased by 75%.")
    require_fields(data, wisp_speed, 910032, wisp_speed_fields)

    return record_count, records_end


def patch_spell_dbc(path: Path):
    data, record_count, record_size, records_end = read_wdbc(path, SPELL_FIELD_COUNT, SPELL_RECORD_SIZE)

    for spell_id in range(910003, 910036):
        if spell_id not in {910013, 910016, 910017, 910018, 910019, 910020, 910021, 910022, 910023, 910024,
            910025, 910026, 910027, 910028, 910029, 910031, 910032, 910033, 910034, 910035}:
            record_count, records_end = remove_record(data, record_count, record_size, records_end, spell_id)

    patch_blood_fury(data, records_end, record_count, record_size)
    record_count, records_end = patch_tauren_racials(data, records_end, record_count, record_size)
    record_count, records_end = patch_troll_racials(data, records_end, record_count, record_size)
    record_count, records_end = patch_undead_racials(data, records_end, record_count, record_size)
    record_count, records_end = patch_dwarf_racials(data, records_end, record_count, record_size)
    record_count, records_end = patch_gnome_racials(data, records_end, record_count, record_size)
    record_count, records_end = patch_human_racials(data, records_end, record_count, record_size)
    record_count, records_end = patch_night_elf_racials(data, records_end, record_count, record_size)

    hardiness = find_record(data, record_count, record_size, 20573)
    hardiness_fields = {
        4: 80,
        71: 6,
        74: 1,
        80: 0xFFFFFFEB,
        86: 1,
        95: 232,
        110: 12,
        133: 1652,  # inv_helmet_23.
    }
    for field, value in hardiness_fields.items():
        set_u32(data, hardiness, field, value)
    set_string(data, records_end, hardiness, 170, "Duration of Stun effects on you reduced by 20%.")
    require_fields(data, hardiness, 20573, hardiness_fields)

    axe_specialization = find_record(data, record_count, record_size, 20574)
    axe_fields = {
        4: 80,
        68: 0xFFFFFFFF,
        69: 0,
        70: 0,
        71: 6,
        74: 1,
        80: 0xFFFFFFFF,
        86: 1,
        95: 4,     # Dummy aura; server script applies axe-gated 1% crit.
        133: 1628, # inv_axe_02.
    }
    for field, value in axe_fields.items():
        set_u32(data, axe_specialization, field, value)
    set_string(
        data,
        records_end,
        axe_specialization,
        170,
        "Increases your critical strike chance with all spells and abilities by 1% while you have an axe or "
        "a two-handed axe equipped.",
    )
    require_fields(data, axe_specialization, 20574, axe_fields)

    shatter_curse, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 910001, 910001
    )
    shatter_aura, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 910002, 910002
    )

    for record in (shatter_curse, shatter_aura):
        for field in range(71, 131):
            set_u32(data, record, field, 0)

    shatter_fields = {
        4: 16,
        5: 32768,   # Remove auras on immunity.
        28: 1,
        29: 180000,
        40: 0,
        46: 1,
        68: 0xFFFFFFFF,
        71: 64,     # Trigger spell.
        86: 1,
        117: 910002,
        131: 0,
        132: 0,
        133: 542,   # spell_nature_removecurse.
        136: 0,
        205: 133,   # Normal GCD category.
        206: 1500,
        214: 1,
        225: 1,
    }
    for field, value in shatter_fields.items():
        if field != 136:
            set_u32(data, shatter_curse, field, value)
    set_string(data, records_end, shatter_curse, 136, "Shatter Curse")
    set_string(
        data,
        records_end,
        shatter_curse,
        170,
        "Instantly removes and grants immunity to all Curses and Banes, and reduces all Magical damage taken "
        "by 15% for 8 sec.",
    )
    set_string(data, records_end, shatter_curse, 187, "")
    require_fields(data, shatter_curse, 910001, {k: v for k, v in shatter_fields.items() if k != 136})

    aura_fields = {
        4: 0,
        5: 32768,   # Remove auras on immunity.
        28: 1,
        29: 0,
        40: 31,     # Eight seconds in this client's SpellDuration.dbc.
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        72: 38,
        73: 6,
        74: 1,
        75: 1,
        76: 1,
        80: 0xFFFFFFF0, # DBC base points evaluate as value + 1: -15%.
        81: 99,
        82: 0,
        86: 1,
        87: 1,
        88: 1,
        95: 87,     # Mod damage taken percent.
        96: 0,
        97: 41,     # Dispel immunity.
        110: 126,   # Magical schools.
        111: 2,     # Curse.
        112: 2,     # Curse.
        131: 9750,
        132: 0,
        133: 542,   # spell_nature_removecurse.
        205: 0,
        206: 0,
        214: 1,
        225: 32,
    }
    for field, value in aura_fields.items():
        set_u32(data, shatter_aura, field, value)
    set_string(data, records_end, shatter_aura, 136, "Shatter Curse")
    set_string(data, records_end, shatter_aura, 170, "")
    set_string(
        data,
        records_end,
        shatter_aura,
        187,
        "Immune to Curses and Banes. Reduces Magical damage taken by 15%.",
    )
    require_fields(data, shatter_aura, 910002, aura_fields)

    walk_on_air, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 130, 910033
    )
    walk_on_air_aura, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 1706, 910034
    )
    wind_blessed, record_count, records_end = ensure_cloned_record(
        data, record_count, record_size, records_end, 20554, 910035
    )

    for record in (walk_on_air, walk_on_air_aura, wind_blessed):
        for field in range(71, 131):
            set_u32(data, record, field, 0)

    walk_on_air_fields = {
        4: 16,
        5: 0,
        28: 1,
        29: 120000,
        40: 0,
        46: 1,
        68: 0xFFFFFFFF,
        71: 64,     # Trigger spell.
        86: 1,
        117: 910034,
        131: 0,
        132: 0,
        133: 79,    # spell_holy_layonhands.
        205: 133,
        206: 1500,
        214: 1,
        225: 8,
    }
    for field, value in walk_on_air_fields.items():
        set_u32(data, walk_on_air, field, value)
    set_string(data, records_end, walk_on_air, 136, "Walk on Air")
    set_string(data, records_end, walk_on_air, 170, "Glide downward through the air for 10 sec.")
    set_string(data, records_end, walk_on_air, 187, "")
    require_fields(data, walk_on_air, 910033, walk_on_air_fields)

    walk_on_air_aura_fields = {
        4: 0,
        5: 0,
        28: 1,
        29: 0,
        40: 1,      # Ten seconds in this client's SpellDuration.dbc.
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        74: 1,
        80: 0,
        86: 1,
        95: 105,    # Feather fall.
        131: 6768,  # Levitate visual.
        132: 0,
        133: 79,
        205: 0,
        206: 0,
        214: 1,
        225: 8,
    }
    for field, value in walk_on_air_aura_fields.items():
        set_u32(data, walk_on_air_aura, field, value)
    set_string(data, records_end, walk_on_air_aura, 136, "Walk on Air")
    set_string(data, records_end, walk_on_air_aura, 170, "")
    set_string(data, records_end, walk_on_air_aura, 187, "Walking on air.")
    require_fields(data, walk_on_air_aura, 910034, walk_on_air_aura_fields)

    wind_blessed_fields = {
        4: 80,
        5: 0,
        28: 1,
        29: 0,
        40: 21,
        46: 1,
        68: 0xFFFFFFFF,
        71: 6,
        72: 6,
        73: 6,
        74: 1,
        75: 1,
        76: 1,
        80: 0,
        81: 0,
        82: 0,
        86: 1,
        87: 1,
        88: 1,
        95: 138,    # Melee haste.
        96: 140,    # Ranged haste.
        97: 216,    # Spell haste.
        131: 0,
        132: 0,
        133: 136,   # spell_nature_windfury.
        205: 0,
        206: 0,
        214: 0,
        225: 8,
    }
    for field, value in wind_blessed_fields.items():
        set_u32(data, wind_blessed, field, value)
    set_string(data, records_end, wind_blessed, 136, "Wind Blessed")
    set_string(data, records_end, wind_blessed, 170, "Increases your spellcasting, melee, and ranged Haste by 1%.")
    set_string(data, records_end, wind_blessed, 187, "")
    require_fields(data, wind_blessed, 910035, wind_blessed_fields)

    path.write_bytes(data)


def patch_skill_line_ability(path: Path):
    data, record_count, record_size, records_end = read_wdbc(path, 14, 56)

    for index in range(record_count - 1, -1, -1):
        offset = 20 + index * record_size
        record = struct.unpack_from("<14I", data, offset)
        ability_id = record[0]
        spell_id = record[2]
        if ability_id in {910002, 910016, 910034} or spell_id in {910002, 910016, 910034}:
            del data[offset:offset + record_size]
            record_count -= 1
            records_end -= record_size
        elif record[3] == 64 and spell_id == 20591 and record[4] != 400:
            fields = list(record)
            fields[4] = 400
            struct.pack_into("<14I", data, offset, *fields)
        elif spell_id == 26290 or (spell_id == 20554 and ability_id != 13418):
            del data[offset:offset + record_size]
            record_count -= 1
            records_end -= record_size
        elif record[3] == 16 and spell_id in {20579, 17737}:
            del data[offset:offset + record_size]
            record_count -= 1
            records_end -= record_size
        elif record[3] == 4 and spell_id in {20595, 20596, 59224}:
            del data[offset:offset + record_size]
            record_count -= 1
            records_end -= record_size
        elif record[3] == 64 and spell_id == 20592:
            del data[offset:offset + record_size]
            record_count -= 1
            records_end -= record_size
        elif (record[0] == 910030 and spell_id == 20600) or (record[3] == 1 and spell_id in {20599, 20864,
            58985, 59752}):
            del data[offset:offset + record_size]
            record_count -= 1
            records_end -= record_size
        elif record[3] == 8 and spell_id in {20583, 58984, 21009}:
            del data[offset:offset + record_size]
            record_count -= 1
            records_end -= record_size
        elif (910003 <= ability_id <= 910022 and ability_id not in {910013, 910017, 910018, 910019, 910020,
            910021}) or (
            910003 <= spell_id <= 910022 and spell_id not in {910013, 910017, 910018, 910019, 910020, 910021}
        ) or (910023 <= ability_id <= 910028 and ability_id not in {910023, 910024, 910025, 910026, 910027,
            910028}) or (
            910023 <= spell_id <= 910028 and spell_id not in {910023, 910024, 910025, 910026, 910027, 910028}
        ) or (ability_id == 910029 and spell_id != 910029) or (
            spell_id == 910029 and ability_id != 910029
        ) or (910031 <= spell_id <= 910032 and spell_id != 910031) or (
            910031 <= ability_id <= 910032
        ) or (910033 <= ability_id <= 910037 and ability_id not in {910033, 910035, 910036, 910037}) or (
            spell_id in {910034}
        ):
            del data[offset:offset + record_size]
            record_count -= 1
            records_end -= record_size

    plainsrunning_found = False
    berserking_found = False
    rapid_regeneration_found = False
    touch_melee_found = False
    touch_caster_found = False
    stoneform_record = None
    big_game_found = False
    mace_specialization_found = False
    escape_artist_record = None
    gnome_custom_found = set()
    human_source_record = None
    perception_found = False
    will_to_survive_found = False
    night_elf_source_record = None
    shadowmeld_found = False
    elunes_light_found = False
    blood_elf_source_record = None
    draenei_source_record = None
    blood_elf_custom_found = set()
    draenei_custom_found = set()
    cultivation_record = None
    regeneration_record = None
    cannibalize_record = None
    for index in range(record_count):
        offset = 20 + index * record_size
        record = struct.unpack_from("<14I", data, offset)
        if record[2] == 20552 and record[1] == 124 and record[3] == 32:
            cultivation_record = offset
        if record[2] == 20555 and record[1] == 733 and record[3] == 128:
            regeneration_record = offset
        if record[2] == 20577 and record[1] == 220 and record[3] == 16:
            cannibalize_record = offset
        if record[2] == 20594 and record[1] == 101 and record[3] == 4:
            stoneform_record = offset
        if record[2] == 20589 and record[1] == 753 and record[3] == 64:
            escape_artist_record = offset
        if record[2] == 20598 and record[1] == 754 and record[3] == 1:
            human_source_record = offset
        if record[2] == 20582 and record[1] == 126 and record[3] == 8:
            night_elf_source_record = offset
        if record[2] == 822 and record[1] == 756 and record[3] in {0, 512}:
            blood_elf_source_record = offset
        if record[2] == 28875 and record[1] == 760 and record[3] in {0, 1024}:
            draenei_source_record = offset
        if record[2] == 20600 and record[1] == 754 and record[3] == 1:
            perception_found = True
        if record[2] == 910013 and record[1] == 124 and record[3] == 32:
            plainsrunning_found = True
        if record[2] == 20554 and record[1] == 733 and record[3] == 128:
            berserking_found = True
        if record[2] == 910017 and record[1] == 733 and record[3] == 128:
            rapid_regeneration_found = True
        if record[2] == 910018 and record[1] == 220 and record[3] == 16 and record[4] == 11:
            touch_melee_found = True
        if record[2] == 910019 and record[1] == 220 and record[3] == 16 and record[4] == 400:
            touch_caster_found = True
        if record[2] == 910020 and record[1] == 101 and record[3] == 4:
            big_game_found = True
        if record[2] == 910021 and record[1] == 101 and record[3] == 4:
            mace_specialization_found = True
        if record[2] in {910023, 910024, 910025, 910026, 910027, 910028} and record[1] == 753 and record[3] == 64:
            gnome_custom_found.add(record[2])
        if record[2] == 910029 and record[1] == 754 and record[3] == 1:
            will_to_survive_found = True
        if record[2] == 20580 and record[1] == 126 and record[3] == 8:
            shadowmeld_found = True
        if record[2] == 910031 and record[1] == 126 and record[3] == 8:
            elunes_light_found = True
        if record[2] in {910033, 910035} and record[1] == 756 and record[3] == 512:
            blood_elf_custom_found.add(record[2])
        if record[2] in {910033, 910035} and record[1] == 760 and record[3] == 1024:
            draenei_custom_found.add(record[2])

    if not plainsrunning_found:
        if cultivation_record is None:
            raise ValueError(f"{path}: missing Cultivation record to clone for Plainsrunning")

        clone = bytes(data[cultivation_record:cultivation_record + record_size])
        data[records_end:records_end] = clone
        plainsrunning_record = records_end
        record_count += 1
        records_end += record_size
        struct.pack_into("<I", data, 4, record_count)
        fields = list(struct.unpack_from("<14I", data, plainsrunning_record))
        fields[0] = 910013
        fields[2] = 910013
        struct.pack_into("<14I", data, plainsrunning_record, *fields)

    for ability_id, spell_id, found in ((13418, 20554, berserking_found), (910017, 910017, rapid_regeneration_found)):
        if found:
            continue

        if regeneration_record is None:
            raise ValueError(f"{path}: missing Regeneration record to clone for Troll racial {spell_id}")

        clone = bytes(data[regeneration_record:regeneration_record + record_size])
        data[records_end:records_end] = clone
        troll_record = records_end
        record_count += 1
        records_end += record_size
        struct.pack_into("<I", data, 4, record_count)
        fields = list(struct.unpack_from("<14I", data, troll_record))
        fields[0] = ability_id
        fields[2] = spell_id
        struct.pack_into("<14I", data, troll_record, *fields)

    for ability_id, spell_id, class_mask, found in (
        (910018, 910018, 11, touch_melee_found),
        (910019, 910019, 400, touch_caster_found),
    ):
        if found:
            continue

        if cannibalize_record is None:
            raise ValueError(f"{path}: missing Cannibalize record to clone for Touch of the Grave")

        clone = bytes(data[cannibalize_record:cannibalize_record + record_size])
        data[records_end:records_end] = clone
        touch_record = records_end
        record_count += 1
        records_end += record_size
        struct.pack_into("<I", data, 4, record_count)
        fields = list(struct.unpack_from("<14I", data, touch_record))
        fields[0] = ability_id
        fields[2] = spell_id
        fields[4] = class_mask
        struct.pack_into("<14I", data, touch_record, *fields)

    for ability_id, spell_id, found in (
        (910020, 910020, big_game_found),
        (910021, 910021, mace_specialization_found),
    ):
        if found:
            continue

        if stoneform_record is None:
            raise ValueError(f"{path}: missing Stoneform record to clone for Dwarf racial {spell_id}")

        clone = bytes(data[stoneform_record:stoneform_record + record_size])
        data[records_end:records_end] = clone
        dwarf_record = records_end
        record_count += 1
        records_end += record_size
        struct.pack_into("<I", data, 4, record_count)
        fields = list(struct.unpack_from("<14I", data, dwarf_record))
        fields[0] = ability_id
        fields[2] = spell_id
        fields[4] = 0
        struct.pack_into("<14I", data, dwarf_record, *fields)

    for ability_id, spell_id, class_mask in (
        (910023, 910023, 1),
        (910024, 910024, 8),
        (910025, 910025, 8),
        (910026, 910026, 1),
        (910027, 910027, 256),
        (910028, 910028, 16),
    ):
        if spell_id in gnome_custom_found:
            continue

        if escape_artist_record is None:
            raise ValueError(f"{path}: missing Escape Artist record to clone for Gnome racial {spell_id}")

        clone = bytes(data[escape_artist_record:escape_artist_record + record_size])
        data[records_end:records_end] = clone
        gnome_record = records_end
        record_count += 1
        records_end += record_size
        struct.pack_into("<I", data, 4, record_count)
        fields = list(struct.unpack_from("<14I", data, gnome_record))
        fields[0] = ability_id
        fields[2] = spell_id
        fields[4] = class_mask
        struct.pack_into("<14I", data, gnome_record, *fields)

    for ability_id, spell_id, found in (
        (910030, 20600, perception_found),
        (910029, 910029, will_to_survive_found),
    ):
        if found:
            continue

        if human_source_record is None:
            raise ValueError(f"{path}: missing The Human Spirit record to clone for Human racial {spell_id}")

        clone = bytes(data[human_source_record:human_source_record + record_size])
        data[records_end:records_end] = clone
        human_record = records_end
        record_count += 1
        records_end += record_size
        struct.pack_into("<I", data, 4, record_count)
        fields = list(struct.unpack_from("<14I", data, human_record))
        fields[0] = ability_id
        fields[2] = spell_id
        fields[4] = 0
        struct.pack_into("<14I", data, human_record, *fields)

    for ability_id, spell_id, found in (
        (1259800, 20580, shadowmeld_found),
        (1259799, 910031, elunes_light_found),
    ):
        if found:
            continue

        if night_elf_source_record is None:
            raise ValueError(f"{path}: missing Quickness record to clone for Night Elf racial {spell_id}")

        clone = bytes(data[night_elf_source_record:night_elf_source_record + record_size])
        data[records_end:records_end] = clone
        night_elf_record = records_end
        record_count += 1
        records_end += record_size
        struct.pack_into("<I", data, 4, record_count)
        fields = list(struct.unpack_from("<14I", data, night_elf_record))
        fields[0] = ability_id
        fields[2] = spell_id
        fields[4] = 0
        struct.pack_into("<14I", data, night_elf_record, *fields)

    for ability_id, spell_id, race_mask, skill_line, source_record, found in (
        (910033, 910033, 512, 756, blood_elf_source_record, 910033 in blood_elf_custom_found),
        (910035, 910035, 512, 756, blood_elf_source_record, 910035 in blood_elf_custom_found),
        (910036, 910033, 1024, 760, draenei_source_record, 910033 in draenei_custom_found),
        (910037, 910035, 1024, 760, draenei_source_record, 910035 in draenei_custom_found),
    ):
        if found:
            continue

        if source_record is None:
            raise ValueError(f"{path}: missing source record to clone for Skyborne-style racial {spell_id}")

        clone = bytes(data[source_record:source_record + record_size])
        data[records_end:records_end] = clone
        custom_record = records_end
        record_count += 1
        records_end += record_size
        struct.pack_into("<I", data, 4, record_count)
        fields = list(struct.unpack_from("<14I", data, custom_record))
        fields[0] = ability_id
        fields[1] = skill_line
        fields[2] = spell_id
        fields[3] = race_mask
        fields[4] = 0
        struct.pack_into("<14I", data, custom_record, *fields)

    struct.pack_into("<I", data, 4, record_count)
    path.write_bytes(data)


def validate_skill_line_ability(path: Path):
    data, record_count, record_size, _ = read_wdbc(path, 14, 56)
    expected = {
        (125, 2, 20572),
        (125, 2, 20573),
        (125, 2, 20574),
        (125, 2, 910001),
        (124, 32, 20549),
        (124, 32, 20550),
        (124, 32, 20552),
        (124, 32, 910013),
        (733, 128, 20554),
        (733, 128, 20555),
        (733, 128, 20557),
        (733, 128, 910017),
        (220, 16, 7744),
        (220, 16, 20577),
        (220, 16, 5227),
        (220, 16, 910018),
        (220, 16, 910019),
        (101, 4, 2481),
        (101, 4, 20594),
        (101, 4, 910020),
        (101, 4, 910021),
        (753, 64, 20589),
        (753, 64, 20591),
        (753, 64, 20593),
        (753, 64, 910023),
        (753, 64, 910024),
        (753, 64, 910025),
        (753, 64, 910026),
        (753, 64, 910027),
        (753, 64, 910028),
        (754, 1, 20597),
        (754, 1, 20598),
        (754, 1, 20600),
        (754, 1, 910029),
        (126, 8, 20580),
        (126, 8, 20582),
        (126, 8, 20585),
        (126, 8, 910031),
        (756, 512, 25046),
        (756, 0, 28730),
        (756, 0, 822),
        (756, 0, 50613),
        (756, 512, 910033),
        (756, 512, 910035),
        (760, 1024, 6562),
        (760, 1024, 28880),
        (760, 0, 28875),
        (760, 1024, 910033),
        (760, 1024, 910035),
    }
    found = set()
    forbidden_custom = set()

    for index in range(record_count):
        offset = 20 + index * record_size
        record = struct.unpack_from("<14I", data, offset)
        spell_id = record[2]
        key = (record[1], record[3], spell_id)
        if key in expected:
            found.add(key)
        if spell_id == 26290:
            forbidden_custom.add(spell_id)
        if record[3] == 16 and spell_id in {20579, 17737}:
            forbidden_custom.add(spell_id)
        if record[3] == 4 and spell_id in {20595, 20596, 59224}:
            forbidden_custom.add(spell_id)
        if record[3] == 64 and spell_id == 20592:
            forbidden_custom.add(spell_id)
        if record[3] == 1 and spell_id in {20599, 20864, 58985, 59752}:
            forbidden_custom.add(spell_id)
        if record[3] == 8 and spell_id in {20583, 58984, 21009}:
            forbidden_custom.add(spell_id)
        if 910002 <= spell_id <= 910022 and spell_id not in {910013, 910017, 910018, 910019, 910020, 910021}:
            forbidden_custom.add(spell_id)
        if 910023 <= spell_id <= 910028 and spell_id not in {910023, 910024, 910025, 910026, 910027, 910028}:
            forbidden_custom.add(spell_id)
        if 910031 <= spell_id <= 910032 and spell_id != 910031:
            forbidden_custom.add(spell_id)
        if spell_id == 910034:
            forbidden_custom.add(spell_id)

    missing = expected - found
    if missing:
        raise ValueError(f"{path}: missing WoW Forever racial spells: {sorted(missing)}")
    if forbidden_custom:
        raise ValueError(f"{path}: extra custom racial spells must not be exposed: {sorted(forbidden_custom)}")


def main():
    parser = argparse.ArgumentParser(description="Generate synchronized WoW Forever racial DBC records.")
    parser.add_argument(
        "--dbc-dir",
        type=Path,
        default=Path(__file__).resolve().parent / "DBFilesClient",
        help="Directory containing Spell.dbc and SkillLineAbility.dbc",
    )
    args = parser.parse_args()

    spell_path = args.dbc_dir / "Spell.dbc"
    skill_line_path = args.dbc_dir / "SkillLineAbility.dbc"
    patch_spell_dbc(spell_path)
    patch_skill_line_ability(skill_line_path)
    validate_skill_line_ability(skill_line_path)
    print(f"Generated {spell_path}")
    print(f"Validated {skill_line_path}")


if __name__ == "__main__":
    main()

# Racial compatibility audit

Checked the 84 race/class creation templates against server `SkillLineAbility.dbc` plus the live
`skilllineability_dbc` overrides, `playercreateinfo_skills`, `playercreateinfo_spell_custom`, server
`SkillRaceClassInfo.dbc`, generated client `SkillLineAbility.dbc`, and `EnsureRacials` in
`src/server/scripts/Spells/spell_racial.cpp`. There are 74 ordinary combinations in `CharBaseInfo.dbc`
and ten Death Knight combinations, which use the client's separate hero-class creation path.

## Corrections applied

| Race/classes | Finding | Correction |
| --- | --- | --- |
| Orc Priest/Mage | Caster Blood Fury excluded these classes in its racial learning record | Class mask 400 in server and client; `rev_1791253303056472029.sql` |
| Draenei Rogue | Missing Heroic Presence, Gift of the Naaru, and Shadow Resistance | Extend the physical variants to Rogue |
| Draenei Warlock | Missing Heroic Presence, Gift of the Naaru, and Shadow Resistance | Extend the caster variants to Warlock |
| Dwarf | Retired Frost Resistance remained learnable on the server | Disable original learning record 11725 |
| Night Elf | Retired Nature Resistance and Elusiveness remained learnable on the server | Disable original learning records 11717 and 20665 |
| Undead | Retired Shadow Resistance remained learnable on the server | Disable original learning record 11714 |

The last five corrections are in `rev_1791253684952831587.sql`. The retired passives were already
deliberately removed from the client by the custom racial generator. Disabling the server records
preserves that design. No persisted `character_spell` rows for those race/spell pairs were found at
the time of the audit; dependent skill spells are recalculated at login.

The Draenei Rogue uses the existing physical Hunter variants (`59543`, `59536`), and the Draenei
Warlock uses the existing Mage variants (`59548`, `59541`). Heroic Presence remains physical (`6562`)
or caster (`28878`) as appropriate. Existing classes retain their variants. New characters receive
Gift of the Naaru on their initial action bars; existing characters learn it when their racial skill
loads at login and can place it on their bars manually.

After these changes, all 84 combinations pass the racial skill eligibility checks and the comparison
of server-granted racials against client racial classification. None of the client's automatically
learned racial records lack corresponding server learning data. This comparison alone cannot detect
a racial absent from both sides, so class-specific families were also reviewed.

## Remaining coverage gaps

| Combination | Gap | Required work |
| --- | --- | --- |
| Blood Elf Warrior | No Arcane Torrent variant covers Warrior | Define a rage-compatible variant; existing variants restore mana, energy, or runic power |
| Undead Hunter | Neither Touch of the Grave variant includes Hunter | Decide the Hunter variant and extend SQL, client learning masks, and the C++ login/proc handling |

For Undead Hunters, merely teaching `910018` or `910019` is insufficient: `EnsureRacials` explicitly
removes both for classes outside its existing melee/caster lists. Applying a C++ change requires a
build, which must be explicitly requested under AGENTS.md. The existing Death Knight exclusion uses
the same logic. These are coverage gaps in the current design, not resolved by the data corrections.

Gnome Eureka is explicitly implemented for Warrior, Rogue, Priest, and Warlock. Hunter, Mage, and
Death Knight do not have an assigned Eureka variant. This audit preserves that class-specific design;
their Expansive Mind variants and other configured racials match between server and client.

## Validation limits

The audit checks data eligibility and synchronization; it does not establish correct in-game effects,
tooltips, VFX, or proc behavior for every class. Generated racial records passed the generator's
validation and idempotence checks, and the installed MPQ records were extracted and compared with
the generated DBC. The SQL linter reported no errors in the new updates but still fails on pre-existing
issues in other pending SQL files. No C++ build was performed.

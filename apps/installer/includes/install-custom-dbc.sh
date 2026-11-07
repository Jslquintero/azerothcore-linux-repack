#!/usr/bin/env bash
set -euo pipefail

# Install the versioned server data after downloading stock client data, including
# when the stock data version is already current. No DBC generation is needed.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source_dir="$repo_root/client-patches/DBFilesClient"
destination="${1:?Usage: install-custom-dbc.sh DATA_DIRECTORY}/dbc"
files=(CharBaseInfo CharStartOutfit Item SkillLineAbility SkillRaceClassInfo Spell SpellVisual SpellVisualKit)

# Validate the complete source set before changing the installed files.
for name in "${files[@]}"; do
    if [[ ! -s "$source_dir/$name.dbc" ]]; then
        echo "Missing custom DBC: $source_dir/$name.dbc" >&2
        exit 1
    fi
done

mkdir -p "$destination"
for name in "${files[@]}"; do
    cp "$source_dir/$name.dbc" "$destination/$name.dbc"
done
echo "Installed custom DBC files in $destination"

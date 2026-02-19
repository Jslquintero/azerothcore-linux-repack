#!/bin/bash
echo "=== Running module SQL scripts ==="

cd azerothcore-wotlk

# Check that the container is running
if ! docker compose ps | grep -q "ac-database.*Up"; then
    echo "Error: ac-database container is not running"
    echo "Run first: docker compose up -d --build"
    exit 1
fi

echo "Waiting for the database to be ready..."
sleep 5

echo "Applying mod-ah-bot SQL..."
docker exec -i ac-database mysql -uroot -ppassword acore_world < modules/mod-ah-bot/data/sql/db-world/mod_auctionhousebot.sql 2>/dev/null
docker exec -i ac-database mysql -uroot -ppassword acore_world < modules/mod-ah-bot/data/sql/db-world/auctionhousebot_professionItems.sql 2>/dev/null
docker exec -i ac-database mysql -uroot -ppassword acore_world < modules/mod-ah-bot/data/sql/db-world/z_filter_disabled_and_trash.sql 2>/dev/null

echo "Applying mod-transmog SQL..."
docker exec -i ac-database mysql -uroot -ppassword acore_characters < modules/mod-transmog/data/sql/db-characters/trasmorg.sql 2>/dev/null
docker exec -i ac-database mysql -uroot -ppassword acore_world < modules/mod-transmog/data/sql/db-world/trasm_world_NPC.sql 2>/dev/null
docker exec -i ac-database mysql -uroot -ppassword acore_world < modules/mod-transmog/data/sql/db-world/trasm_world_VendorItems.sql 2>/dev/null
docker exec -i ac-database mysql -uroot -ppassword acore_world < modules/mod-transmog/data/sql/db-world/trasm_world_texts.sql 2>/dev/null

echo "Applying mod-individual-progression SQL (this may take a moment)..."
for sql in modules/mod-individual-progression/data/sql/world/base/*.sql; do
  docker exec -i ac-database mysql -uroot -ppassword acore_world < "$sql" 2>/dev/null
done

echo "Applying mod-aoe-loot SQL..."
docker exec -i ac-database mysql -uroot -ppassword acore_world < modules/mod-aoe-loot/data/sql/db-world/base/aoe_loot_acore_string.sql 2>/dev/null

echo "Applying mod-npc-buffer SQL..."
docker exec -i ac-database mysql -uroot -ppassword acore_world < modules/mod-npc-buffer/data/sql/db-world/npc_buffer.sql 2>/dev/null

echo "Applying mod-reagent-bank SQL..."
docker exec -i ac-database mysql -uroot -ppassword acore_characters < modules/mod-reagent-bank/data/sql/db-characters/base/create_table.sql 2>/dev/null
docker exec -i ac-database mysql -uroot -ppassword acore_world < modules/mod-reagent-bank/data/sql/db-world/base/reagent_bank_NPC.sql 2>/dev/null

echo "Applying mod-player-bot-level-brackets SQL..."
docker exec -i ac-database mysql -uroot -ppassword acore_characters < modules/mod-player-bot-level-brackets/data/sql/characters/base/2025_07_31_bot_level_brackets_guild_tracker.sql 2>/dev/null

echo "Restarting server to apply changes..."
docker compose restart ac-worldserver

echo ""
echo "=== Done! ==="
echo ""
echo "The server will be available in a few seconds."
echo "To create an account:"
echo "  docker attach ac-worldserver"
echo "  account create username password"
echo "  account set gmlevel username 3 -1"
echo ""
echo "Exit the console: Ctrl+P, Ctrl+Q"

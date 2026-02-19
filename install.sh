#!/bin/bash
echo "=== AzerothCore Repack with Playerbots + Modules ==="

# Cloning fork
git clone https://github.com/mod-playerbots/azerothcore-wotlk.git --branch=Playerbot --depth 1
cd azerothcore-wotlk/modules

# Cloning modules
echo "Cloning modules..."
git clone https://github.com/mod-playerbots/mod-playerbots.git --branch=master --depth 1
git clone https://github.com/ZhengPeiRu21/mod-individual-progression.git --depth 1
git clone https://github.com/azerothcore/mod-autobalance.git --depth 1
git clone https://github.com/azerothcore/mod-transmog.git --depth 1
git clone https://github.com/azerothcore/mod-ah-bot.git --depth 1
git clone https://github.com/azerothcore/mod-learn-spells.git --depth 1
git clone https://github.com/azerothcore/mod-aoe-loot.git --depth 1
git clone https://github.com/azerothcore/mod-account-achievements.git --depth 1
git clone https://github.com/noisiver/mod-junk-to-gold.git --depth 1
git clone https://github.com/ZhengPeiRu21/mod-leech.git --depth 1
git clone https://github.com/BytesGalore/mod-no-hearthstone-cooldown.git --depth 1
git clone https://github.com/ZhengPeiRu21/mod-reagent-bank.git --depth 1
git clone https://github.com/azerothcore/mod-account-mounts.git --depth 1
git clone https://github.com/DustinHendrickson/mod-player-bot-level-brackets.git --depth 1
git clone https://github.com/dunjeon/mod-TimeIsTime.git --depth 1

cd ..

# Copy docker configuration
cp ../docker-compose.override.yml .

echo "=== Instalation completed ==="
echo ""
echo "Next step:"
echo "  cd azerothcore-wotlk && docker compose up -d --build"
echo ""
echo "After the server starts (20-40 min first time):"
echo "  cd .. && ./setup-sql.sh"

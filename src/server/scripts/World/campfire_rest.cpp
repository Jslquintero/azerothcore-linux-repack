/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 * This program is free software; see the LICENSE file for details.
 */

#include "GameObject.h"
#include "Player.h"
#include "ScriptMgr.h"

#include <algorithm>
#include <unordered_map>

namespace
{
constexpr uint32 GO_BASIC_CAMPFIRE = 29784;
constexpr uint32 CAMPFIRE_CHECK_INTERVAL = 1000;
constexpr uint32 CAMPFIRE_REST_DELAY = 60000;
constexpr float CAMPFIRE_REST_DISTANCE = 7.0f;
constexpr float MINIMUM_CAMPFIRE_REST_BONUS = 11.0f;

struct CampfireRestState
{
    uint32 checkTimer = 0;
    uint32 timeNearCampfire = 0;
    bool nearCampfire = false;
};
}

class player_campfire_rest : public PlayerScript
{
public:
    player_campfire_rest() : PlayerScript("player_campfire_rest") { }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        ObjectGuid const guid = player->GetGUID();
        CampfireRestState& state = _restStates[guid];
        if (state.nearCampfire)
            state.timeNearCampfire = std::min(state.timeNearCampfire + diff, CAMPFIRE_REST_DELAY);

        if (state.checkTimer > diff)
        {
            state.checkTimer -= diff;
            ApplyRestedState(player, state);
            return;
        }

        state.checkTimer = CAMPFIRE_CHECK_INTERVAL;
        state.nearCampfire = player->FindNearestGameObject(GO_BASIC_CAMPFIRE, CAMPFIRE_REST_DISTANCE) != nullptr;
        if (!state.nearCampfire)
        {
            state.timeNearCampfire = 0;
            player->RemoveRestFlag(REST_FLAG_NEAR_CAMPFIRE);
        }

        ApplyRestedState(player, state);
    }

    void OnPlayerLogout(Player* player) override
    {
        _restStates.erase(player->GetGUID());
        player->RemoveRestFlag(REST_FLAG_NEAR_CAMPFIRE);
    }

private:
    static void ApplyRestedState(Player* player, CampfireRestState const& state)
    {
        if (!state.nearCampfire || state.timeNearCampfire < CAMPFIRE_REST_DELAY)
            return;

        player->SetRestFlag(REST_FLAG_NEAR_CAMPFIRE);
        if (player->GetRestBonus() < MINIMUM_CAMPFIRE_REST_BONUS)
            player->SetRestBonus(MINIMUM_CAMPFIRE_REST_BONUS);
    }

    std::unordered_map<ObjectGuid, CampfireRestState> _restStates;
};

void AddSC_campfire_rest()
{
    new player_campfire_rest();
}

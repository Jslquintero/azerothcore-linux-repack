/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#include "RacialsStrategy.h"

#include "Playerbots.h"

void RacialsStrategy::InitTriggers(std::vector<TriggerNode*>& triggers)
{
    // Cultivation replaced Lifeblood for Taurens. Lifeblood and Gift of the Naaru
    // must not be treated as interchangeable racial actions.
    triggers.push_back(new TriggerNode(
        "low health", { NextAction("rapid regeneration", ACTION_NORMAL + 6) }));
    triggers.push_back(
        new TriggerNode("self cursed", { NextAction("shatter curse", ACTION_HIGH + 5) }));
    triggers.push_back(new TriggerNode(
        "medium aoe", { NextAction("war stomp", ACTION_NORMAL + 5) }));
    triggers.push_back(new TriggerNode(
        "low mana", { NextAction("arcane torrent", ACTION_NORMAL + 5) }));

    // Offensive racials are used with the existing generic damage cooldowns.
    // Elune's Light is the Night Elf replacement active and grants a short crit buff.
    triggers.push_back(new TriggerNode(
        "generic boost", { NextAction("blood fury", ACTION_NORMAL + 5),
                           NextAction("berserking", ACTION_NORMAL + 5),
                           NextAction("elune's light", ACTION_NORMAL + 5),
                           NextAction("use trinket", ACTION_NORMAL + 4) }));
}

RacialsStrategy::RacialsStrategy(PlayerbotAI* botAI) : Strategy(botAI)
{
}

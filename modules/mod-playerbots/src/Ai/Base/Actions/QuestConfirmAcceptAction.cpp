#include "QuestConfirmAcceptAction.h"

#include "QuestPackets.h"
#include "WorldPacket.h"

bool QuestConfirmAcceptAction::Execute(Event event)
{
    WorldPacket packet(event.getPacket());
    uint32 questId;
    packet >> questId;

    WorldPacket sendPacket(CMSG_QUEST_CONFIRM_ACCEPT, 4);
    sendPacket << questId;
    WorldPackets::Quest::QuestConfirmAcceptClient packetWrapper(std::move(sendPacket));
    packetWrapper.Read();
    Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
    if (!quest || !bot->CanAddQuest(quest, true))
    {
        return false;
    }
    std::ostringstream out;
    out << "Quest: " << chat->FormatQuest(quest) << " confirm accept";
    botAI->TellMaster(out);
    bot->GetSession()->HandleQuestConfirmAccept(packetWrapper);
    return true;
}

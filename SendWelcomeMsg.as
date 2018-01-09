#define SERVER_ONLY
#include "WelcomeMsg.as";

void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player) {
    if ((player is null) || (blob is null))
        return;

    if (player.hasTag("shown_help"))
        return;

    if (blob.hasCommandID("send_chat"))
    {
        printf("onSetPlayer. sending chat");
        send_chat(blob, WELCOME_MSG, WELCOME_COLOR);
        player.Tag("shown_help");
    }
    else
        printf("WARNING: no send_chat command ID found");
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player) {
    printf("onNewPlayerJoin called");
}

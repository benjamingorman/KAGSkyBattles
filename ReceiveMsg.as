void onInit(CBlob@ this)
{
    printf("ReceiveMsg onInit called.");
    this.addCommandID("send_chat");
}

void onCommand( CBlob@ this, u8 cmd, CBitStream@ params )
{
    //printf("onCommand called!");
    if(cmd == this.getCommandID("send_chat") && !getNet().isServer())
    {
        //printf("commandID is send_chat!");
        u16 netID = params.read_netid();
        u8 r = params.read_u8();
        u8 g = params.read_u8();
        u8 b = params.read_u8();
        string text = params.read_string();
        if((this.getNetworkID() == netID) && (this.getPlayer() !is null) && this.getPlayer().isMyPlayer())
        {
            client_AddToChat(text, SColor(255,r,g,b));
        }
    }
}

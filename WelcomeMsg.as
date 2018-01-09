const string WELCOME_MSG = (
        "Welcome to Skybattles! Instructions:\n" +
        " - Bombers have 2 seats for flyers and 1 seat for a gunner.\n" +
        " - To fly a bomber hold left mouse to go up and right mouse to go down. Use A and D to go left and right.\n" +
        " - When flying you can also press E to fire a bomb!\n" +
        " - When gunning you can turn the catapult arm using A and D.\n" +
        " - There is a parachute in your inventory which will slow your fall!"
        )
    ;
const SColor WELCOME_COLOR = SColor(255,0,0,255);

void send_chat(CBlob@ blob, string x, SColor color) {
    if(blob is null)
    {
        printf("blob is null");
        return;
    }

    CBitStream params;
    params.write_netid(blob.getNetworkID());
    params.write_u8(color.getRed());
    params.write_u8(color.getGreen());
    params.write_u8(color.getBlue());
    params.write_string(x);
    blob.SendCommand(blob.getCommandID("send_chat"), params);
}

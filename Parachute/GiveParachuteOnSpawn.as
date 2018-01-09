#define SERVER_ONLY

void onInit(CBlob@ this)
{
    CBlob@ parachute = server_CreateBlob("parachute", this.getTeamNum(), this.getPosition());
    if (parachute !is null)
    {
        if (!this.server_PutInInventory(parachute))
            parachute.server_Die();
    }
}

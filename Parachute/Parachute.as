const float PARACHUTE_SLOW_FACTOR = 2.5f; // multiplied by sv_gravity to slow fall

void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_attached;
    this.getShape().SetGravityScale(0.1f);
    this.set_netid("carrier", 0);
    this.SetInventoryIcon("ParachuteInventoryIcon.png", 0, Vec2f(15,13));
}

void onTick(CBlob@ this)
{
    uint16 carrier_netid = this.get_netid("carrier");
    if (carrier_netid == 0)
        return;
    else 
    {
        CBlob@ carrier_blob = getBlobByNetworkID(carrier_netid);
        if (carrier_blob is null)
        {
            printf("WARNING: parachute carrier blob is null!");
            return;
        }
        else
        {
            if((!carrier_blob.isOnGround()) && carrier_blob.getVelocity().y > 0)
            {
                //printf("Adding parachute force...");
                carrier_blob.AddForce(Vec2f(0, -sv_gravity*PARACHUTE_SLOW_FACTOR));
            }
        }
    }
}

void onAttach(CBlob@ this, CBlob@ blob, AttachmentPoint @attachedPoint)
{
    //printf("Parachute onAttach: " + this.getName() + " " + blob.getName());
    this.set_netid("carrier", blob.getNetworkID());
    blob.setVelocity(Vec2f(blob.getVelocity().x, 0)); // set y vel to 0
    this.getSprite().PlaySound("ParachuteDeploy.ogg");
}

void onDetach(CBlob@ this, CBlob@ blob, AttachmentPoint @attachedPoint)
{
    this.set_netid("carrier", 0);
}

void onInit(CSprite@ this)
{
    printf("Parachute Sprite onInit called");
    this.SetZ(-10.0f);
    this.SetRelativeZ(-10.0f);
}

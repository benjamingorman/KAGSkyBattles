#include "VehicleCommon.as"
#include "Hitters.as"
#include "Knocked.as"

const u8 cata_baseline_charge = 15;

const u8 cata_charge_contrib = 35;

const u8 cata_cooldown_time = 45;
const u16 cata_startStone = 6000;

const u16 BOMBING_INTERVAL_TICKS = 70;
const float RAM_PLAYER_DAMAGE_MOD = 0.1f; // reduce the damage when ramming players so we don't 1 shot them

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
	              58.0f, // move speed
	              0.60f,  // turn speed
	              Vec2f(0.0f, -6.0f), // jump out velocity
	              false  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_SetupAirship(this, v, -310.0f);

	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));

	this.set_f32("map dmg modifier", 35.0f);
    this.set_f32("hit dmg modifier", 0.05f);

	//this.getShape().SetOffset(Vec2f(0,0));
	//  this.getShape().getConsts().bullet = true;
//	this.getShape().getConsts().transports = true;

	CSprite@ sprite = this.getSprite();

	// add balloon

	CSpriteLayer@ balloon = sprite.addSpriteLayer("balloon", "Balloon.png", 48, 64);
	if (balloon !is null)
	{
		balloon.addAnimation("default", 0, false);
		int[] frames = { 0, 2, 3 };
		balloon.animation.AddFrames(frames);
		balloon.SetRelativeZ(-0.1f);
		balloon.SetOffset(Vec2f(0.0f, -38.0f));
	}

	CSpriteLayer@ background = sprite.addSpriteLayer("background", "Balloon.png", 32, 16);
	if (background !is null)
	{
		background.addAnimation("default", 0, false);
		int[] frames = { 3 };
		background.animation.AddFrames(frames);
		background.SetRelativeZ(-5.0f);
		background.SetOffset(Vec2f(0.0f, -17.0f));
	}

	CSpriteLayer@ burner = sprite.addSpriteLayer("burner", "Balloon.png", 8, 16);
	if (burner !is null)
	{
		{
			Animation@ a = burner.addAnimation("default", 3, true);
			int[] frames = { 41, 42, 43 };
			a.AddFrames(frames);
		}
		{
			Animation@ a = burner.addAnimation("up", 3, true);
			int[] frames = { 38, 39, 40 };
			a.AddFrames(frames);
		}
		{
			Animation@ a = burner.addAnimation("down", 3, true);
			int[] frames = { 44, 45, 44, 46 };
			a.AddFrames(frames);
		}
		burner.SetRelativeZ(-0.05f);
		burner.SetOffset(Vec2f(0.0f, -38.0f));
	}

    CSpriteLayer@ arm = sprite.addSpriteLayer("arm", "Catapult.png", 16,32);
    
    if (arm !is null)
    {
        Animation@ anim = arm.addAnimation("default", 0, false);
        anim.AddFrame(6);
        anim.AddFrame(7);
        arm.ResetTransform();
        arm.SetOffset(Vec2f(-8,-40));
        arm.SetRelativeZ(-0.01f);
        // rotation handled by CBlob update
    }

	v.max_charge_time = 90;
	v.fire_cost_per_amount = 2;
	Vehicle_SetupWeapon(this, v,
	                    cata_cooldown_time, // fire delay (ticks)
	                    5, // fire bullets amount
	                    getMagAttachmentPoint(this).offset, // fire position offset
	                    "mat_stone", // bullet ammo config name
	                    "cata_rock", // bullet config name
	                    "CatapultFire", // fire sound
	                    "CatapultFire", // empty fire sound
	                    Vehicle_Fire_Style::custom
	                   );

    this.set_u16("last bombing time", getGameTime());



    // Add 2 blocks to shape (to prevent riding players falling out)
    {
		Vec2f[] shape = { Vec2f(-7,  -5),
		                  Vec2f(-3,  -5),
		                  Vec2f(-3,  0),
		                  Vec2f(-7,  0)
		                };
		this.getShape().AddShape(shape);
	}

    {
		Vec2f[] shape = { Vec2f(33,  -5),
		                  Vec2f(37,  -5),
		                  Vec2f(37,  0),
		                  Vec2f(33,  0)
		                };
		this.getShape().AddShape(shape);
	}

    this.getShape().SetRotationsAllowed(false);
    this.getShape().getConsts().bullet = true;
    this.set_u8("attached_count", 0);
    
    // Add catapult
    //AttachmentPoint@ ap = this.getAttachmentPoint(2);
    //CBlob@ catapult = server_CreateBlob("catapult", this.getTeamNum(), ap.getPosition());

    // Add some bombs to inventory
    if (getNet().isServer())
    {
        // Some bombs
        /*
        for (int i=0; i < 8; i++)
        {
            CBlob@ bomb = server_CreateBlob("mat_bombs");
            if (bomb !is null)
            {
                if (!this.server_PutInInventory(bomb))
                    bomb.server_Die();
            }
        }
        */

        // Cata stone
        CBlob@ ammo = server_CreateBlob("mat_stone");
		if (ammo !is null)
		{
			ammo.server_SetQuantity(cata_startStone);
			if (!this.server_PutInInventory(ammo))
				ammo.server_Die();
		}
    }

    this.getAttachmentPoint(3).offsetZ = 11.0f;
}

void onTick(CBlob@ this)
{
    VehicleInfo@ v;
    if (!this.get("VehicleInfo", @v))
    {
        return;
    }
    Vehicle_StandardControls(this, v);

    if (getGameTime() % 5 == 0)
    {
        // Turn the bomber left/right according to the gunner's direction
        AttachmentPoint@ gunner_point = this.getAttachmentPoint(3);
        CBlob@ gunner = gunner_point.getOccupied();
        if (gunner !is null)
        {
            //printf("Gunner not null");
            if (gunner_point.isKeyPressed(key_left))
            {
                //printf("Gunner pressed left");
                this.SetFacingLeft(true);
            }
            else if (gunner_point.isKeyPressed(key_right))
            {
                //printf("Gunner pressed right");
                this.SetFacingLeft(false);
            }

        }

        if (this.get_u8("attached_count") == 0 && !this.isOnGround()) // no pilots left
        {
            // Check if a player is near (i.e. standing on the ship)
            CBlob@[] nearby_blobs;
            getMap().getBlobsInRadius(this.getPosition(), 20.0f, @nearby_blobs);
            bool found_player = false;
            for (uint i=0; i < nearby_blobs.length; i++)
            {
                CBlob@ blob = nearby_blobs[i];
                if (blob.hasTag("player"))
                {
                    found_player = true;
                    break;
                }
            }

            if (!found_player)
                v.fly_amount = 0.72f;
            else
                v.fly_amount = 0.85f;
        }
    }

    if (this.getHealth() <= 1.0f)
    {
        this.server_DetachAll();
        this.setAngleDegrees(this.getAngleDegrees() + (this.isFacingLeft() ? 1 : -1));

        if (this.isOnGround() || this.isInWater())
        {
            this.server_SetHealth(-1.0f);
            this.server_Die();
        }
        else
        {
            //TODO: effects
            if (getGameTime() % 30 == 0)
                this.server_Hit(this, this.getPosition(), Vec2f(0, 0), 0.05f, 0, true);
        }
    }

    // Handle catapult arm
    const u16 delay = float(v.fire_delay);
	const f32 time_til_fire = Maths::Max(0, Maths::Min(v.fire_time - getGameTime(), delay));
    if (this.getTickSinceCreated() < 30 || (this.getAttachmentPoint(3).getOccupied() !is null)) // if gunner exists
    {
        if (getNet().isClient() && delay != 0) //only matters visually on client
		{
			//set the arm angle based on how long ago we fired
			f32 rechargeRatio = (time_til_fire / delay);
			f32 angle = 360.0f * (1.0f - rechargeRatio);
			CSpriteLayer@ arm = this.getSprite().getSpriteLayer("arm");

			if (arm !is null)
			{
				f32 armAngle = 20 + (angle / 9) + (float(v.charge) / float(v.max_charge_time)) * 20;

				f32 floattime = getGameTime();
				f32 sign = this.isFacingLeft() ? -1.0f : 1.0f;

				Vec2f armOffset = Vec2f(-8.0f, -40.0f);
				arm.SetOffset(armOffset);

				arm.ResetTransform();
				arm.SetRelativeZ(-0.01f);
				arm.RotateBy(armAngle * -sign, Vec2f(0.0f, 13.0f));

				if (getMagBlob(this) is null && v.loaded_ammo > 0)
				{
					arm.animation.frame = 1;
				}
				else
				{
					arm.animation.frame = 0;
				}

				// set the bowl attachment offset
				Vec2f offset = Vec2f(4, -10);
				offset.RotateBy(-armAngle, Vec2f(0.0f, 13.0f));
				offset += armOffset + Vec2f(28, 0);

				this.getAttachments().getAttachmentPointByName("MAG").offset = offset;
			}
		}
    }


    // Handle bombing
    u16 time_since_last_bombing = getGameTime() - this.get_u16("last bombing time");
    if (time_since_last_bombing > BOMBING_INTERVAL_TICKS)
    {
        for (u8 i=0; i < 2; i++)
        {
            AttachmentPoint@ flyer_point = this.getAttachmentPoint(i);
            CBlob@ flyer = flyer_point.getOccupied();
            if ((flyer !is null) && flyer_point.isKeyPressed(key_use))
            {
                server_CreateBlob("bomb", this.getTeamNum(), this.getPosition() + Vec2f(0, 12));
                this.set_u16("last bombing time", getGameTime());
            }
        }
    }
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue)
{
	u8 charge = v.charge;

	if (charge > 0 || isActionPressed)
	{

		if (charge < v.max_charge_time && isActionPressed)
		{
			charge++;
			v.charge = charge;

			u8 t = Maths::Round(float(v.max_charge_time) * 0.66f);
			if ((charge < t && charge % 10 == 0) || (charge >= t && charge % 5 == 0))
				this.getSprite().PlaySound("/LoadingTick");

			chargeValue = charge;
			return false;
		}

		chargeValue = charge;

		if (charge < cata_baseline_charge)
			return false;

		v.firing = true;

		return true;
	}

	return false;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("fire"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		v.firing = false;
		v.charge = 0;
	}
	else if (cmd == this.getCommandID("fire blob"))
	{
		CBlob@ blob = getBlobByNetworkID(params.read_netid());
		const u8 charge = params.read_u8();
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Vehicle_onFire(this, v, blob, charge);
	}
}

Random _r(0xca7a);

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge)
{
	f32 charge = cata_baseline_charge + (float(_charge) / float(v.max_charge_time)) * cata_charge_contrib;

	if (bullet !is null)
	{
		f32 angle = this.getAngleDegrees();
		f32 sign = this.isFacingLeft() ? -1.0f : 1.0f;

		Vec2f vel = Vec2f(sign, -0.5f) * charge * 0.3f;

		vel += (Vec2f((_r.NextFloat() - 0.5f) * 128, (_r.NextFloat() - 0.5f) * 128) * 0.01f);
		vel.RotateBy(angle);

		bullet.setVelocity(vel);

		if (isKnockable(bullet))
		{
			SetKnocked(bullet, 30);
		}
	}

	// we override the default time because we want to base it on charge
	int delay = 30 + (charge / (250 / 30));
	v.fire_delay = delay;

	v.last_charge = _charge;
	v.charge = 0;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	//return Vehicle_doesCollideWithBlob_ground(this, blob);

    if (!blob.isCollidable() || blob.isAttached()) // no colliding against people inside vehicles
        return false;
    else if (blob.hasTag("player") && this.isOnGround())
        return false;

    return true;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_onAttach(this, v, attached, attachedPoint);
    this.set_u8("attached_count", this.get_u8("attached_count") + 1);

    /*
    if (attachedPoint.name == "GUNNER")
    {
        attached.getSprite().SetRelativeZ(1001.0f);
        attached.getSprite().getSpriteLayer("head").SetRelativeZ(1001.1f);
    }
    */
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_onDetach(this, v, detached, attachedPoint);

    this.set_u8("attached_count", this.get_u8("attached_count") - 1);

    /*
    if (attachedPoint.name == "GUNNER")
        detached.getSprite().SetRelativeZ(0.0f);
    */
}


// SPRITE

void onInit(CSprite@ this)
{
	this.SetZ(-50.0f);
	this.getCurrentScript().tickFrequency = 5;

}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	f32 ratio = 1.0f - (blob.getHealth() / blob.getInitialHealth());
	this.animation.setFrameFromRatio(ratio);

	CSpriteLayer@ balloon = this.getSpriteLayer("balloon");
	if (balloon !is null)
	{
		if (blob.getHealth() > 1.0f)
			balloon.animation.frame = Maths::Min((ratio) * 3, 1.0f);
		else
			balloon.animation.frame = 2;
	}

	CSpriteLayer@ burner = this.getSpriteLayer("burner");
	if (burner !is null)
	{
		burner.SetOffset(Vec2f(0.0f, -14.0f));
		s8 dir = blob.get_s8("move_direction");
		if (dir == 0)
		{
			blob.SetLightColor(SColor(255, 255, 240, 171));
			burner.SetAnimation("default");
		}
		else if (dir < 0)
		{
			blob.SetLightColor(SColor(255, 255, 240, 200));
			burner.SetAnimation("up");
		}
		else if (dir > 0)
		{
			blob.SetLightColor(SColor(255, 255, 200, 171));
			burner.SetAnimation("down");
		}
	}
}

/*
void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
    printf("bomber onHitBlob");
    if (hitBlob.hasTag("flesh"))
    {
        printf("" + hitBlob.getHealth());
        //hitBlob.server_Heal(10.0f);
        //printf("" + hitBlob.getHealth());
    }
}
*/

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    printf("[onHit] name: " + this.getName() +
            ", worldpoint: " + worldPoint.x + "," + worldPoint.y +
            ", velocity: " + velocity.x + "," + velocity.y + 
            ", damage: " + damage +
            ", hitterBlob: " + hitterBlob.getName() +
            ", customData: " + customData);
    if (this.getName() == "archer" && hitterBlob.getName() == "bomber")
        this.server_SetHealth(10.0f);
    return damage;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
    printf("[onHitBlob] name: " + this.getName() +
            ", worldpoint: " + worldPoint.x + "," + worldPoint.y +
            ", velocity: " + velocity.x + "," + velocity.y + 
            ", damage: " + damage +
            ", hitBlob: " + hitBlob.getName() + 
            ", customData: " + customData);
}

void onHitMap( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData )
{
    printf("[onHitMap] name: " + this.getName() +
            ", worldpoint: " + worldPoint.x + "," + worldPoint.y +
            ", velocity: " + velocity.x + "," + velocity.y + 
            ", damage: " + damage +
            ", customData: " + customData);
}

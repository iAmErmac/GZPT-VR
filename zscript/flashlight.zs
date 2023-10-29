class PlayerInteractionWep : Weapon
{
    Default
    {
	Weapon.SelectionOrder 1900;
	Weapon.AmmoUse 1;
	Weapon.AmmoGive 20;
	Weapon.AmmoType "Clip";
	DamageType "InteractionDamage";
	Obituary "%o got stranded in his death.";
	+WEAPON.AMMO_OPTIONAL
	+WEAPON.NOAUTOAIM
	+WEAPON.MELEEWEAPON
	Inventory.Pickupmessage "You picked up an incredible box of nothing!";
	}
	
	override void Tick()
	{
		if(!owner || !owner.player || owner.player.mo.health < 1) return;
		
		Actor beamTracer = owner.SpawnPlayerMissile("PTLightBeamTracer");
		if(beamTracer) beamTracer.master = self;
		
		if(GetAge() && GetAge() % 17 == 0)
		{
			Actor lineTracer = Actor.Spawn("PTlineTraceUseDummy", handPos);
			lineTracer.master = owner.player.mo;
			lineTracer.A_SetAngle(beamAngle);
			lineTracer.A_SetPitch(beamPitch);
			PTlineTraceUseDummy(lineTracer).range = 0.25;
		}
	}
	
	States
	{
	Ready:
		TNT1 A 0;
		HAND A 0 A_TakeInventory("Token_HasReleasedAltFire", 100);
		HAND A 0 A_JumpIfInventory("PowerFlashlight", 1, "ReadyFLashlight");
		HAND A 1 
		{
			A_CheckReload();
			A_WeaponReady();
		}
		Loop;
	ReadyFLashlight:
		HAND C 1
		{
			A_CheckReload();
			A_WeaponReady();
		}
		HAND C 0 A_JumpIfInventory("PowerFlashlight", 1, "ReadyFLashlight");
		Goto Ready;
	Deselect:
		HAND A 1 A_Lower(160);
		Loop;
	Select:
		HAND A 1 A_Raise(160);
		Loop;
	Fire:
		HAND A 1;
		Goto Ready;
	AltFire:
		HAND B 1;
		goto AltFireHold;
	AltFireHold:
		HAND B 1 A_FireProjectile("InteractionBall",0,0,0,13,FPF_NOAUTOAIM,0);
		HAND B 0 A_Refire("AltFireHold");
		goto AltFireExit;
	AltFireExit:
		HAND A 1 A_GiveInventory("Token_HasReleasedAltFire", 1);
		goto Ready;
	Spawn:
		PIST A -1;
		Stop;
	}

	vector3 handPos;
	double beamAngle, beamPitch;
}

Class PTlineTraceUseDummy : Actor
{
	Default
	{
	Mass        0;
	Radius      1;
	Height      2;

	+NOBLOCKMAP;
	+NOGRAVITY;
	+DONTSPLASH;
	+SKYEXPLODE;
	+GHOST;
	-COUNTKILL;
	}

	States
	{
	Spawn:
		TNT1 A 1;
		Stop;
	}
	
	override void Tick()
	{
		FLineTraceData l;
		double z = height * 0.5 - floorclip + pos.z;
		LineTrace(angle, range * 64, pitch, TRF_BLOCKUSE, offsetz: z, data: l);
		let lline = l.HitLine;
		if (lline)
		{
			lline.Activate(master, l.LineSide, SPAC_Use);
		}
		destroy();
	}
	
	double range;
}

Class PTLightBeamTracer : Actor
{
	Vector3 t_pos;
	double t_pitch;
	
	override void BeginPlay()
	{
		t_pos = self.pos;
	}

	override void Tick()
	{
		Super.Tick();
		
		let dX = t_pos.x - self.pos.x;
		let dY = t_pos.y - self.pos.y;
		let dZ = t_pos.z - self.pos.z;
		
		t_pitch = (atan2(sqrt(dX * dX + dY * dY), dZ) * -1) + 90;
		
		PlayerInteractionWep(master).handPos = t_pos;
		PlayerInteractionWep(master).beamPitch = t_pitch;
		PlayerInteractionWep(master).beamAngle = angle;
	}

	Default
	{
	Projectile;
	+MISSILE;
	+NOGRAVITY;
	+NOBLOCKMAP;
	+DONTSPLASH;
	+THRUACTORS;
	Radius 1;
	Height 1;
	Damage 0;
	Speed 65;
	RenderStyle "None";
	}
	
	States
	{
	Spawn:
		TNT1 A 1; //don't need more than a single tick
		Stop;
	}
}

Class PTDummyPuff1 : Actor
{
	Default
	{
	Radius 1;
	Height 1;
	Speed 0;
	Damage 0;
	+GHOST;
	+NOGRAVITY;
	Renderstyle "None";
	}
	
	States
	{
	Spawn:
		TNT1 A 2;
		Stop;
	}
}

// Manages the components of the beam, and attaches it to its source
class PowerFlashlight : Powerup
{
    Property EnergyType : energyType;               // Light flickers when player is low on this inventory class
    Property FlickerThreshold : flickerThreshold;   // Threshold amount for light flicker
    Property Offset : ofsX, ofsY, ofsZ;             // Beam offset, relative to attack height

    // Beam hotspot properties
    Property SpotColor : spotColor;
    Property SpotRange : spotRange;                 // Note: I think range depends on beam angle, too
    Property SpotInnerAngle : spotInnerAngle;       // Max brightness inside this angle from center
    Property SpotOuterAngle : spotOuterAngle;       // No light outside this angle

    // Spill light properties
    Property SpillColor : spillColor;
    Property SpillRange : spillRange;
    Property SpillInnerAngle : spillInnerAngle;
    Property SpillOuterAngle : spillOuterAngle;

    // Reflected light properties
    Property BounceColor : bounceColor;
    Property BounceRange : bounceRange;             // Note: Range from point of reflection
    Property BounceInnerAngle : bounceInnerAngle;
    Property BounceOuterAngle : bounceOuterAngle;

    Default
    {
        Inventory.MaxAmount 1;
        Powerup.Duration 0x7FFFFFFF;

        PowerFlashlight.EnergyType "FlashLightBeamStrenght";
        PowerFlashlight.FlickerThreshold 10;
        PowerFlashlight.Offset 1, 0, 0; // ofsX is 1 so player doesn't illuminate themself

        PowerFlashlight.SpotColor 0xffffff;
        PowerFlashlight.SpotRange 1024;
        PowerFlashlight.SpotInnerAngle 6;
        PowerFlashlight.SpotOuterAngle 8;

        PowerFlashlight.SpillColor 0x252525;
        PowerFlashlight.SpillRange 512; //32;
        PowerFlashlight.SpillInnerAngle 25;
        PowerFlashlight.SpillOuterAngle 30;

        PowerFlashlight.BounceColor 0x888888;
        PowerFlashlight.BounceRange 0; // 256;
        PowerFlashlight.BounceInnerAngle 0;
        PowerFlashlight.BounceOuterAngle 45;
    }

    class<Inventory> energyType;
    double flickerThreshold;
    double ofsX, ofsY, ofsZ;

    Color spotColor;
    int spotRange;
    double spotInnerAngle;
    double spotOuterAngle;

    Color spillColor;
    int spillRange;
    double spillInnerAngle;
    double spillOuterAngle;

    Color bounceColor;
    int bounceRange;
    double bounceInnerAngle;
    double bounceOuterAngle;

    FlashlightBeam spot;
    FlashlightBeam spill;
    FlashlightBounce bounce;

    override void AttachToOwner(Actor other)
    {
        Super.AttachToOwner(other);

        spot = FlashlightBeam(Spawn("FlashlightBeam", other.pos));
        spot.master = other;
        spot.offset = (ofsX, ofsY, ofsZ);
        spot.args[0] = spotColor.r;
        spot.args[1] = spotColor.g;
        spot.args[2] = spotColor.b;
        spot.args[3] = spotRange;
        spot.spotInnerAngle = spotInnerAngle;
        spot.spotOuterAngle = spotOuterAngle;

        if (spillRange > 0)
        {
            spill = FlashlightBeam(Spawn("FlashlightBeam", other.pos));
            spill.master = other;
            spill.offset = (ofsX, ofsY, ofsZ);
            spill.args[0] = spillColor.r;
            spill.args[1] = spillColor.g;
            spill.args[2] = spillColor.b;
            spill.args[3] = spillRange;
            spill.spotInnerAngle = spillInnerAngle;
            spill.spotOuterAngle = spillOuterAngle;
        }
    }

    override void DoEffect()
    {
        Super.DoEffect();
		
		let player = owner.player;
		let pmo = player.mo;
		double angle = pmo.angle;
		double pitch = pmo.AimTarget() ? pmo.BulletSlope(null, ALF_PORTALRESTRICT) : pmo.pitch;
		double dist = 5;
		if(abs(pmo.vel.x) > 2 || abs(pmo.vel.y) > 2 || abs(pmo.vel.z) > 2) dist = 15;
		
		let _puff = pmo.LineAttack(angle, dist, pitch, 0, "melee", "PTDummyPuff1", LAF_NOIMPACTDECAL | LAF_NOINTERACT | LAF_NORANDOMPUFFZ);
		spot.beamPos = spill.beamPos = _puff.pos;
		
		let beamTracer = PlayerInteractionWep(pmo.findinventory("PlayerInteractionWep"));
		let beamAngle = beamTracer.beamAngle;
		let beamPitch = beamTracer.beamPitch;
		if(beamAngle)
		{
			spot.beamAngle = beamAngle;
			spill.beamAngle = beamAngle;
		}
		if(beamPitch)
		{
			spot.beamPitch = beamPitch;
			spill.beamPitch = beamPitch;
		}

        int energy = energyType ? owner.CountInv(energyType) : effectTics;

        int flicker = Random(0, flickerThreshold);
        if (flicker < 0) flicker *= -ticRate;

        if (flicker > energy)
        {
            spot.args[3] = 0;
            if (spill) spill.args[3] = 0;
            if (bounce) bounce.args[3] = 0;
        }
        else
        {
            spot.args[3] = spotRange;
            if (spill) spill.args[3] = spillRange;
            if (bounce) bounce.args[3] = bounceRange;
        }
    }

    override void DetachFromOwner()
    {
        spot.Destroy();
        if (spill) spill.Destroy();
        if (bounce) bounce.Destroy();
        Super.DetachFromOwner();
    }
}

class PowerFlashlightGreen : PowerFlashlight
{
    Default
    {
PowerFlashlight.SpotColor 0x00CB21;
PowerFlashlight.SpillColor 0x257425;
PowerFlashlight.BounceColor 0x88B588;
   }
}

class PowerFlashlightBlue : PowerFlashlight
{
    Default
    {
PowerFlashlight.SpotColor 0x3075FF;
PowerFlashlight.SpillColor 0x163777;
PowerFlashlight.BounceColor 0x4B78CC;
   }
}

class PowerFlashlightYellow : PowerFlashlight
{
    Default
    {
PowerFlashlight.SpotColor 0xFFD800;
PowerFlashlight.SpillColor 0x937B00;
PowerFlashlight.BounceColor 0xD3B000;
   }
}

class PowerFlashlightRed : PowerFlashlight
{
    Default
    {
PowerFlashlight.SpotColor 0xFF0000;
PowerFlashlight.SpillColor 0xAD0000;
PowerFlashlight.BounceColor 0xD80000;
   }
}


// Spotlight that follows its master around
class FlashlightBeam : SpotLight
{
    Vector3 offset, beamPos;
	Double beamAngle, beamPitch;

    override void Tick()
    {
        Super.Tick();

        let plyr = PlayerPawn(master);
        /*Vector3 beamPos = master.pos;
        beamPos.xy += AngleToVector(master.angle, offset.x);
        beamPos.xy += AngleToVector(master.angle - 90, offset.y);

        let plyr = PlayerPawn(master);
        if (plyr && plyr.player)
        {
            beamPos.z += (plyr.height / 2 + plyr.attackZOffset) * plyr.player.crouchFactor;
        }
        else
        {
            beamPos.z += master.height / 2;
        }*/

        SetOrigin(beamPos, true);

        vel = master.vel;
        angle = beamAngle; //master.angle;
        pitch = beamPitch; //master.pitch;
    }
}


// Spotlight that bounces off whatever its master faces
class FlashlightBounce : SpotLight
{
    Vector3 offset;

    override void Tick()
    {
        Super.Tick();

        // Find intersection point
        double ofsZ;
        let plyr = PlayerPawn(master);
        if (plyr && plyr.player)
        {
            ofsZ += (plyr.height / 2 + plyr.attackZOffset) * plyr.player.crouchFactor;
        }
        else
        {
            ofsZ += master.height / 2;
        }

        FLineTraceData data;
        master.LineTrace(
            master.angle,
            8192,
            master.pitch,
            TRF_ThruActors | TRF_NoSky,
            ofsz, offset.x, offset.y,
            data);

        // Bounce light comes from intersection
        Vector3 bouncePos = data.hitLocation;
        bouncePos.xy += AngleToVector(master.angle + 180);
        SetOrigin(bouncePos, true);

        // Find reflection vector
        Vector3 normal;
        if (data.hitType == Trace_HitWall)
        {
            if (data.lineSide = Line.front) normal.xy = RotateVector(data.hitLine.delta.Unit(), -90);
            else normal.xy = RotateVector(data.hitLine.delta.Unit(), 90);
        }
        else if (data.hitType == Trace_HitFloor)
        {
            normal = data.hitSector.floorPlane.Normal;
        }
        else if (data.hitType == Trace_HitFloor)
        {
            normal = data.hitSector.ceilingPlane.Normal;
        }
        else
        {
            Deactivate(null);
            return;
        }

        Activate(null);

        Vector3 reflection = data.hitDir - 2 * (data.hitDir dot normal) * normal;

        angle = VectorAngle(reflection.x, reflection.y);
        pitch = -ASin(reflection.z / reflection.Length());
    }
}
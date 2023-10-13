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
  Inventory.Pickupmessage "You picked up an incredible box of nothing!";
     }
  States
  {
  Ready:
    TNT1 A 1 
	        {
            A_CheckReload();
            A_WeaponReady();
        }
    TNT1 A 0 A_TakeInventory("Token_HasReleasedAltFire", 100);
    Loop;
  Deselect:
    TNT1 A 1 A_Lower;
    Loop;
  Select:
    TNT1 A 1 A_Raise;
    Loop;
  Fire:
    TNT1 A 1;
    //TNT1 A 8
    //{
	//if (CountInv("Token_FlashlightEnabler"))
	//    {
    //        if (CountInv("PowerFlashlight"))
    //        {
    //            A_PlaySound("flashlight/off");
    //            A_TakeInventory("PowerFlashlight");
    //        }
    //       else
    //        {
    //            A_PlaySound("flashlight/on");
    //            A_GiveInventory("PowerFlashlight");
    //        }
    //    }
	// }
        Goto Ready;
  AltFire:
    TNT1 A 1 A_ZoomFactor(1.5);
	goto AltFireHold;
  AltFireHold:
    TNT1 A 1 A_FireProjectile("InteractionBall",0,0,0,13,FPF_NOAUTOAIM,0);
    TNT1 A 0 A_Refire("AltFireHold");
	goto AltFireExit;
  AltFireExit:
    TNT1 A 0 A_GiveInventory("Token_HasReleasedAltFire", 1);
    TNT1 A 1 A_ZoomFactor(1.0);
	goto Ready;
  Spawn:
    PIST A -1;
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
        PowerFlashlight.SpillRange 32;
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
        spot.args[0] = spillColor.r;
        spot.args[1] = spillColor.g;
        spot.args[2] = spillColor.b;
        spot.args[3] = spillRange;
        spot.spotInnerAngle = spillInnerAngle;
        spot.spotOuterAngle = spillOuterAngle;

    }

    override void DoEffect()
    {
        Super.DoEffect();

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
    Vector3 offset;

    override void Tick()
    {
        Super.Tick();

        Vector3 beamPos = master.pos;
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
        }

        SetOrigin(beamPos, true);

        vel = master.vel;
        angle = master.angle;
        pitch = master.pitch;
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

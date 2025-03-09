class PoliceGoat extends GGMutator;

var array<GGGoat> mGoats;
var float timeElapsed;
var float managementTimer;
var float SRTimeElapsed;
var float spawnRemoveTimer;
var float spawnRadius;
var int minPoliceCount;
var int maxPoliceCount;

var array<GGNpc> mRemovableNPCs;
var int mPoliceNPCCount;
var array<int> mPoliceNPCsToSpawnForPlayer;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	goat = GGGoat( other );

	if( goat != none )
	{
		if( IsValidForPlayer( goat ) )
		{
			mGoats.AddItem(goat);
		}
	}

	super.ModifyPlayer( other );
}

simulated event Tick( float deltaTime )
{
	super.Tick( deltaTime );

	timeElapsed=timeElapsed+deltaTime;
	if(timeElapsed > managementTimer)
	{
		timeElapsed=0.f;
		GeneratePoliceNPCLists();
	}
	SRTimeElapsed=SRTimeElapsed+deltaTime;
	if(SRTimeElapsed > spawnRemoveTimer)
	{
		SRTimeElapsed=0.f;
		SpawnPoliceNPCFromList();
		RemovePoliceNPCFromList();
	}
}

function GeneratePoliceNPCLists()
{
	local GGNpcPolice policeNPC;
	local array<int> policeNPCsForPlayer;
	local bool isRemovable;
	local int nbPlayers, i;
	local vector dist;

	mRemovableNPCs.Length=0;

	nbPlayers=mGoats.Length;
	mPoliceNPCsToSpawnForPlayer.Length = 0;
	mPoliceNPCsToSpawnForPlayer.Length = nbPlayers;
	policeNPCsForPlayer.Length = nbPlayers;
	mPoliceNPCCount=0;
	//Find all policemen NPCs close to each player
	foreach AllActors(class'GGNpcPolice', policeNPC)
	{
		//WorldInfo.Game.Broadcast(self, MMONPCAI $ " possess " $ policeNPC);
		mPoliceNPCCount++;
		isRemovable=true;

		for(i=0 ; i<nbPlayers ; i++)
		{
			dist=mGoats[i].Location - policeNPC.Location;
			if(VSize2D(dist) < spawnRadius)
			{
				policeNPCsForPlayer[i]++;
				isRemovable=false;
			}
		}

		if(isRemovable)
		{
			mRemovableNPCs.AddItem(policeNPC);
		}
	}

	for(i=0 ; i<nbPlayers ; i++)
	{
		mPoliceNPCsToSpawnForPlayer[i]=minPoliceCount-policeNPCsForPlayer[i];
	}
	//WorldInfo.Game.Broadcast(self, "MMONPCs to spawn " $ mPoliceNPCsToSpawnForPlayer[0]);
}

function SpawnPoliceNPCFromList()
{
	local GGNpcPolice newNpc;
	local int nbPlayers, i;

	//Spawn new goat and sheeps NPCs if needed
	nbPlayers=mGoats.Length;
	for(i=0 ; i<nbPlayers ; i++)
	{
		if(mPoliceNPCsToSpawnForPlayer.Length > 0 && mPoliceNPCsToSpawnForPlayer[i] > 0)
		{
			mPoliceNPCsToSpawnForPlayer[i]--;
			newNpc = Spawn( class'GGNpcPolice',,, GetRandomSpawnLocation(mGoats[i].Location), GetRandomRotation());
			if(newNpc != none)
			{
				SetupSpawnedPawn(newNpc);
				mPoliceNPCCount++;
			}
			break;
		}
	}
}

function RemovePoliceNPCFromList()
{
	local GGNpc NPCToRemove;
	local int nbPlayers, goatsToRemove;

	//Remove old MMONPCs and infected NPCs if needed
	nbPlayers=mGoats.Length;
	goatsToRemove=mPoliceNPCCount-(maxPoliceCount*nbPlayers);
	if(mRemovableNPCs.Length > 0 && goatsToRemove > 0)
	{
		NPCToRemove=mRemovableNPCs[0];
		mRemovableNPCs.Remove(0, 1);

		DestroyNPC(NPCToRemove);
		mPoliceNPCCount--;
	}
}

function SetupSpawnedPawn(GGNpcPolice newNpc)
{
	SetNpcRandomSkin(newNpc);
	newNpc.SpawnDefaultController();
	newNpc.SetPhysics( PHYS_Falling );
	//WorldInfo.Game.Broadcast(self, newNpc $ " controller " $ newNpc.Controller);
}

function SetNpcRandomSkin(GGNpcPolice npc)
{
  	if(Rand(2) == 0)
  	{
		npc.mesh.SetSkeletalMesh( SkeletalMesh'Heist_Characters_02.mesh.Cop_01' );
	}
	else
	{
		npc.mesh.SetSkeletalMesh( SkeletalMesh'Heist_Characters_02.mesh.Cop_02' );
	}
}

function DestroyNPC(GGPawn gpawn)
{
	local int i;

	for( i = 0; i < gpawn.Attached.Length; i++ )
	{
		if(GGGoat(gpawn.Attached[i]) == none)
		{
			gpawn.Attached[i].ShutDown();
			gpawn.Attached[i].Destroy();
		}
	}
	gpawn.ShutDown();
	gpawn.Destroy();
}

function vector GetRandomSpawnLocation(vector center)
{
	local vector dest;
	local rotator rot;
	local float dist;
	local Actor hitActor;
	local vector hitLocation, hitNormal, traceEnd, traceStart;

	rot=GetRandomRotation();

	dist=spawnRadius;
	dist=RandRange(dist/2.f, dist);

	dest=center+Normal(Vector(rot))*dist;
	traceStart=dest;
	traceEnd=dest;
	traceStart.Z=10000.f;
	traceEnd.Z=-3000;

	hitActor = Trace( hitLocation, hitNormal, traceEnd, traceStart, true);
	if( hitActor == none )
	{
		hitLocation = traceEnd;
	}

	hitLocation.Z+=30;

	return hitLocation;
}

function rotator GetRandomRotation()
{
	local rotator rot;

	rot=Rotator(vect(1, 0, 0));
	rot.Yaw+=RandRange(0.f, 65536.f);

	return rot;
}

DefaultProperties
{
	managementTimer=1.f
	spawnRemoveTimer=0.1f
	spawnRadius=5000.f
	minPoliceCount=5
	maxPoliceCount=10
}
/**
 * Custom Spawn V1.0
 * By David Y.
 * 2015-01-21
 *
 * Allows players to respawn after death at a different location than the 
 * standard map spawn points using the sm_setspawn command. Once this command 
 * is invoked, the current player's location is stored as the new spawn point 
 * and saved for future respawns. The custom respawn point can be removed via 
 * the sm_clearspawn command after which further player spawns will be at the 
 * default map spawn points.
 *
 * This plugin can be restricted for use only by admins by setting the 
 * sm_players_spawn_admin_only value to 1.
 *
 * Some code adapted from almcaeobtac's Player Spawns plugin V1.2 at
 * https://forums.alliedmods.net/showthread.php?p=877834
 */

#include <sourcemod>
#include <sdktools>

new Handle:sm_players_spawn_admin_only = INVALID_HANDLE;

static Float:SpawnPoint[MAXPLAYERS][3];
static bool:SpawnSet[MAXPLAYERS];
static bool:SpawnSetDisabled = false;

public Plugin:myinfo = {
	name = "Player Spawns",
	author = "David Y.",
	description = "Players set a custom spawnpoint for themselves.",
	version = "1.0.0",
	url = "http://www.davidvyee.com/"
}

public OnPluginStart() {
	CreateConVar("sm_player_spawns_version", "1.0.0", "Player Spawns Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_players_spawn_admin_only = CreateConVar("sm_players_spawn_admin_only", "0", "Toggles Admin Only spawn saving.", FCVAR_PLUGIN);
	RegConsoleCmd("sm_setspawn", SetSpawn);
	RegConsoleCmd("sm_clearspawn", ClearSpawn);

	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
}

public OnClientPutInServer(Client) {
	for(new i=0; i<3; i++)
		SpawnPoint[Client][i] = 0.0;
	SpawnSet[Client] = false;
}

public Action:SetSpawn(Client, Args) {
	if(SpawnSetDisabled == true) {
		PrintToChat(Client, "[SM] You cannot set your spawn right now.");
		return Plugin_Handled;
	}

	if(Client == 0) {
		return Plugin_Handled;
	}

	new AdminId:id = GetUserAdmin(Client);

	if(GetConVarBool(sm_players_spawn_admin_only) && id == INVALID_ADMIN_ID) {
		PrintToChat(Client, "[SM] You cannot set your spawn right now.");
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client)) {
		PrintToChat(Client, "[SM] You must be alive to set a spawn location.");
		return Plugin_Handled;
	}

	decl Float:Location[3];

	GetClientAbsOrigin(Client, Location);

	SpawnPoint[Client][0] = Location[0];
	SpawnPoint[Client][1] = Location[1];
	SpawnPoint[Client][2] = Location[2];

	SpawnSet[Client] = true;

	PrintToChat(Client, "[SM] Spawn location set.");

	return Plugin_Handled;
}

public Action:ClearSpawn(Client, Args) {
	if(Args == 0) {
		if(Client == 0) {
			return Plugin_Handled;
		}

		if(!SpawnSet[Client]) {
			PrintToChat(Client, "[SM] No spawn location set.");
			return Plugin_Handled;
		}

		SpawnSet[Client] = false;
		PrintToChat(Client, "[SM] Spawn location cleared.");
		return Plugin_Handled;
	}
	else {
		decl bool:IsAdmin;

		if(Client == 0) {
			IsAdmin = true;
		}
		else {
			new AdminId:id = GetUserAdmin(Client);
			if(id == INVALID_ADMIN_ID) {
				IsAdmin = false;
			}
			else {
				IsAdmin = true;
			}
		}

		if(!IsAdmin) {
			PrintToChat(Client, "[SM] You do not have access to this command.");
			return Plugin_Handled;
		}

		decl String:TypedName[MAX_NAME_LENGTH];
		decl String:TestName[MAX_NAME_LENGTH];
		decl String:TargetName[MAX_NAME_LENGTH];
		decl String:AdminName[MAX_NAME_LENGTH];

		decl Possibles;
		Possibles = 0;

		decl Target;
		Target = -1;

		GetCmdArgString(TypedName, MAX_NAME_LENGTH);
		StripQuotes(TypedName);
		TrimString(TypedName);

		for(new Player = 1; Player <= MaxClients; Player++) {
			if(IsClientInGame(Player)) {
				GetClientName(Player, TestName, MAX_NAME_LENGTH);
				if(StrContains(TestName, TypedName, false) != -1) {
					Target = Player;
					Possibles += 1;
				}
			}
		}

		if(Target == -1) {
			if(Client == 0) {
				PrintToConsole(Client, "[SM] %s is not ingame.", TypedName);
			}
			else {
				PrintToChat(Client, "[SM] %s is not ingame.", TypedName);
			}
			return Plugin_Handled;
		}

		if(Possibles > 1) {
			if(Client == 0) {
				PrintToConsole(Client, "[SM] Multiple targets found.");
			}
			else {
				PrintToChat(Client, "[SM] Multiple targets found.");
			}
			return Plugin_Handled;
		}

		GetClientName(Target, TargetName, MAX_NAME_LENGTH);
		
		if(Client == 0) {
			AdminName = "The Console";
		}
		else {
			GetClientName(Client, AdminName, MAX_NAME_LENGTH);
		}

		if(!SpawnSet[Target]) {
			if(Client == 0) {
				PrintToConsole(Client, "[SM] %s does not have a spawn location set.", TargetName);
			}
			else {
				PrintToChat(Client, "[SM] %s does not have a spawn location set.", TargetName);
			}
			return Plugin_Handled;
		}

		SpawnSet[Target] = false;
		PrintToChat(Target, "[SM] %s cleared your spawn location.", AdminName);
		
		if(Client == 0) {
			PrintToConsole(Client, "[SM] You cleared the spawn location of %s.", TargetName);
		} else {
			PrintToChat(Client, "[SM] You cleared the spawn location of %s.", TargetName);
		}
		return Plugin_Handled;
	}
}

public PlayerSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
	decl Client;
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	new AdminId:id = GetUserAdmin(Client);

	if(GetConVarBool(sm_players_spawn_admin_only) && id == INVALID_ADMIN_ID) {
		return;
	}

	if(SpawnSet[Client]) {
		TeleportEntity(Client, SpawnPoint[Client], NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	SpawnSetDisabled = false;
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	SpawnSetDisabled = true;
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			SpawnSet[i] = false;
		}
	}  
	PrintToChatAll ("[SM] All player spawn points reset!");
}
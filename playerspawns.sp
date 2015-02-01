/**
 * Custom Spawn V1.4.0
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

#define __PS_ERROR -1
#define __PS_OK		0

new Handle:sm_players_spawn_admin_only = INVALID_HANDLE;
new Handle:sm_player_spawns = INVALID_HANDLE;

static Float:SpawnPoint[MAXPLAYERS+1][3];
static Float:SpawnAngle[MAXPLAYERS+1][3];
static bool:SpawnSet[MAXPLAYERS+1];
static bool:SpawnSetDisabled = false;

public Plugin:myinfo = {
	name = "Player Spawns",
	author = "David Y.",
	description = "Players set a custom spawnpoint for themselves.",
	version = "1.4.0",
	url = "http://www.davidvyee.com/"
}

public OnPluginStart() {
	CreateConVar("sm_player_spawns_version", "1.4.0", "Player Spawns Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_player_spawns = CreateConVar("sm_player_spawns", "1", "Respawn players to their custom locations on death; 0 - disabled, 1 - enabled");
	sm_players_spawn_admin_only = CreateConVar("sm_players_spawn_admin_only", "0", "Toggles Admin Only spawn saving; 0 - disabled, 1 - enabled", FCVAR_PLUGIN);
	RegConsoleCmd("sm_setspawn", Command_SetSpawn);
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

public bool:IsAdmin(Client) {
	if(GetUserAdmin(Client) == INVALID_ADMIN_ID) return false;
	else return true;
}

public SetSpawn(Client, Target) { 
	LogAction(Client, Target, "\"%L\" set the spawn location of \"%L\"", Client, Target);
	
	decl String:AdminName[MAX_NAME_LENGTH];
	decl String:TargetName[MAX_NAME_LENGTH];
	GetClientName(Client, AdminName, MAX_NAME_LENGTH);
	
	GetClientAbsOrigin(Client, SpawnPoint[Target]);
	GetClientEyeAngles(Client, SpawnAngle[Target]);
	SpawnSet[Target] = true;
	
	GetClientName(Target, TargetName, MAX_NAME_LENGTH);
	
	PrintToChat(Target, "[SM] Your spawn location was set to the location of %s.", AdminName);
	PrintToChat(Client, "[SM] You set the spawn location of %s.", TargetName);
}

public CopySpawn(Admin, DestinationTarget, SourceTarget) {
	if(DestinationTarget == SourceTarget) return __PS_OK; // no need to copy to self
	
	decl String:DestinationTargetName[MAX_NAME_LENGTH];
	decl String:SourceTargetName[MAX_NAME_LENGTH];
	LogAction(Admin, DestinationTarget, 
			"\"%L\" copied the spawn location of \"%L\"", 
			DestinationTarget, SourceTarget);
	
	GetClientName(DestinationTarget, DestinationTargetName, MAX_NAME_LENGTH);
	GetClientName(SourceTarget, SourceTargetName, MAX_NAME_LENGTH);
	
	if(SpawnSet[SourceTarget]) {
		for(new i=0; i<3; i++) {
			SpawnPoint[DestinationTarget][i] = SpawnPoint[SourceTarget][i];
			SpawnAngle[DestinationTarget][i] = SpawnAngle[SourceTarget][i];
		}
		SpawnSet[DestinationTarget] = true;
	} else {
		PrintToChat(Admin, 
				"[SM] You cannot copy %s's spawn because they have not set a custom spawn location.", 
				SourceTargetName);
		return __PS_ERROR;
	}
	
	PrintToChat(DestinationTarget, 
				"[SM] Your spawn location was set to the location of %s.", 
				SourceTargetName);
	PrintToChat(Admin, 
				"[SM] You set the spawn location of %s to %s.", 
				DestinationTargetName, SourceTargetName);
	return __PS_OK;
}

public Action:Command_SetSpawn(Client, Args) {
	new playerSpawnsState = GetConVarInt(sm_player_spawns);
	
	if(Args == 0) { // setting spawn on self
		if(playerSpawnsState == 0) {
			PrintToChat(Client, 
			"[SM] You cannot set your spawn location because player spawns has been disabled.");
			return Plugin_Handled;
		}

		if(SpawnSetDisabled == true) {
			PrintToChat(Client, "[SM] You cannot set your spawn right now.");
			return Plugin_Handled;
		}

		if(Client == 0) { // server cannot execute this command
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

		GetClientAbsOrigin(Client, SpawnPoint[Client]);
		GetClientEyeAngles(Client, SpawnAngle[Client]);
		SpawnSet[Client] = true;

		PrintToChat(Client, "[SM] Spawn location set.");
	} else {
		decl bool:isAdmin;
		
		if(Client == 0) isAdmin = false; // server cannot invoke this command
		else isAdmin = IsAdmin(Client);
		
		if(!isAdmin) {
			PrintToChat(Client, "[SM] You do not have access to this command.");
			return Plugin_Handled;
		}
		
		new String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));

		new String:target_name[2*MAX_TARGET_LENGTH];
		new target_list[MaxClients], target_count, bool:tn_is_ml;

		target_count = ProcessTargetString(
						arg,
						Client,
						target_list,
						MaxClients,
						0,
						target_name,
						sizeof(target_name),
						tn_is_ml);
		
		for (new i = 0; i < target_count; i++) {
			// don't need to set the spawn location on yourself again
			if(Args == 1) {
				if(target_list[i] != Client) {
					SetSpawn(Client, target_list[i]);
				}
			} else {
				new String:TargetPlayer[MAX_NAME_LENGTH];
				GetCmdArg(2, TargetPlayer, sizeof(TargetPlayer));
				StripQuotes(TargetPlayer);
				TrimString(TargetPlayer);
				
				decl Source;
				Source = -1;
				
				decl String:TestName[MAX_NAME_LENGTH];
				for(new Player = 1; Player <= MaxClients; Player++) {
					if(IsClientInGame(Player)) {
						GetClientName(Player, TestName, MAX_NAME_LENGTH);
						if(StrContains(TestName, TargetPlayer, false) != -1) {
							Source = Player;
						}
					}
				}
				
				if(Source != -1) {
					decl result;
					result = CopySpawn(Client, target_list[i], Source);
					if(result != __PS_OK) break; // terminate early if cannot copy from source
				}
				else {
					PrintToChat(Client, 
								"[SM] You could not set the spawn location of %s because %s was not found.", 
								TargetPlayer);
				}
			}
		}
	}

	return Plugin_Handled;
}

public Action:ClearSpawn(Client, Args) {
	new playerSpawnsState = GetConVarInt(sm_player_spawns);
	if(playerSpawnsState == 0) {
		PrintToChat(Client, "[SM] You cannot clear your spawn location because player spawns has been disabled.");
		return Plugin_Handled;
	}

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
		decl bool:isAdmin;

		if(Client == 0) {
			isAdmin = true;
		}
		else {
			new AdminId:id = GetUserAdmin(Client);
			if(id == INVALID_ADMIN_ID) {
				isAdmin = false;
			}
			else {
				isAdmin = true;
			}
		}

		if(!isAdmin) {
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
	new playerSpawnsState = GetConVarInt(sm_player_spawns);
	if(playerSpawnsState > 0) {
		decl Client;
		Client = GetClientOfUserId(GetEventInt(Event, "userid"));

		new AdminId:id = GetUserAdmin(Client);

		if(GetConVarBool(sm_players_spawn_admin_only) && id == INVALID_ADMIN_ID) {
			return;
		}

		if(SpawnSet[Client]) {
			TeleportEntity(Client, SpawnPoint[Client], SpawnAngle[Client], NULL_VECTOR);
		}
	}
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	SpawnSetDisabled = false;
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new playerSpawnsState = GetConVarInt(sm_player_spawns);
	if(playerSpawnsState > 0) {
		SpawnSetDisabled = true;
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				SpawnSet[i] = false;
			}
		}  
		//PrintToChatAll ("[SM] All player spawn points reset!");
	}
}
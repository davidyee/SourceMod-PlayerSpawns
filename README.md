PlayerSpawns
===========

<h2>Summary:</h2>

Allows players to respawn after death at a different location than the 
standard map spawn points using the sm_setspawn command. Once this command 
is invoked, the current player's location is stored as the new spawn point 
and saved for future respawns. The custom respawn point can be removed via 
the sm_clearspawn command after which further player spawns will be at the 
default map spawn points.

This plugin can be restricted for use only by admins by setting the 
sm_players_spawn_admin_only value to 1.

Some code adapted from almcaeobtac's Player Spawns plugin V1.2 at
https://forums.alliedmods.net/showthread.php?p=877834

<h2>Compatibility:</h2>
- Counter Strike: Global Offensive

<h2>Cvars:</h2>
- `sm_player_spawns_version = 1.2.0` (cannot be changed)
- `sm_player_spawns = 1` - Respawn players to their custom locations on death; 0 - disabled, 1 - enabled
- `sm_players_spawn_admin_only = 1` - Toggles Admin Only spawn saving; 0 - disabled, 1 - enabled

<h2>Cmds:</h2>
- `sm_setspawn`
- `sm_clearspawn`
- `sm_clearspawn <name>`

<h2>Installation:</h2>
- playerspawns.smx into /addons/sourcemod/plugins

<h2>Changelog:</h2>
- 1.2.0 (2015-01-24)
  - Add restoration of player spawn angles when respawning players to their custom spawn location
- 1.1.1 (2015-01-23)
  - Fix spawn points being reset for all players regardless of sm_player_spawns value
- 1.1.0 (2015-01-21)
  - Add `sm_player_spawns` cvar to allow enabling/disabling custom spawn locations
- 1.0.0 (2015-01-21)
  - Initial release 

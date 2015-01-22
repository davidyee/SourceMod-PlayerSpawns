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
`sm_player_spawns_version = 1.0.0` (cannot be changed)

`sm_players_spawn_admin_only = 1` - Toggles Admin Only spawn saving

<h2>Cmds:</h2>
- `sm_setspawn`
- `sm_clearspawn`
- `sm_clearspawn <name>`

<h2>Installation:</h2>
- playerspawns.smx into /addons/sourcemod/plugins

<h2>Changelog:</h2>
- 1.0.0 (2015-01-21)
  - Initial release 

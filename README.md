# PlayerSpawns

## Summary:

Allows players to respawn after death at a different location than the 
standard map spawn points using the sm_setspawn command. Once this command 
is invoked, the current player's location is stored as the new spawn point 
and saved for future respawns. The custom respawn point can be removed via 
the `sm_clearspawn` command after which further player spawns will be at the 
default map spawn points.

This plugin can be restricted for use only by admins by setting the 
`sm_players_spawn_admin_only` value to 1.

Some code adapted from [almcaeobtac's Player Spawns plugin V1.2](https://forums.alliedmods.net/showthread.php?p=877834
).

## Compatibility:

* Counter Strike: Global Offensive

## Cvars:

* `sm_player_spawns_version = 1.4.0` (cannot be changed)
* `sm_player_spawns = 1` - Respawn players to their custom locations on death; 0 - disabled, 1 - enabled
* `sm_players_spawn_admin_only = 1` - Toggles Admin Only spawn saving; 0 - disabled, 1 - enabled

## Cmds:

* `sm_setspawn`
* `sm_setspawn <name>`
* `sm_clearspawn`
* `sm_clearspawn <name>`

## Installation:

* playerspawns.smx into /addons/sourcemod/plugins

## Changelog:

* 1.4.0 (2015-02-01)
  * Add ability to set spawn of players groups via general targets (ie: @all, @ct, @t, @bots, @dead, @alive, etc.)
  * Add ability to copy a saved spawn point of a player to another player or player group's spawn point via `sm_setspawn <player-to-replace-spawn> <player-to-copy-spawn-from>`
  
* 1.3.0 (2015-01-25)
  * Add admin ability to set the spawn location of other players via `sm_setspawn <name>`
  
* 1.2.0 (2015-01-24)
  * Add restoration of player spawn angles when respawning players to their custom spawn location

* 1.1.1 (2015-01-23)
  * Fix spawn points being reset for all players regardless of sm_player_spawns value

* 1.1.0 (2015-01-21)
  * Add `sm_player_spawns` cvar to allow enabling/disabling custom spawn locations

* 1.0.0 (2015-01-21)
  * Initial release 

Ingame GSC timer for speedrunning ALL BO2 easter eggs. Automatic start, stop, and split functionality. Single GSC script that works seamlessly across every map. Accurate times down to increments of one game tick (50ms).

Latest release (2.6) [[download](https://github.com/HuthTV/T6-EE-Timer/releases/download/V2.6/EE_ingame_timer_2.6.gsc)]

## Installation
Place the gsc file in ```C:\Users\%username%\AppData\Local\Plutonium\storage\t6\scripts\zm``` and start playing

## Chat Restarts
Players can initiate a fast restart by typing `r`, `restart`, or `fast_restart` in the game chat. To simplify restarts, players can bind a key to the say command. For instance, `bind F2 say fast_restart`.

## Strafe Speed
EE leaderboards allow runs to use modified strafe values that match those of console. To revert modded values, set `strafe_unlocked 0`.  
PC defaults: `side:80% | back:70% ` — Console: `side:100% | back:100%`

## Persistent Upgrades & Bank
Upon spawning, players will be awarded all persistent upgrades except insta kill. Players bank will also be set to maximum amount. To change what upgrades are active, use to following boolean console dvars to enable/disable upgrades and bank fill.

`full_bank`
`pers_jugg`
`pers_boarding`
`pers_carpenter`
`pers_insta_kill`
`pers_nube_counter`
`pers_revivenoperk`
`pers_sniper_counter`
`pers_cash_back_prone`
`pers_cash_back_bought`
`pers_perk_lose_counter`
`pers_box_weapon_counter`
`pers_multikill_headshots`
`pers_pistol_points_counter`
`pers_double_points_counter`

## Network Frame Fix
In certain older versions of Plutonium (such as R2905), there exists an issue with the `wait_network_frame()` function, speeding up certain in-game events, most notably the spawnrate of zombies. This timer incorporates a fix for this particular issue, ensuring that gameplay on older Plutonium versions remains legitimate.
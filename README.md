Timer for speedrunning ALL BO2 Easter Eggs with automatic start, stop, and split functionality. Accurate times down to increments of one game tick (50ms). Supports both ingame GSC timer and LiveSplit. Built for Plutonium R4524 and newer.



## 💾 Installation
**Latest release 5.0 ➡️ [Download](https://github.com/HuthTV/T6-EE-Timer/releases/download/V5.0/T6EE_V5.0.gsc)**  
Place the `T6EE.gsc` file in ```C:\Users\%username%\AppData\Local\Plutonium\storage\t6\scripts\zm```

## ⏱️ LiveSplit Setup
To use LiveSplit you must install an ASL script in your layout. You can find it here [Download](https://github.com/HuthTV/T6-EE-Timer/releases/download/V5.0/T6EE_V5.0.asl)  
Right-click LiveSplit and choose `Edit Layout...`  
Click `+ > Control > Scriptable Auto Splitter` to add that component.  
Open the Auto Splitter component and set the script path to the `T6EE.asl` file.

<img width="488" height="197" alt="image" src="https://github.com/user-attachments/assets/6df7f646-ddea-4f05-8282-03ab46fa069c" />

If you don’t want to create your own LiveSplit files, you can download these premade layouts  
- [Tranzit](https://github.com/HuthTV/T6-EE-LiveSplit/releases/download/SplitFiles/tranzit.zip)  
- [Die Rise](https://github.com/HuthTV/T6-EE-LiveSplit/releases/download/SplitFiles/die_rise.zip)  
- [Mob of the Dead](https://github.com/HuthTV/T6-EE-LiveSplit/releases/download/SplitFiles/motd.zip)  
- [Buried](https://github.com/HuthTV/T6-EE-LiveSplit/releases/download/SplitFiles/buried.zip)  
- [Origins](https://github.com/HuthTV/T6-EE-LiveSplit/releases/download/SplitFiles/origins.zip)

## ⚙️ T6EE settings
The timer has several settings that persist between restarts and game sessions. These settings can be changed by typing commands directly into the ingame chat or by editing the file: `%localappdata%\Plutonium\storage\t6\raw\scriptdata\T6EE.cfg`

The following chat commands are available.  
| Command   | Description                                         |
| --------- | --------------------------------------------------- |
| timer   | Toggles the ingame timer (requires a map restart)   |
| strafe  | Switches strafe DVARs between console and PC values |
| speed   | Toggles the speedometer                             |
| restore | Resets your config file to default settings         |


## Chat Restarts
Players can initiate a fast restart by typing `r`, `restart`, or `fast_restart` in the game chat. To simplify restarts, players can bind a key to the say command. For example, `bind F2 say restart` in the game console.

## Persistent Upgrades, Bank, & Fridge 
Upon spawning, players will be awarded all persistent upgrades except Insta-Kill. The player's bank will also be set to the maximum amount. On Die Rise, an upgraded SVU will be placed in the player's fridge. To change which upgrades are active, use the following boolean console DVARs to enable or disable specific upgrades or bank fill.

```
full_bank
pers_jugg
pers_boarding
pers_carpenter
pers_insta_kill
pers_nube_counter
pers_revivenoperk
pers_sniper_counter
pers_cash_back_prone
pers_cash_back_bought
pers_perk_lose_counter
pers_box_weapon_counter
pers_multikill_headshots
pers_pistol_points_counter
pers_double_points_counter
```

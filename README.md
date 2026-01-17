# T6EE Speedrun Timer
All-in-one timer script for speedrunning every Black Ops II zombies Easter Egg. Features automatic start, stop, and split functionality. Accuracy down to one game tick (50ms). Supports both in-game GSC timer and LiveSplit. Compatible with Plutonium R4524 and newer.

## 📥 Installation
Download the latest release from the link below and place the `T6EE.gsc` file in your Plutonium scripts folder: 
<pre>C:\Users\%username%\AppData\Local\Plutonium\storage\t6\scripts\zm</pre>
### **Latest T6EE release 6.0 ➡️[Download](https://github.com/HuthTV/T6-EE-Timer/releases/download/V5.2/T6EE_5.2.gsc)**

## ⏱️ LiveSplit Setup
To connect LiveSplit with the timer, you must install an autosplitter script (asl file) in your layout. You can find it here **➡️[Download](https://github.com/HuthTV/T6-EE-Timer/releases/download/V5.2/T6EE_5.2.asl)**  

- Open the layout editor by right-clicking LiveSplit and selecting `Edit Layout...`  
- Click `+ > Control > Scriptable Auto Splitter` to add that component.
<img width="413" height="223" alt="image" src="https://github.com/user-attachments/assets/05fd17e3-2012-4dbe-9f0b-2eb32d4b7f06" />

- Double-click the auto splitter component and select the `T6EE.asl` file you downloaded..
<img width="481" height="96" alt="image" src="https://github.com/user-attachments/assets/a7d84ccd-c292-42e1-ad00-0c660f4e4234" />

- Make sure to set the timer to game time if you plan to pause during use.  
<img width="339" height="170" alt="image" src="https://github.com/user-attachments/assets/e269a899-e9a4-477f-960e-6d18f83a2cd0" />  

If you don’t wish to create your own LiveSplit files, you can download premade ones  
- [Tranzit](https://github.com/HuthTV/T6-EE-LiveSplit/releases/download/SplitFiles/tranzit.zip)  
- [Die Rise](https://github.com/HuthTV/T6-EE-LiveSplit/releases/download/SplitFiles/die_rise.zip)  
- [Mob of the Dead](https://github.com/HuthTV/T6-EE-LiveSplit/releases/download/SplitFiles/motd.zip)  
- [Buried](https://github.com/HuthTV/T6-EE-LiveSplit/releases/download/SplitFiles/buried.zip)  
- [Origins](https://github.com/HuthTV/T6-EE-LiveSplit/releases/download/SplitFiles/origins.zip)

## ⚙️ Config settings
The config file contains settings that persist between restarts and game sessions. These settings can be changed by typing commands directly into the in-game chat or by editing the cfg file: 
 <pre>%localappdata%\Plutonium\storage\t6\raw\scriptdata\T6EE\T6EE.cfg</pre>

## 💾 Stats data
The timer tracks restarts and completions for every map and for any number of players. Stats are saved in a text file and can be edited manually if desired:  
<pre>%localappdata%\Plutonium\storage\t6\raw\scriptdata\T6EE\T6EE.stats</pre>

## 💬 Chat commands

Various commands are available to enter straight into the game chat, found in table below.
| Command   | Description                                         |
| --------- | --------------------------------------------------- |
| timer     | Toggles the ingame timer (requires a reset)         |
| super     | Toggle super EE timing mode                         |
| strafe    | Switches strafe DVARs between console and PC values |
| speed     | Toggles the speedometer                             |
| tank      | Toggle origins tank push trigger                    |
| stats     | Toggle tracking reset/completions stats             |
| restore   | Resets your config file to default settings         |
| madeup    | Toggle madeup scripts                               |
| anticheat | Prevent anticheat form loading on map start         |


## 🔄 Chat Restarts
Players can initiate a fast restart by typing `r`, `restart`, or `fast_restart` in the game chat. To simplify restarts, players can bind a key to the say command. For example, `bind F2 say restart` in the game console.

## 🚫 Anti Cheat
To ensure fair play, several measures are in place to prevent players from gaining an unfair advantage through dvars or loaded scripts. The timer will automatically activate `cg_flashScriptHashes` and `cg_drawIdentifier` and execute the `flashScriptHashes` command at the start and end of each run. Additionally, a dvar monitor runs continuously, tracking any changes to dvar values. If a value falls outside the allowed range, it will be clearly displayed on-screen. The full list of tracked dvars can be found [here]. Any illegal dvar values detected on map load will be automatically corrected before timing begins.

## 🤡 Victis solo & Coop "madeup" scripts

Certain maps normally require a minimum number of players to complete the Easter Egg. This timer includes “madeup” code that lets players complete the egg with fewer than the required number. The code emulates the behaviors found in this repository:[T6-Any-Player-EE-Scripts](https://github.com/Hadi77KSA/Plutonium-T6-Any-Player-EE-Scripts/blob/7d890242c2cf3f8741382d1c7d30eeedc7fe588d). For full details, check out the repos [readme](https://github.com/Hadi77KSA/Plutonium-T6-Any-Player-EE-Scripts/blob/7d890242c2cf3f8741382d1c7d30eeedc7fe588d/README.md). These “madeup” features can be disabeled via the `EE_madeup` dvar.

## 🧭 Super Easter Egg Timing
Super Timing runs a single timer across all maps. Tranzit is unchanged, Die Rise and Buried will show the total time in-game. LiveSplit also won’t reset between maps. Buried has a super exlusive split for triggering the EE reward button after Sharpshooter.

## 🗄️ Fridge
On Die Rise, an upgraded SVU will be placed in each player's fridge. On Buried (solo), a TAR-21 MMS will be placed in the player's fridge.

## ✨ Persistent Upgrades and Bank 
Upon spawning, players will be awarded all persistent upgrades except Insta-Kill. The player's bank will also be set to the maximum amount. To change which upgrades are active, use the following boolean console DVARs to enable or disable specific upgrades.

```
pers_jugg
pers_boarding
pers_carpenter
pers_insta_kill
pers_nube_counter
pers_revivenoperk
pers_sniper_counter
pers_flopper_counter
pers_cash_back_prone
pers_cash_back_bought
pers_perk_lose_counter
pers_box_weapon_counter
pers_multikill_headshots
pers_pistol_points_counter
pers_double_points_counter
```

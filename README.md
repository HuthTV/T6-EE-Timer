# T6EE Speedrun Timer
Timer for speedrunning all Black Ops II Easter Eggs. Features automatic start, stop, and split functionality. Accuracy down to one game tick (50ms). Supports both in-game GSC timer and LiveSplit. Compatible with Plutonium R4524 and newer.

## 📥 Installation
Download the latest release from the link below and place the `T6EE.gsc` file in your Plutonium scripts folder: 
<pre>C:\Users\%username%\AppData\Local\Plutonium\storage\t6\scripts\zm</pre>
### **Latest T6EE release 5.1b ➡️[Download](https://github.com/HuthTV/T6-EE-Timer/releases/download/V5.1b/T6EE_5.1b.gsc)**

## ⏱️ LiveSplit Setup
To connect LiveSplit with the timer, you must install an autosplitter script (asl file) in your layout. You can find it here **➡️[Download](https://github.com/HuthTV/T6-EE-Timer/releases/download/V5.1/T6EE_5.1.asl)**  

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
| timer   | Toggles the ingame timer (requires a map restart)   |
| strafe  | Switches strafe DVARs between console and PC values |
| speed   | Toggles the speedometer                             |
| stats   | Hide/show stats at start of run                     |
| restore | Resets your config file to default settings         |


## 🔄 Chat Restarts
Players can initiate a fast restart by typing `r`, `restart`, or `fast_restart` in the game chat. To simplify restarts, players can bind a key to the say command. For example, `bind F2 say restart` in the game console.

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
pers_cash_back_prone
pers_cash_back_bought
pers_perk_lose_counter
pers_box_weapon_counter
pers_multikill_headshots
pers_pistol_points_counter
pers_double_points_counter
```

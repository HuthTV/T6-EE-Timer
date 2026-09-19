# T6EE Speedrun Timer
All-in-one timer script for speedrunning every Black Ops II zombies Easter Egg. Features automatic start, stop, and split functionality. Accuracy down to one game tick (50ms). Supports both in-game GSC timer and LiveSplit on solo via plutonium plugin built for Plutonium R5334 and later.

## 📺 Video Tutorial
soon

## 📥 Installation

### T6EE Timer Script → [Download](https://github.com/HuthTV/T6-EE-Timer/releases/download/V6.2/T6EE_6.2.gsc)

Download the latest `T6EE.gsc` and place it in the Plutonium scripts folder:

    C:\Users\%username%\AppData\Local\Plutonium\storage\t6\scripts\zm\

## ⏱️ LiveSplit Setup

### T6EE Plugin → [Download](https://github.com/HuthTV/T6-EE-Timer/releases/download/V6.2/T6EE_Plugin.dll)

Download `T6EE_Plugin.dll` and place it in the Plutonium plugins folder:

    C:\Users\%username%\AppData\Local\Plutonium\plugins\

1. Right-click LiveSplit and select `Control` → `Start TCP Server`.
   - Alternatively, go to `Settings` → `Startup Behavior` and enable `Start TCP Server`.
2. Start the game in LAN mode.
3. Press `F9` in-game to open the splits menu.

If you don't want to create your own LiveSplit files, you can download premade splits:

- [Tranzit](https://github.com/HuthTV/T6-EE-Timer/releases/download/V0.1/tranzit_maxis_splits.lss) Maxis
- [Tranzit](https://github.com/HuthTV/T6-EE-Timer/releases/download/V0.1/tranzit_richtofen_splits.lss) Richtofen
- [Die Rise](https://github.com/HuthTV/T6-EE-Timer/releases/download/V0.1/die_rise_splits.lss)
- [Mob of the Dead](https://github.com/HuthTV/T6-EE-Timer/releases/download/V0.1/motd_splits.lss)
- [Buried](https://github.com/HuthTV/T6-EE-Timer/releases/download/V0.1/buried_splits.lss)
- [Origins](https://github.com/HuthTV/T6-EE-Timer/releases/download/V0.1/origins_splits.lss)
- [Super](https://github.com/HuthTV/T6-EE-Timer/releases/download/V0.1/super_maxis_splits.lss) Maxis
- [Super](https://github.com/HuthTV/T6-EE-Timer/releases/download/V0.1/super_richtofen_splits.lss) Richtofen

## ⚙️ Config Settings

The config file contains settings that persist between restarts and game sessions. These settings can be changed by typing commands directly into the in-game chat or by editing the config file:

    %localappdata%\Plutonium\storage\t6\raw\scriptdata\T6EE\T6EE.cfg

## 💾 Stats Data

The timer tracks restarts and completions for every map and any number of players. Stats are saved in a text file and can be edited manually if desired:

    %localappdata%\Plutonium\storage\t6\raw\scriptdata\T6EE\T6EE.stats

## 💬 Chat commands

Various commands are available to enter straight into the game chat, as shown in the table below.
| Command   | Description                                         |
| --------- | --------------------------------------------------- |
| anticheat | Pause anticheat from loading on map start           |
| madeup    | Toggle madeup scripts                               |
| restore   | Reset your config file to default settings          |
| speed     | Toggle the speedometer                              |
| stats     | Toggle tracking reset/completion stats              |
| super     | Toggle super EE timing mode                         |
| timer     | Toggle the ingame timer (requires a reset)          |
| fridge    | Store a weapon in your fridge             |

## 🗄️ Fridge
Players may set their fridge weapon with the fridge command Example `fridge tar21_upgraded_zm+mms`. Note that when super mode is active, every player will have a different fridge slot that will only populate the fridge when Tranzit is started. You can see the full list of legal weapons [here](https://raw.githubusercontent.com/HuthTV/T6-EE-Timer/refs/heads/main/fridge_list.md)

## 🔄 Chat Restarts
Players can initiate a fast restart by typing `r`, `restart`, or `fast_restart` in the game chat. To simplify restarts, players can bind a key to the say command. For example, `bind F2 say restart` in the game console.

## 📺 Despawn FOV Clamp
In BO2 Zombies, the host player’s `cg_fov` value is used when calculating zombie despawning behavior. This timer script clamps the calculation to the base game FOV range of 65–90. Using FOV values outside this range will not change the game behavior.

## 🚫 Anti Cheat
To ensure fair play, several measures are in place to prevent players from gaining an unfair advantage through dvars or loaded scripts. The timer will automatically activate `cg_flashScriptHashes` and `cg_drawIdentifier` and execute the `flashScriptHashes` command at the start and end of each run. Additionally, a dvar monitor runs continuously, tracking any changes to dvar values. If a value falls outside the allowed range, it will be clearly displayed on-screen. Any illegal dvar values detected on map load will be automatically corrected before timing begins. The full list of tracked dvars can be found [here](https://github.com/HuthTV/T6-EE-Timer/blob/r6.0/tracked_dvars.md)

## 🤡 Victis solo & Coop "madeup" scripts

Certain maps normally require a minimum number of players to complete the Easter Egg. This timer includes “madeup” code that lets players complete the egg with fewer than the required number. These “madeup” features can be disabled via the `EE_madeup` dvar. The timer emulates the behaviors found in this repository: [T6-Any-Player-EE-Scripts](https://github.com/Hadi77KSA/Plutonium-T6-Any-Player-EE-Scripts/blob/7d890242c2cf3f8741382d1c7d30eeedc7fe588d). For full details, check out the repos [readme](https://github.com/Hadi77KSA/Plutonium-T6-Any-Player-EE-Scripts/blob/7d890242c2cf3f8741382d1c7d30eeedc7fe588d/README.md)

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

## Plugin dependencies

| Dependency | Version | Pinned commit |
| --- | --- | --- |
| [Plutonium SDK](https://github.com/plutoniummod/plutonium-sdk) | v1 | `17e9a0a4d5e1133b50f879e3db07e97d1bf92e10` |
| [Dear ImGui](https://github.com/ocornut/imgui) | v1.91.9b | `f5befd2d29e66809cd1110a152e375a7f1981f06` |
| [MinHook](https://github.com/tsudakageyu/minhook) | v1.3.4 | `c3fcafdc10146beb5919319d0683e44e3c30d537` |
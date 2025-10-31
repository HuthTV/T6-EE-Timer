#DEFINE T6EE_ACTIVE_COLOR (0.99, 0.91, 0.99)
#DEFINE T6EE_COMPLETE_COLOR (0.99, 0.58, 0.99)
#include maps\mp\_utility;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include common_scripts\utility;

main()
{
    setdvar("scr_allowFileIo", 1);
    level.T6EE_LIVESPLIT_FILE = "T6EE/T6EE.dat";
    level.T6EE_SETTINGS_FILE = "T6EE/T6EE.cfg";
    level.T6EE_STATS_FILE = "T6EE/T6EE.stats";

    init_default_config();
    if(fs_testfile(level.T6EE_SETTINGS_FILE))
    {
        read_config();  //read cfg file if exists
    }
    else
    {
        write_config(); //create default cfg file
    }
    //write empty livesplit data file
    livesplit_handle = fs_fopen(level.T6EE_LIVESPLIT_FILE, "write");
    fs_write( livesplit_handle, "zm_map|0|0" );    // map|split|time
    fs_fclose( livesplit_handle );
}

init()
{
    if(level.scr_zm_ui_gametype_group != "zclassic") return; //dont run on survival maps
    level.T6EE_HUD = int(level.T6EE_CFG["hud_timer"]);
    level.T6EE_SPLIT_NUM = 0;
    level.T6EE_SPLIT = [];
    level.T6EE_X_OFFSET = 2;
    level.T6EE_Y_INCREMENT = 16;
    level.T6EE_Y_OFFSET = -34;
    level.T6EE_Y_MAP_OFFSET["zm_prison"] = 16;
    level.T6EE_Y_MAP_OFFSET["zm_tomb"] = 76;
    if(isdefined(level.T6EE_Y_MAP_OFFSET[level.script])) level.T6EE_Y_OFFSET = level.T6EE_Y_MAP_OFFSET[level.script];
    flag_init("timer_end");
    flag_init("timer_start");

    if(level.T6EE_HUD) //HUD off → prevent conflict with other scripts
    {
        thread overflow_manager();
        thread precache_hud_strings();
    }

    thread on_player_connect();
    thread verify_network_frame();
    thread run_anticheat();
    thread apply_strafe_settings();
    thread upgrade_dvars();
    thread setup_splits_and_labels();
    thread handle_chat_commands();
    thread game_over_wait();
    thread stats_tracking();
    timer_start_wait();

    for(split = 0; split < level.T6EE_SPLIT_LIST.size; split++)
    {
        level.T6EE_SPLIT[split] = spawnstruct();
        if(level.T6EE_HUD) level.T6EE_SPLIT[split].timer = newhudelem();
        level.T6EE_SPLIT[split] process_split();
        wait 0.05;
    }
    flag_set("timer_end");
}

stats_tracking()
{
    //permanent stats

    init_stats();
    if(fs_testfile(level.T6EE_STATS_FILE))
    {
        read_stats();
    }
    else
    {
        write_stats();
    }

    flag_wait("initial_players_connected");
    //init session stats
    restarts_string = level.script + "_" + level.players.size + "p_restarts";
    completions_string = level.script + "_" + level.players.size + "p_completions";
    set_dvar_if_unset(restarts_string, 0);
    set_dvar_if_unset(completions_string, 0);

    //run starts
    flag_wait("timer_start");
    level.T6EE_STATS[restarts_string] = int(level.T6EE_STATS[restarts_string]) + 1;
    setdvar(restarts_string, getdvarint(restarts_string) + 1);
    write_stats();
    if(int(level.T6EE_CFG["show_stats"]))
        iprintln("[Restarts] Total: " + level.T6EE_STATS[restarts_string] + " Session: " + getdvarint(restarts_string) + "\n[Completions] Total: " + level.T6EE_STATS[completions_string] + " Session: " + getdvarint(completions_string));

    //run ends
    flag_wait("timer_end");
    level.T6EE_STATS[completions_string] = int(level.T6EE_STATS[completions_string]) + 1;
    setdvar(completions_string, getdvarint(completions_string) + 1);
    write_stats();
}


init_stats()
{
    level.T6EE_STATS = [];
    maps = array("zm_transit_", "zm_highrise_", "zm_prison_", "zm_buried_", "zm_tomb_");
    foreach(map in maps)
    {
        for(i = 4; i > 0; i--) level.T6EE_STATS[map + i + "p_completions"] = 0;
        for(i = 4; i > 0; i--) level.T6EE_STATS[map + i + "p_restarts"] = 0;
    }
}

read_stats()
{
    stats_handle = fs_fopen(level.T6EE_STATS_FILE, "read");
    stats = fs_read(stats_handle);
    tokens = strtok(stats, "\n");
    foreach(stat in tokens)
    {
        split = strtok(stat, "=");
        println("Loaded stat: " + split[0] + " = " + split[1]);
        level.T6EE_STATS[split[0]] = split[1];
    }
    fs_fclose(stats_handle);
}

write_stats()
{
    fs_remove(level.T6EE_STATS_FILE);
    stats_handle = fs_fopen(level.T6EE_STATS_FILE, "write");
    array_key = getarraykeys( level.T6EE_STATS );
    foreach(stat in array_key)
    {
        fs_write(stats_handle, stat + "=" + level.T6EE_STATS[stat] + "\n" );
    }
    fs_fclose(stats_handle);
}

on_player_connect()
{
    level endon("game_ended");
    while(true)
    {
        level waittill("connected", player);
        player thread on_player_spawned();
        if(int(level.T6EE_CFG["hud_speed"]) == 1)
            player thread speedometer();
    }
}

on_player_spawned()
{
    self waittill("spawned_player");
    if(upgrades_active()) self thread upgrades_bank();
    wait 2.6;
    self iprintln("^8[^1R" + getSubStr(getDvar("version"), 23, 27) +"^8]" + "^8[^3T6EE^8][^5" + VERSION + "^8]^7 github.com/HuthTV/T6-EE-Timer");
}

process_split()
{
    self.split_index = level.T6EE_SPLIT_NUM;
    self.split_id = level.T6EE_SPLIT_LIST[self.split_index];

    if(level.T6EE_HUD)
    {
        self.split_label = level.T6EE_LABELS[self.split_id];
        self.timer draw_client_split(self.split_index);
    }
    self thread split_refresh();
    wait_for_split(self.split_id);
    if(self.split_id == "jetgun_power_off")
    {
        handle_tranzit_branch();
    }
    level.T6EE_SPLIT_NUM++;
}

split_refresh()
{
    while(true && !flag("game_over"))
    {
        time = gettime() - level.T6EE_START_TIME;

        if(level.T6EE_HUD)
        {
            frame_string = "^3" + self.split_label + " ^7" + game_time_string(time);
            self.split_string = frame_string;
            self.timer set_safe_text(frame_string);
        }

        write_livesplit_data(time);

        if(self.split_index < level.T6EE_SPLIT_NUM) break;
        wait 0.05;
    }
    if(!flag("game_over")) self.timer.color = T6EE_COMPLETE_COLOR;
}

handle_chat_commands()
{
    flag_wait("initial_blackscreen_passed");
    while(true)
    {
        level waittill("say", message, player);
        msg = tolower(message);

        switch (msg)
        {

            case "stats":
                status = int(level.T6EE_CFG["show_stats"]);
                level.T6EE_CFG["show_stats"] = !status;
                iprintln("Display stats " + (status ? "^1disabled" : "^2enabled"));
                write_config();
                break;

            case "timer":
                status = int(level.T6EE_CFG["hud_timer"]);
                level.T6EE_CFG["hud_timer"] = !status;
                iprintln("HUD Timer " + (status ? "^1disabled" : "^2enabled") + "^7 - use ^3fast_restart");
                write_config();
                break;

            case "strafe":
                status = int(level.T6EE_CFG["console_strafe"]);
                set_strafe_speed(!status);
                level.T6EE_CFG["console_strafe"] = !status;
                iprintln("Strafe speeds - " + (status ? "^2PC" : "^1Console"));
                write_config();
                break;

            case "speed":
                status = int(level.T6EE_CFG["hud_speed"]);
                level.T6EE_CFG["hud_speed"] = !status;
                speed_active = isdefined(player.speedometer);
                if(speed_active)
                {
                    player notify( "kill_speedometer" );
                    player.speedometer destroy();
                }
                else
                {
                    player thread speedometer();
                }
                player iprintln("Speedometer - " + (speed_active ? "^1disabled" : "^2enabled"));
                write_config();
                break;

            case "restore":
                if(player ishost())
                {
                    init_default_config();
                    write_config();
                    player iprintln("Settings restored to default");
                }
                else
                {
                    player iprintln("Host only command");
                }
                break;

            case "r":
            case "restart":
            case "fast_restart":
                map_restart();
                break;
        }
    }
}

set_speedometer_color()
{

    velocity = int(length(self getvelocity() * (1, 1, 0))); //ignore vertical velocity
    self.speedometer setValue(velocity);

    if(isdefined( self.afterlife ) && self.afterlife )
    {
        self.speedometer.color = (0.6, 1.0, 1.0);      //pale cyan
        self.speedometer.glowcolor = (0.3, 0.8, 1.0);  //cyan glow
        return;
    }

    //Speed range for color gradient
    if(self hasperk("specialty_longersprint"))
    {
        min_speed = 310.0;
        max_speed = 390.0;
    }
    else
    {
        min_speed = 260.0;
        max_speed = 350.0;
    }

    //clamp value 0-1
    ratio = (velocity - min_speed) / (max_speed - min_speed);
    ratio = max(0, min(1, ratio));

    if (ratio < 0.5)
    {
        rt = ratio / 0.5;
        self.speedometer.color = (0.6 + 0.4 * rt, 1.0, 0.6); // green -> yellow
        self.speedometer.glowcolor = (0.4 + 0.3 * rt, 0.7, 0.4);
    }
    else
    {
        rt = (ratio - 0.5) / 0.5;
        self.speedometer.color = (1.0, 1.0 - 0.8 * rt, 0.6 - 0.6 * rt); // yellow -> red
        self.speedometer.glowcolor = (0.7, 0.7 - 0.6 * rt, 0.4 - 0.4 * rt);
    }
}

speedometer()
{
    self endon("kill_speedometer");
    flag_wait("timer_start");
    self.speedometer = createfontstring("default" , 1.4);
    self.speedometer.alpha = 0.8;
    self.speedometer.hidewheninmenu = 1;
    self.speedometer setpoint("CENTER", "CENTER", "CENTER", 190);

    while (true)
    {
        self set_speedometer_color();
        wait 0.05;
    }
}

apply_strafe_settings()
{
    console_strafe = int(level.T6EE_CFG["console_strafe"]);
    set_strafe_speed( console_strafe );
}

draw_client_split( index )
{
    self.sort = 2000;
    self.alignx = "left";
    self.aligny = "center";
    self.horzalign = "user_left"; // user_left respects aspect ratio
    self.vertalign = "top";
    self.x = level.T6EE_X_OFFSET;
    self.y = level.T6EE_Y_OFFSET + (index * level.T6EE_Y_INCREMENT);
    self.fontscale = 1.4;
    self.hidewheninmenu = 0;
    self.alpha = 0.8;
    self.color = T6EE_ACTIVE_COLOR;
}

timer_start_wait()
{
    level thread game_start_check();
    level thread mob_start_check( level.script == "zm_prison" );
    flag_wait("timer_start");

}

game_start_check()
{
    flag_wait("initial_blackscreen_passed");
    if(!isdefined(level.T6EE_START_TIME))
    {
        level.T6EE_START_TIME = gettime();
        flag_set("timer_start");
    }
}

mob_start_check( is_mob )
{
    if(!is_mob) return;
    flag_wait("initial_players_connected");
    players = getplayers();
    while(!flag("timer_start"))
    {
        foreach(ghost in players)
        {
            if(isdefined(ghost.afterlife_visionset) && ghost.afterlife_visionset == 1)
            {
                wait 0.45;
                if(!isdefined(level.T6EE_START_TIME))
                {
                    level.T6EE_START_TIME = gettime();
                    flag_set("timer_start");
                    return;
                }
            }
        }
        wait 0.05;
    }
}

handle_tranzit_branch()
{
    side = level.T6EE_SIDE;
    if(side == "richtofen")
    {
        self.split_label = "Jetgun";
        level.T6EE_SPLIT_LIST = combinearrays(level.T6EE_SPLIT_LIST, array("tower", "EMP"));
    }
    else if(side == "maxis")
    {
        self.split_label = "Power off";
        level.T6EE_SPLIT_LIST = combinearrays(level.T6EE_SPLIT_LIST, array("turbines"));
    }
}

game_over_wait()
{
    flag_init("game_over");
    level waittill("end_game");
    wait 0.1; // dont conflict with origins/mob coop ending
    flag_set("game_over");
}

write_livesplit_data( time )
{
        livesplit_handle = fs_fopen(level.T6EE_LIVESPLIT_FILE, "write");
        livesplit_data = level.script + "|" + level.T6EE_SPLIT_NUM + "|" + (time);
        fs_write( livesplit_handle, livesplit_data );
        fs_fclose( livesplit_handle );
}

wait_for_split(split)
{
    switch (split)
    {
        //Tranzit
        case "jetgun_power_off":
            level waittill("power_event_complete");
            split = false;
            while(!split)
            {
                if( level.sq_progress["rich"]["A_jetgun_built"] > 0 )
                {
                    split = true;
                    level.T6EE_SIDE = "richtofen";
                    continue;
                }

                if( level.power_event_in_progress )
                {
                    split = true;
                    level.T6EE_SIDE = "maxis";
                    continue;
                }

                wait 0.05;
            }
            break;

        case "tower":
            while(level.sq_progress["rich"]["A_jetgun_tower"] == 0) wait 0.05;
            break;

        case "EMP":
            while(level.sq_progress["rich"]["FINISHED"] == 0) wait 0.05;
            break;

        case "turbines":
            while(level.sq_progress["maxis"]["FINISHED"] == 0) wait 0.05;
            break;

        //Die Rise
        case "highrise_symbols":
            flag_wait("sq_atd_drg_puzzle_complete");
            break;

        case "highrise_perks":
            level waittill("sq_fireball_hit_player");
            break;

        //Mob
        case "dryer":
            flag_wait("dryer_cycle_active");
            break;

        case "gondola_1":
        case "gondola_2":
        case "gondola_3":
            flag_wait("gondola_initialized");
            flag_wait("gondola_in_motion");
            break;

        case "plane_1":
        case "plane_2":
        case "plane_3":
            flag_waitopen("plane_boarded");
            flag_wait("plane_boarded");
            break;

        case "codes":
            level waittill_multiple("nixie_final_" + 386, "nixie_final_" + 481, "nixie_final_" + 101, "nixie_final_" + 872);
            break;

        case "headphones":
            wait 10;
            while( isdefined(level.m_headphones) ) wait 0.05;
            break;

        case "fight":
            level waittill("showdown_over");
            wait 2;
            break;

        //Buried
        case "boxhit":
            flag_wait("chest_has_been_used");
            break;

        case "ghosts":
            flag_wait("spawn_ghosts");
            break;

        case "cipher":
            wait_for_buildable("buried_sq_oillamp");
            break;

        case "time_travel":
        while(!flag("sq_tpo_special_round_active") && !flag("sq_wisp_saved_with_time_bomb")) wait 0.05;
            break;

        case "sharpshooter":
            level waittill_any("sq_richtofen_complete", "sq_maxis_complete");
            break;

        //Origins
        case "NML":
            flag_wait("activate_zone_nml");
            break;

        case "boxes":
            while(level.n_soul_boxes_completed < 4) wait 0.05;
            wait 4.3;
            break;

        case "staff_1":
        case "staff_2":
        case "staff_3":
        case "staff_4":
            curr = level.n_staffs_crafted;
            while(curr == level.n_staffs_crafted && level.n_staffs_crafted < 4) wait 0.05;
            break;

        case "rain_fire":
            flag_wait("ee_mech_zombie_hole_opened");
            break;

        case "AFD":
            flag_wait("ee_all_staffs_placed");
            break;

        case "freedom":
            flag_wait("ee_samantha_released");
            level waittill("end_game");
            break;
    }
}

run_anticheat()
{
    setdvar("cg_flashScriptHashes", 1);
    setdvar("cg_drawIdentifier", 1);
    flag_wait("timer_end");
    cmdexec("flashScriptHashes");
}

set_strafe_speed( use_console )
{
    setDvar("player_backSpeedScale", 0.7 + (0.3 * use_console));
    setDvar("player_strafeSpeedScale", 0.8 + (0.2 * use_console));
}

upgrade_dvars()
{
    if(!upgrades_active()) return;
    foreach(upgrade in level.pers_upgrades)
    {
        foreach(stat_name in upgrade.stat_names)
            level.T6EE_upgrades[level.T6EE_upgrades.size] = stat_name;
    }

    insta = level.script != "zm_transit";
    set_dvar_if_unset("full_bank", 1);
    set_dvar_if_unset("pers_insta_kill", insta);

    foreach(pers_perk in  level.T6EE_upgrades)
        set_dvar_if_unset(pers_perk, 1);
}

upgrades_bank()
{
    foreach(upgrade in level.pers_upgrades)
    {
        for(i = 0; i < upgrade.stat_names.size; i++)
        {
            val = (getdvarint(upgrade.stat_names[i]) > 0) * upgrade.stat_desired_values[i];
            self maps\mp\zombies\_zm_stats::set_client_stat(upgrade.stat_names[i], val);
        }
    }

    flag_wait("initial_players_connected");

    if(level.script == "zm_highrise")
    {
        self maps\mp\zombies\_zm_stats::clear_stored_weapondata();
        self player_rig_fridge("svu_upgraded_zm+vzoom");
    }

    if(level.script == "zm_buried" && level.players.size == 1)
    {
        self maps\mp\zombies\_zm_stats::clear_stored_weapondata();
        self player_rig_fridge("tar21_upgraded_zm+mms");
    }

    flag_wait("initial_blackscreen_passed");
    if(getdvarint("full_bank"))
    {
        self maps\mp\zombies\_zm_stats::set_map_stat("depositBox", level.bank_account_max, level.banking_map);
        self.account_value = level.bank_account_max;
    }
}

player_rig_fridge(weapon)
{
    self maps\mp\zombies\_zm_stats::clear_stored_weapondata();

    wpn = [];
    wpn["clip"] = weaponclipsize(weapon);
    wpn["stock"] = weaponmaxammo(weapon);
    wpn["dw_name"] = weapondualwieldweaponname(weapon);
    wpn["alt_name"] = weaponaltweaponname(weapon);
    wpn["lh_clip"] = weaponclipsize(wpn["dw_name"]);
    wpn["alt_clip"] = weaponclipsize(wpn["alt_name"]);
    wpn["alt_stock"] = weaponmaxammo(wpn["alt_name"]);

    self setdstat("PlayerStatsByMap", "zm_transit", "weaponLocker", "name", weapon);
    self setdstat("PlayerStatsByMap", "zm_transit", "weaponLocker", "clip", wpn["clip"]);
    self setdstat("PlayerStatsByMap", "zm_transit", "weaponLocker", "stock", wpn["stock"]);

    if (isdefined(wpn["alt_name"]) && wpn["alt_name"] != "")
    {
        self setdstat("PlayerStatsByMap", "zm_transit", "weaponLocker", "alt_name", wpn["alt_name"]);
        self setdstat("PlayerStatsByMap", "zm_transit", "weaponLocker", "alt_clip", wpn["alt_clip"]);
        self setdstat("PlayerStatsByMap", "zm_transit", "weaponLocker", "alt_stock", wpn["alt_stock"]);
    }

    if (isdefined(wpn["dw_name"]) && wpn["dw_name"] != "")
    {
        self setdstat("PlayerStatsByMap", "zm_transit", "weaponLocker", "dw_name", wpn["dw_name"]);
        self setdstat("PlayerStatsByMap", "zm_transit", "weaponLocker", "lh_clip", wpn["lh_clip"]);
    }
}

upgrades_active()
{
    return maps\mp\zombies\_zm_pers_upgrades::is_pers_system_active();
}

//Probably not needed anymore, safeguard for future pluto updates
verify_network_frame()
{
    flag_wait("initial_blackscreen_passed");
    while(incorrect_network_frame())
    {
        iprintln("^1BAD NETWORK FRAME");
        wait 5;
    }

}

incorrect_network_frame()
{
    solo = level.players.size == 1;
    COOP_DELAY = 50;
    SOLO_DELAY = 100;

    start = gettime();
    wait_network_frame();
    delay = gettime() - start;
    return (solo && delay != SOLO_DELAY) || (!solo && delay != COOP_DELAY);
}

init_default_config()
{

    level.T6EE_CFG = [];
    level.T6EE_CFG["hud_timer"] = 1;
    level.T6EE_CFG["hud_speed"] = 1;
    level.T6EE_CFG["console_strafe"] = 0;
    level.T6EE_CFG["show_stats"] = 1;
}

read_config()
{
    config_handle = fs_fopen(level.T6EE_SETTINGS_FILE, "read");
    settings = fs_read(config_handle);
    tokens = strtok(settings, "\n");
    foreach(setting in tokens)
    {
        split = strtok(setting, "=");
        println("Loaded setting: " + split[0] + " = " + split[1]);
        level.T6EE_CFG[split[0]] = split[1];
    }
    fs_fclose(config_handle);
}

write_config()
{
    fs_remove(level.T6EE_SETTINGS_FILE);
    config_handle = fs_fopen(level.T6EE_SETTINGS_FILE, "write");
    array_key = getarraykeys( level.T6EE_CFG );
    foreach(setting in array_key)
    {
        fs_write( config_handle, setting + "=" + level.T6EE_CFG[setting] + "\n" );
    }
    fs_fclose(config_handle);
}

setup_splits_and_labels()
{
    flag_wait("initial_players_connected");

    // ====== Split Name Labels ======

    // Tranzit
    level.T6EE_LABELS["jetgun_power_off"] = "Jetgun/Power off";
    level.T6EE_LABELS["turbines"] = "Turbines";
    level.T6EE_LABELS["tower"] = "Tower";
    level.T6EE_LABELS["EMP"] = "Lights";

    // Die Rise
    level.T6EE_LABELS["highrise_symbols"] = "Symbols";
    level.T6EE_LABELS["highrise_perks"] = "High Maintenance";

    // Mob of the Dead
    level.T6EE_LABELS["dryer"] = "Dryer";
    level.T6EE_LABELS["gondola_1"] = "Gondola I";
    level.T6EE_LABELS["gondola_2"] = "Gondola II";
    level.T6EE_LABELS["gondola_3"] = "Gondola III";
    level.T6EE_LABELS["plane_1"] = "Plane I";
    level.T6EE_LABELS["plane_2"] = "Plane II";
    level.T6EE_LABELS["plane_3"] = "Plane III";
    level.T6EE_LABELS["codes"] = "Codes";
    level.T6EE_LABELS["headphones"] = "Headphones";
    level.T6EE_LABELS["fight"] = "Showdown";

    // Buried
    level.T6EE_LABELS["boxhit"] = "Boxhit";
    level.T6EE_LABELS["ghosts"] = "Ghosts";
    level.T6EE_LABELS["cipher"] = "Cipher";
    level.T6EE_LABELS["time_travel"] = "Time Travel";
    level.T6EE_LABELS["sharpshooter"] = "Sharpshooter";

    // Origins
    level.T6EE_LABELS["NML"] = "NML";
    level.T6EE_LABELS["boxes"] = "Boxes";
    level.T6EE_LABELS["staff_1"] = "Staff I";
    level.T6EE_LABELS["staff_2"] = "Staff II";
    level.T6EE_LABELS["staff_3"] = "Staff III";
    level.T6EE_LABELS["staff_4"] = "Staff IV";
    level.T6EE_LABELS["AFD"] = "AFD";
    level.T6EE_LABELS["rain_fire"] = "Rain Fire";
    level.T6EE_LABELS["freedom"] = "Freedom";

    // ====== Split Lists ======

    splits = [];
    splits["zm_transit"] = array("jetgun_power_off");
    splits["zm_highrise"] = strtok("highrise_symbols|highrise_perks", "|");

    if(level.players.size == 1)
    {
        splits["zm_prison"] = strtok("dryer|gondola_1|plane_1|gondola_2|plane_2|gondola_3|plane_3|codes|headphones", "|");
        splits["zm_buried"] = strtok("boxhit|ghosts|cipher|time_travel|sharpshooter", "|");
        splits["zm_tomb"] = strtok("NML|boxes|staff_1|staff_2|staff_3|staff_4|AFD|rain_fire|freedom", "|");
    }
    else
    {
        splits["zm_prison"] = strtok("plane_1|plane_2|plane_3|codes|fight", "|");
        splits["zm_buried"] = strtok("cipher|time_travel|sharpshooter", "|");
        splits["zm_tomb"] = strtok("boxes|AFD|freedom", "|");
    }

    level.T6EE_SPLIT_LIST = splits[level.script];
}

set_safe_text(text)
{
	level.string_count += 1;

	level notify("textset");  // Notify overflow monitor on setText
    self.text_string = text;
	self setText(text);
}

overflow_manager()
{
    level endon("game_ended");
	level endon("host_migration_begin");
    flag_wait("timer_start");

    // all strings allocated after this will be periodically removed
    level.overflow = newhudelem();
    level.overflow setText("overflow");
    level.overflow.alpha = 0;

    level.string_count = 0;
    max_string_count = 50;

    while(true)
    {
            level waittill("textset");

            if(level.string_count >= max_string_count)
            {
                level.overflow ClearAllTextAfterHudElem();
                level.string_count = 0;

                foreach(elem in level.T6EE_SPLIT)
                {
                    if(isdefined(elem.timer))
                        elem.timer set_safe_text(elem.split_string);
                }
            }
    }
}

precache_hud_strings()
{
    //precache string that are normally not precached to avoid timer clearing them
    switch(level.script)
    {
        case "zm_transit":
            precachestring( &"ZOMBIE_EQUIP_RIOTSHIELD_HOWTO");
            precachestring( &"ZOMBIE_EQUIP_ELECTRICTRAP_HOWTO");
            precachestring( &"ZOMBIE_EQUIP_TURBINE_HOWTO");
            precachestring( &"ZOMBIE_EQUIP_JETGUN_HOWTO");
            precachestring( &"ZOMBIE_EQUIP_TURRET_HOWTO");
            break;

        case "zm_highrise":
            precachestring( &"ZM_HIGHRISE_EQUIP_SPRINGPAD_HOWTO");
            precachestring( &"ZM_HIGHRISE_EQUIP_SLIPGUN_PICKUP_HINT_STRING");
            precachestring( &"ZM_HIGHRISE_EQUIP_SLIPGUN_HOWTO");
            break;

        case "zm_prison":
            precachestring( &"ZM_PRISON_AFTERLIFE_HOWTO");
            precachestring( &"ZM_PRISON_AFTERLIFE_HOWTO_2");
            precachestring( &"ZM_PRISON_TOMAHAWK_TUTORIAL");
            precachestring( &"ZOMBIE_EQUIP_RIOTSHIELD_PICKUP_HINT");
            precachestring( &"ZOMBIE_EQUIP_RIOTSHIELD_HOWTO");
            precachestring( &"ZM_PRISON_RIOTSHIELD_ATTACK");
            precachestring( &"ZM_PRISON_RIOTSHIELD_DEPLOY");
            precachestring( &"ZM_CRAFTABLES_CHANGE_BUILD");
            precachestring( &"ZM_PRISON_LIFE_OVER");
            precachestring( &"GAME_REVIVING");
            break;

        case "zm_buried":
            precachestring( &"ZM_BURIED_SQ_SEARCHING");
            precachestring( &"ZOMBIE_BUILD_PIECE_SWITCH");
            precachestring( &"ZOMBIE_EQUIP_TURBINE_HOWTO");
            precachestring( &"ZM_BURIED_EQ_SP_HTS");//springpad
            precachestring( &"ZM_BURIED_EQ_SW_HTS");//subwoof
            precachestring( &"ZM_BURIED_EQ_HC_HTS");//headchopper

            precachestring( &"ZM_BURIED_GIVING");
            precachestring( &"ZOMBIE_TIMEBOMB_PICKUP");
            precachestring( &"ZOMBIE_TIMEBOMB_HOWTO");

            precachestring( &"ZM_BURIED_BOOZE_G");
            precachestring( &"ZM_BURIED_BOOZE_B");
            precachestring( &"ZM_BURIED_I_NEED_BOOZE");
            precachestring( &"ZM_BURIED_I_SAID_BOOZE");

            precachestring( &"ZM_BURIED_CANDY_G");
            precachestring( &"ZM_BURIED_CANDY_B");
            precachestring( &"ZM_BURIED_I_WANT_CANDY");
            precachestring( &"ZM_BURIED_THATS_NOT_CANDY");

            precachestring( &"ZM_BURIED_DRAW");
            precachestring( &"ZM_BURIED_KEY_G");
            precachestring( &"ZM_BURIED_UNLOCKING");
            precachestring( &"ZM_BURIED_WB");
            precachestring( &"ZM_BURIED_WALLBUILD");
            precachestring( &"ZM_BURIED_RANDOM_WALLBUY");
            precachestring( &"ZM_BURIED_BUY_UNKNOWN_STUFF");
            break;

        case "zm_tomb":
            precachestring( &"ZOMBIE_EQUIP_RIOTSHIELD_PICKUP_HINT");
            precachestring( &"ZOMBIE_EQUIP_RIOTSHIELD_HOWTO");
            precachestring( &"ZM_CRAFTABLES_CHANGE_BUILD");
            precachestring( &"ZOMBIE_BUILDING");
            precachestring( &"ZM_TOMB_RU");
            precachestring( &"ZM_TOMB_OSO");
            precachestring( &"ZM_TOMB_GREL");
            precachestring( &"ZM_TOMB_DIHO");
            break;
    }

    precachestring( &"ZOMBIE_CLAYMORE_HOWTO");
    precachestring( &"ZOMBIE_PLAYERZOMBIE_DOWNED");
    precachestring( &"ZOMBIE_SUICIDING");

    flag_wait("initial_players_connected");
    //chache string that are player name specific ahead of time
    tmp_strings = [];
    runners = getplayers();

    // Shared strings
    foreach(p in runners)
    {
        tmp_strings[p.name + "ZPIRY"] = newhudelem();
        tmp_strings[p.name + "ZPIRY"] settext( &"ZOMBIE_PLAYER_IS_REVIVING_YOU", p);
        tmp_strings[p.name + "ZPIRY"].alpha = 0;

        tmp_strings[p.name + "ZPNTBR"] = newhudelem();
        tmp_strings[p.name + "ZPNTBR"] settext( &"ZOMBIE_PLAYER_NEEDS_TO_BE_REVIVED", p);
        tmp_strings[p.name + "ZPNTBR"].alpha = 0;

        tmp_strings[p.name + "ZRS"] = newhudelem();
        tmp_strings[p.name + "ZRS"] settext( &"ZOMBIE_REVIVING_SOLO", p);
        tmp_strings[p.name + "ZRS"].alpha = 0;
    }

    // mob/gins specific strings
    if(level.script == "zm_prison" || level.script == "zm_tomb")
    {
        foreach(p in runners)
        {
            tmp_strings[p.name + "GPIRY"] = newhudelem();
            tmp_strings[p.name + "GPIRY"] settext( &"GAME_PLAYER_IS_REVIVING_YOU", p);
            tmp_strings[p.name + "GPIRY"].alpha = 0;
        }
    }
}

game_time_string(duration)
{
	total_sec = int(duration / 1000);
    time_string = "";

    mn = int(total_sec / 60);       //minutes
    time_string += (mn > 9) ? int(mn) : "0" + int(mn);

    se = int(total_sec % 60);       //seconds
    time_string += (se > 9) ? ":" + se : ":0" + se;

    ce = (duration % 1000) / 10;    //centiseconds
    time_string += (ce > 9) ? "." + int(ce) : ".0" + int(ce);

	return time_string;
}

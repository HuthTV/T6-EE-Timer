#define VERSION "6.0"
#define CFG_FILE "T6EE/T6EE.cfg"
#define TIMER_FILE "T6EE/T6EE.dat"
#define STATS_FILE "T6EE/T6EE.stats"
#define GIT_LINK "github.com/HuthTV/T6-EE-Timer"
#define SOLO_NETWORK_FRAME 100
#define COOP_NETWORK_FRAME 50
#define SUPER_Y_INCREMENT 305
#define TIMER_Y_INCREMENT 16
#define TIMER_X_OFFSET 2
#define IS_MOB (level.script == "zm_prison")
#define IS_DIE_RISE (level.script == "zm_highrise")
#define IS_BURIED (level.script == "zm_buried")
#define IS_ORIGINS (level.script == "zm_tomb")
#define IS_TRANZIT (level.script == "zm_transit")
#define IS_SOLO (level.players.size == 1)
#define TIMER_ACTIVE_COLOR (0.99, 0.91, 0.99)
#define TIMER_COMPLETE_COLOR (0.99, 0.58, 0.99)
#define FS_WRITE_CLOSE(path, data) owc_handle = fs_fopen(path, "write"); fs_write(owc_handle, data); fs_fclose(owc_handle)
#define FS_READ_CLOSE(path, data) orc_handle = fs_fopen(path, "read"); data = fs_read(orc_handle); fs_fclose(orc_handle)
#define IS_VICTIS (IS_TRANZIT || IS_DIE_RISE || IS_BURIED)

#include maps\mp\_utility;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include common_scripts\utility;

main()
{
    if(level.scr_zm_ui_gametype_group != "zclassic") return; //dont run on survival maps
    thread madeup_replaces();
}

init()
{

    if(isdefined(level.oprac_version) && (getDvar("o_menu_gamemode") != "fullgame")) return; //Don't run on oprac modes
    setdvar("scr_allowFileIo", 1);
    init_default_config();
    if(fs_testfile(CFG_FILE))
        read_config();  //read cfg file if exists
    else
        write_config(); //create default cfg file

    flag_init("timer_end");
    flag_init("timer_start");
    level.T6EE_HUD = int(level.T6EE_CFG["hud_timer"]);
    level.T6EE_SPLIT_NUM = 0;
    level.T6EE_Y_OFFSET = -34;
    level.T6EE_Y_MAP_OFFSET["zm_prison"] = 16;
    level.T6EE_Y_MAP_OFFSET["zm_tomb"] = 76;
    level.T6EE_STATS_ACTIVE = int(level.T6EE_CFG["show_stats"]);
    level.T6EE_SUPER_TIMING = int(level.T6EE_CFG["super_timing"]);
    level.managed_text_huds = [];
    if(isdefined(level.T6EE_Y_MAP_OFFSET[level.script])) level.T6EE_Y_OFFSET = level.T6EE_Y_MAP_OFFSET[level.script];

    thread precache_hud_strings();
    thread overflow_manager();
    thread setup_start_data();
    thread on_player_connect();
    thread verify_network_frame();
    thread run_anticheat();
    thread upgrade_dvars();
    thread setup_splits_and_labels();
    thread handle_chat_commands();
    thread game_over_wait();

    if(level.T6EE_STATS_ACTIVE) thread stats_tracking();
    set_strafe_speed( int(level.T6EE_CFG["console_strafe"]) );

    timer_start_wait();
    level.T6EE_SPLIT = [];

    if((level.T6EE_HUD) && level.non_first_super_map)
    {
        level.T6EE_SUPER_HUD = create_tracked_hud();
        level.T6EE_SUPER_HUD thread super_timer();
    }

    for(split = 0; split < level.T6EE_SPLIT_LIST.size; split++)
    {
        level.T6EE_SPLIT[split] = spawnstruct();
        if(level.T6EE_HUD) level.T6EE_SPLIT[split].timer = create_tracked_hud();
        level.T6EE_SPLIT[split] process_split();
        wait 0.05;
    }

    flag_set("timer_end");
}

madeup_replaces()
{
    if(IS_MOB)
    {
        return;
    }

    if(IS_ORIGINS && int(level.T6EE_CFG["old_tank"]))
    {
        replacefunc(getfunction("maps/mp/zm_tomb_tank", "tank_push_player_off_edge"), ::replace_tank_push_player_off_edge);
        return;
    }

    flag_wait("initial_players_connected");
    navcard_set();
    level.starting_player_count = level.players.size;

    if(int(level.T6EE_CFG["madeup"]) && level.starting_player_count < 4)
    {
        if(IS_TRANZIT && IS_SOLO)
        {
            replacefunc(getfunction("maps/mp/zm_transit_sq", "maxis_sidequest_b"), ::replace_maxis_sidequest_b);
            replacefunc(getfunction("maps/mp/zm_transit_sq", "get_how_many_progressed_from"), ::replace_get_how_many_progressed_from);
        }

        if(IS_DIE_RISE)
        {
            replacefunc(getfunction("maps/mp/zm_highrise_sq_atd", "sq_atd_elevators"), ::replace_sq_atd_elevators);
            replacefunc(getfunction("maps/mp/zm_highrise_sq_atd", "sq_atd_drg_puzzle"), ::replace_sq_atd_drg_puzzle);
            replacefunc(getfunction("maps/mp/zm_highrise_sq_pts", "wait_for_all_springpads_placed"), ::replace_wait_for_all_springpads_placed);
            replacefunc(getfunction("maps/mp/zm_highrise_sq_pts", "pts_should_player_create_trigs"), ::replace_pts_should_player_create_trigs);
            replacefunc(getfunction("maps/mp/zm_highrise_sq_pts", "pts_should_springpad_create_trigs"), ::replace_pts_should_springpad_create_trigs);
            replacefunc(getfunction("maps/mp/zm_highrise_sq_pts", "pts_putdown_trigs_create_for_spot"), ::replace_pts_putdown_trigs_create_for_spot);
            replacefunc(getfunction("maps/mp/zm_highrise_sq_pts", "place_ball_think"), ::replace_place_ball_think);
        }

        if(IS_BURIED)
        {
            replacefunc(getfunction("maps/mp/zm_buried_sq_ctw", "ctw_max_fail_watch"), ::replace_ctw_max_fail_watch);
            replacefunc(getfunction("maps/mp/zm_buried_sq_tpo", "_are_all_players_in_time_bomb_volume"), ::replace_are_all_players_in_time_bomb_volume);
            replacefunc(getfunction("maps/mp/zm_buried_sq_ip", "sq_bp_set_current_bulb"), ::replace_sq_bp_set_current_bulb);
            replacefunc(getfunction("maps/mp/zm_buried_sq_ows", "ows_target_delete_timer"), ::replace_ows_target_delete_timer);
            replacefunc(getfunction("maps/mp/zm_buried_sq_ows", "ows_targets_start"), ::replace_ows_targets_start);
            replacefunc(getfunction("maps/mp/zm_buried_sq_ows", "sq_metagame"), ::replace_sq_metagame);
        }
    }
}

on_player_connect()
{
    level endon("game_ended");
    while(true)
    {
        level waittill("connected", player);
        player thread on_player_spawned();
        if(int(level.T6EE_CFG["hud_speed"]) == 1) player thread speedometer();
    }
}

on_player_spawned()
{
    self waittill("spawned_player");
    if(IS_VICTIS) self thread upgrades_bank();
    wait 2.6;
    self iprintln("^8[^1" + toupper(getDvar("shortversion")) +"^8][^3T6EE^8][^5" + VERSION + "^8]^7 " + GIT_LINK);
}

super_timer()
{
    self.sort = 2000;
    self.alignx = "left";
    self.aligny = "center";
    self.horzalign = "user_left"; // user_left respects aspect ratio
    self.vertalign = "top";
    self.x = TIMER_X_OFFSET;
    self.y = SUPER_Y_INCREMENT;
    self.fontscale = 1.4;
    self.hidewheninmenu = 0;
    self.alpha = 0.8;
    self.color = TIMER_ACTIVE_COLOR;

    flag_wait("timer_start");
    while(!flag("game_over") && !flag("timer_end"))
    {
        wait 0.05;
        time = level.timing_offset + gettime() - level.T6EE_START_TIME;
        frame_string = "^3Total ^7" + game_time_string(time);
        self.split_string = frame_string;
        self set_safe_text(frame_string);
    }
    if(IS_BURIED && flag("timer_end")) self.color = TIMER_COMPLETE_COLOR;
}

setup_start_data()
{
    level.timing_offset = 0;
    flag_wait("initial_players_connected");
    if(IS_VICTIS && level.T6EE_SUPER_TIMING) iprintln("Super EE timing ^2enabled");
    level.non_first_super_map = level.T6EE_SUPER_TIMING && (IS_DIE_RISE || IS_BURIED) && fs_testfile(TIMER_FILE);

    if(level.non_first_super_map)
    {
        //super timing, don't reset time
        livesplit_handle = fs_fopen(TIMER_FILE, "read");
        time = fs_read(livesplit_handle);
        data = strtok(time, "|");
        level.timing_offset = int(data[2]);
        fs_fclose( livesplit_handle );
    }
    else
    {
        //regular timing
        FS_WRITE_CLOSE(TIMER_FILE, "zm_map|0|0|0"); // map|split|time|solo
    }
}

stats_tracking()
{
    //permanent stats
    init_stats();
    if(fs_testfile(STATS_FILE))
        read_stats();
    else
        write_stats();
    flag_wait("initial_players_connected");

    //session stats
    mode = level.script + "_";
    if(level.T6EE_SUPER_TIMING == 1) mode = "super_";
    restarts_string = mode + level.players.size + "p_restarts";
    completions_string = mode + level.players.size + "p_completions";
    set_dvar_if_unset(restarts_string, 0);
    set_dvar_if_unset(completions_string, 0);

    //dont track mid run super maps
    if( !level.T6EE_SUPER_TIMING || IS_TRANZIT || !IS_VICTIS)
    {
        flag_wait("timer_start");
        level.T6EE_STATS[restarts_string] = int(level.T6EE_STATS[restarts_string]) + 1;
        setdvar(restarts_string, getdvarint(restarts_string) + 1);
        write_stats();
        wait 1; //wait for welcome message to fade
        iprintln("[Restarts] Total: " + level.T6EE_STATS[restarts_string] + " Session: " + getdvarint(restarts_string) + "\n[Completions] Total: " + level.T6EE_STATS[completions_string] + " Session: " + getdvarint(completions_string));
    }

    //track completions
    flag_wait("timer_end");
    if(level.T6EE_SUPER_TIMING && (IS_TRANZIT || IS_DIE_RISE)) return;
    level.T6EE_STATS[completions_string] = int(level.T6EE_STATS[completions_string]) + 1;
    setdvar(completions_string, getdvarint(completions_string) + 1);
    write_stats();
}

read_stats()
{
    stats_handle = fs_fopen(STATS_FILE, "read");
    stats = fs_read(stats_handle);
    tokens = strtok(stats, "\n");

    foreach(stat in tokens)
    {
        split = strtok(stat, "=");
        level.T6EE_STATS[split[0]] = split[1];
    }

    fs_fclose(stats_handle);
}

write_stats()
{
    data = "";
    foreach(stat in getarraykeys(level.T6EE_STATS))
        data += stat + "=" + level.T6EE_STATS[stat] + "\n";

    fs_remove(STATS_FILE);
    FS_WRITE_CLOSE(STATS_FILE, data);
}

init_stats()
{
    level.T6EE_STATS = [];

    foreach(map in array("zm_transit_", "zm_highrise_", "zm_prison_", "zm_buried_", "zm_tomb_", "super_"))
    {
        for(i = 4; i > 0; i--)
        {
            level.T6EE_STATS[map + i + "p_completions"] = 0;
            level.T6EE_STATS[map + i + "p_restarts"] = 0;
        }
    }
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

    if(self.split_id == "jetgun_power_off") handle_tranzit_branch();
    level.T6EE_SPLIT_NUM++;
}

split_refresh()
{
    while(!flag("game_over"))
    {
        time = gettime() - level.T6EE_START_TIME;

        if(level.T6EE_HUD)
        {
            frame_string = "^3" + self.split_label + " ^7" + game_time_string(time);
            self.split_string = frame_string;
            self.timer set_safe_text(frame_string);
        }

        write_livesplit_data(time + level.timing_offset);

        if(self.split_index < level.T6EE_SPLIT_NUM) break;
        wait 0.05;
    }

    if(!flag("game_over")) self.timer.color = TIMER_COMPLETE_COLOR;
}

handle_chat_commands()
{
    flag_wait("initial_blackscreen_passed");

    while(true)
    {
        level waittill("say", message, player);

        switch(tolower(message))
        {
            case "anticheat":
                status = getdvarint("EE_anticheat");
                setdvar("EE_anticheat", !status);
                iprintln("Anticheat " + (status ? "^2enabled" : "^1disabled"));
                break;

            case "super":
                status = toggle_setting("super_timing");
                iprintln("Super timing " + (status ? "^2enabled" : "^1disabled"));
                break;

            case "stats":
                status = toggle_setting("show_stats");
                iprintln("Display stats " + (status ? "^2enabled" : "^1disabled"));
                break;

            case "timer":
                status = toggle_setting("hud_timer");
                iprintln("HUD Timer " + (status ? "^2enabled" : "^1disabled") + "^7 - use ^3fast_restart");
                break;

            case "strafe":
                status = toggle_setting("console_strafe");
                set_strafe_speed(status);
                iprintln("Strafe speeds - " + (status ? "^1Console" : "^2PC"));
                break;

            case "speed":
                status = toggle_setting("hud_speed");
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

toggle_setting(key)
{
    new_val = !int(level.T6EE_CFG[key]);
    level.T6EE_CFG[key] = new_val;
    write_config();
    return new_val;
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

draw_client_split( index )
{
    self.sort = 2000;
    self.alignx = "left";
    self.aligny = "center";
    self.horzalign = "user_left"; // user_left respects aspect ratio
    self.vertalign = "top";
    self.x = TIMER_X_OFFSET;
    self.y = level.T6EE_Y_OFFSET + (index * TIMER_Y_INCREMENT);
    self.fontscale = 1.4;
    self.hidewheninmenu = 0;
    self.alpha = 0.8;
    self.color = TIMER_ACTIVE_COLOR;
}

timer_start_wait()
{
    level thread game_start_check();
    if(IS_MOB) level thread mob_start_check();
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

mob_start_check()
{
    flag_wait("initial_players_connected");

    while(!flag("timer_start"))
    {
        foreach(ghost in getplayers())
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
    if(level.T6EE_SIDE == "richtofen")
    {
        self.split_label = "Jetgun";
        level.T6EE_SPLIT_LIST = combinearrays(level.T6EE_SPLIT_LIST, array("tower", "EMP"));
    }
    else if(level.T6EE_SIDE == "maxis")
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
        livesplit_data = level.script + "|" + level.T6EE_SPLIT_NUM + "|" + time + "|"  + IS_SOLO;
        FS_WRITE_CLOSE(TIMER_FILE, livesplit_data);
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

        case "mined_games":
            level waittill_any("end_game_reward_starts_maxis", "end_game_reward_starts_richtofen");
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
    wait 0.10; // make sure dvar cheat hud element is alive
    set_dvar_if_unset("EE_anticheat", 1);
    if(getDvarInt("EE_anticheat"))
    {
        level.T6EE_RESTRICTED_DVARS = [];
        flag_wait("initial_players_connected");
        add_restricted_dvar_value( "cg_flashScriptHashes", 1 );
        add_restricted_dvar_value( "cg_drawIdentifier", 1 );
        add_restricted_dvar_value( "g_speed", 190 );
        add_restricted_dvar_value( "g_gravity", 800 );
        add_restricted_dvar_value( "sv_cheats", 0 );
        add_restricted_dvar_range( "sv_clientFpsLimit", 20, 250, 90);
        //add_restricted_dvar_range( "com_maxfps", 20, 250); not needed with clientFpsLimi
        //add_restricted_dvar_range( "cg_fov", 0, 120); not really working

        level thread dvar_monitor();

        flag_wait("timer_end");
        cmdexec("flashScriptHashes");
    }
    else
    {
        setdvar("cg_flashScriptHashes", 0);
        setdvar("cg_drawIdentifier", 0);
        flag_wait("initial_blackscreen_passed");
        iprintln("Anticheat - ^1Disabled");
    }
}

dvar_monitor()
{
    while (true)
    {
        level waittill ("dvar_changed", dvar, new, old);

        dvar = tolower(dvar);
        data = level.T6EE_RESTRICTED_DVARS[dvar];
        parsed = float(new);

        if (data.range == 0)
        {
            if (parsed != data.value)
            {
                level.cheat_display.alpha = 1;
                level.cheat_display set_safe_text(level.cheat_display.text_string + "\n" + toupper(dvar) + " " + parsed);
            }
        }
        else if (data.range == 1)
        {
            if (parsed < data.min || parsed > data.max)
            {
                level.cheat_display.alpha = 1;
                level.cheat_display set_safe_text(level.cheat_display.text_string + "\n" + toupper(dvar) + " " + parsed);
            }
        }
    }
}


add_restricted_dvar_value( dvar_in, value )
{
    dvar = tolower(dvar_in);
    level.T6EE_RESTRICTED_DVARS[dvar] = spawnStruct();
    level.T6EE_RESTRICTED_DVARS[dvar].string = dvar;
    level.T6EE_RESTRICTED_DVARS[dvar].range = 0;
    level.T6EE_RESTRICTED_DVARS[dvar].value = value;
    setdvar(dvar, value);
    enableDvarChangedNotify(dvar);
}

add_restricted_dvar_range( dvar_in, min, max, normal)
{
    dvar = tolower(dvar_in);
    level.T6EE_RESTRICTED_DVARS[dvar] = spawnStruct();
    level.T6EE_RESTRICTED_DVARS[dvar].string = dvar;
    level.T6EE_RESTRICTED_DVARS[dvar].range = 1;
    level.T6EE_RESTRICTED_DVARS[dvar].min = min;
    level.T6EE_RESTRICTED_DVARS[dvar].max = max;
    val = getdvarfloat(dvar);
    if(val < min || val > max)
    {
        setdvar(dvar, normal);
    }
    enableDvarChangedNotify(dvar);
}

set_strafe_speed( use_console )
{
    setDvar("player_backSpeedScale", 0.7 + (0.3 * use_console));
    setDvar("player_strafeSpeedScale", 0.8 + (0.2 * use_console));
}

upgrade_dvars()
{
    if(!IS_VICTIS) return;
    foreach(upgrade in level.pers_upgrades)
    {
        foreach(stat_name in upgrade.stat_names)
            level.T6EE_upgrades[level.T6EE_upgrades.size] = stat_name;
    }

    set_dvar_if_unset("pers_insta_kill", !IS_TRANZIT);

    foreach(pers_perk in  level.T6EE_upgrades)
        set_dvar_if_unset(pers_perk, 1);
}

upgrades_bank()
{
    //Provide all upgrades for vitis maps. Only for tranzit during supers
    if(!level.T6EE_SUPER_TIMING || IS_TRANZIT)
    {
        foreach(upgrade in level.pers_upgrades)
        {
            for(i = 0; i < upgrade.stat_names.size; i++)
            {
                val = (getdvarint(upgrade.stat_names[i]) > 0) * upgrade.stat_desired_values[i];
                self maps\mp\zombies\_zm_stats::set_client_stat(upgrade.stat_names[i], val);
            }
        }
    }
    else if(IS_BURIED) //Provide flopper on super runs
    {
        self maps\mp\zombies\_zm_stats::set_client_stat("pers_flopper_counter", getdvarint("pers_flopper_counter"));
    }

    flag_wait("initial_players_connected");

    if(level.T6EE_SUPER_TIMING) //Only set super guns on die rise
    {
         //Assumed tranzit fridge is never used
        //Don't clear if player left gun in die rise
        if(!IS_BURIED) self maps\mp\zombies\_zm_stats::clear_stored_weapondata();
        if(IS_DIE_RISE) self player_rig_fridge("svu_upgraded_zm+vzoom");
    }
    else
    {
        if(IS_DIE_RISE) self player_rig_fridge("svu_upgraded_zm+vzoom");
        if(IS_BURIED)
        {
            if(IS_SOLO) self player_rig_fridge("tar21_upgraded_zm+mms");
            else self player_rig_fridge("mp5k_upgraded_zm");
        }
    }

    flag_wait("initial_blackscreen_passed");
    self maps\mp\zombies\_zm_stats::set_map_stat("depositBox", level.bank_account_max, level.banking_map);
    self.account_value = level.bank_account_max;
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
    start = gettime();
    wait_network_frame();
    delay = gettime() - start;

    return (IS_SOLO && delay != SOLO_NETWORK_FRAME) || (!IS_SOLO && delay != COOP_NETWORK_FRAME);
}

init_default_config()
{
    level.T6EE_CFG = [];
    level.T6EE_CFG["hud_timer"]         = 1;
    level.T6EE_CFG["hud_speed"]         = 1;
    level.T6EE_CFG["show_stats"]        = 1;

    level.T6EE_CFG["console_strafe"]    = 0;
    level.T6EE_CFG["super_timing"]      = 0;
}

read_config()
{
    config_handle = fs_fopen(CFG_FILE, "read");
    settings = fs_read(config_handle);

    foreach(setting in strtok(settings, "\n"))
    {
        split = strtok(setting, "=");
        level.T6EE_CFG[split[0]] = split[1];
    }

    fs_fclose(config_handle);
}

write_config()
{
    data = "";

    foreach(setting in getarraykeys(level.T6EE_CFG))
    {
        data += setting + "=" + level.T6EE_CFG[setting] + "\n";
    }

    fs_remove(CFG_FILE);
    FS_WRITE_CLOSE(CFG_FILE, data);
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
    level.T6EE_LABELS["mined_games"] = "Mined Games";

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

    if(IS_SOLO)
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

    if(level.T6EE_SUPER_TIMING)
    {
        splits["zm_buried"][splits["zm_buried"].size] = "mined_games";
    }

    level.T6EE_SPLIT_LIST = splits[level.script];
}

set_safe_text(text)
{
	level.string_count += 1;

    // Notify overflow monitor on setText
	level notify("textset");
    self.text_string = text;
	self setText(text);
}

set_text_no_notify(text)
{
	level.string_count += 1;

    // Notify overflow monitor on setText
    self.text_string = text;
	self setText(text);
}

create_tracked_hud()
{
    hud = newhudelem();
    level.managed_text_huds[level.managed_text_huds.size] = hud;
    return hud;
}

overflow_manager()
{
    level endon("game_ended");
	level endon("host_migration_begin");
    flag_wait("initial_players_connected");

    // all strings allocated after this will be periodically removed
    level.overflow = newhudelem();
    level.overflow setText("overflow");
    level.overflow.alpha = 0;

    level.cheat_display = create_tracked_hud();
    level.cheat_display.sort = 2000;
    level.cheat_display.alignx = "center";
    level.cheat_display.aligny = "top";
    level.cheat_display.horzalign = "center"; // user_left respects aspect ratio
    level.cheat_display.vertalign = "top";
    level.cheat_display.fontscale = 1.4;
    level.cheat_display.hidewheninmenu = 0;
    level.cheat_display.alpha = 0;
    level.cheat_display.color = (1, 0, 0);
    level.cheat_display.glowcolor = (1, 1, 1);
    level.cheat_display set_safe_text("ILLEGAL DVAR CHANGE");

    level.string_count = 0;
    max_string_count = 50;

    while(true)
    {
        level waittill("textset");

        if(level.string_count >= max_string_count)
        {
            level.overflow ClearAllTextAfterHudElem();
            level.string_count = 0;

            foreach(elem in level.managed_text_huds)
            {
                if(isdefined(elem))
                    elem set_text_no_notify(elem.text_string); // or split_string if applicable
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
            precachestring( &"ZM_BURIED_EQ_SP_HTS");    //springpad
            precachestring( &"ZM_BURIED_EQ_SW_HTS");    //subwoof
            precachestring( &"ZM_BURIED_EQ_HC_HTS");    //headchopper
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
    if(IS_MOB || IS_ORIGINS)
    {
        foreach(p in runners)
        {
            tmp_strings[p.name + "GPIRY"] = newhudelem();
            tmp_strings[p.name + "GPIRY"] settext( &"GAME_PLAYER_IS_REVIVING_YOU", p);
            tmp_strings[p.name + "GPIRY"].alpha = 0;
        }
    }
}

game_time_string(time)
{
	total_sec = int(time / 1000);
    mn = int(total_sec / 60);   //minutes
    se = int(total_sec % 60);   //seconds
    ce = (time % 1000) / 10;    //centiseconds

    time_string = "";
    time_string += (mn > 9) ? int(mn)       : "0" + int(mn);
    time_string += (se > 9) ? ":" + se      : ":0" + se;
    time_string += (ce > 9) ? "." + int(ce) : ".0" + int(ce);

	return time_string;
}

/* ===================================NAV CARDS================================================= */
navcard_set()
{
    map = getsubstr(level.script, 3);
    stat_strings = array("sq_" + map + "_started", "navcard_applied_zm_" + map);

    // Build NAV enter cards
	foreach( runner in get_players())
	{
		foreach(stat in stat_strings)
		{
			if(!(runner maps\mp\zombies\_zm_stats::get_global_stat( stat ) ))
			{
				runner maps\mp\gametypes_zm\_globallogic_score::initPersStat( stat, 0 );
				runner maps\mp\zombies\_zm_stats::increment_client_stat( stat, 0 );
			}
		}
	}
}

/* =============================================================== */
/* The functions below are an independent implementation           */
/* that emulates the behavior of the scripts found at:             */
/* https://github.com/Hadi77KSA/Plutonium-T6-Any-Player-EE-Scripts */
/* =============================================================== */

/* =============================================================================================  */
/*                                   TRANZIT FUNCTION OVERRIDES                                   */
/* =============================================================================================  */

//[Maxis] Allow solo player to complete turbine step
replace_maxis_sidequest_b()
{
	level endon( "power_on" );

	while ( true )
	{
		level waittill( "stun_avogadro", avogadro );

		if ( isdefined( level.sq_progress["maxis"]["A_turbine_1"] ) && is_true( level.sq_progress["maxis"]["A_turbine_1"].powered ) && ( IS_SOLO || ( isdefined( level.sq_progress["maxis"]["A_turbine_2"] ) && is_true( level.sq_progress["maxis"]["A_turbine_2"].powered ))) )
		{
			if ( isdefined( avogadro ) && avogadro istouching( level.sq_volume ) )
			{
				level notify( "end_avogadro_turbines" );
				break;
			}
		}
	}

	level notify( "maxis_stage_b" );
    level thread [[getfunction("maps/mp/zm_transit_sq", "maxissay")]]("vox_maxi_avogadro_emp_0", ( 7737, -416, -142 ));
    [[getfunction("maps/mp/zm_transit_sq", "update_sidequest_stats")]]("sq_transit_maxis_stage_3");
	player = get_players();
	player[0] setclientfield( "sq_tower_sparks", 1 );
	player[0] setclientfield( "screecher_maxis_lights", 1 );
	level thread [[getfunction("maps/mp/zm_transit_sq", "maxis_sidequest_complete_check")]]( "B_complete" );
}

//[Maxis] Allow solo player to progress
replace_get_how_many_progressed_from( story, a, b )
{
	if ( !IS_SOLO && (isdefined( level.sq_progress[story][a] ) && !isdefined( level.sq_progress[story][b] ) || !isdefined( level.sq_progress[story][a] ) && isdefined( level.sq_progress[story][b] )) )
		return 1;
	else if ( IS_SOLO || isdefined( level.sq_progress[story][a] ) && isdefined( level.sq_progress[story][b] ) )
		return 2;

	return 0;
}

/* =============================================================================================  */
/*                                  DIE RISE FUNCTION OVERRIDES                                   */
/* =============================================================================================  */

//Require as many elevator symbols as there are players ingame
replace_sq_atd_elevators()
{
	a_elevators = array( "elevator_bldg1b_trigger", "elevator_bldg1d_trigger", "elevator_bldg3b_trigger", "elevator_bldg3c_trigger" );
	a_elevator_flags = array( "sq_atd_elevator0", "sq_atd_elevator1", "sq_atd_elevator2", "sq_atd_elevator3" );

	for ( i = 0; i < a_elevators.size; i++ )
	{
		trig_elevator = getent( a_elevators[i], "targetname" );
        trig_elevator thread [[getfunction("maps/mp/zm_highrise_sq_atd", "sq_atd_watch_elevator")]]( a_elevator_flags[i] );
	}

    el = "sq_atd_elevator";
	while( int(flag(el + "0")) + int(flag(el + "1")) + int(flag(el + "2")) + int(flag(el + "3")) < level.starting_player_count)
	{
		flag_wait_any_array( a_elevator_flags );
		wait 0.5;
	}

	a_dragon_icons = getentarray( "elevator_dragon_icon", "targetname" );

	foreach ( m_icon in a_dragon_icons )
	{
		v_off_pos = m_icon.m_lit_icon.origin;
		m_icon.m_lit_icon unlink();
		m_icon unlink();
		m_icon.m_lit_icon.origin = m_icon.origin;
		m_icon.origin = v_off_pos;
		m_icon.m_lit_icon linkto( m_icon.m_elevator );
		m_icon linkto( m_icon.m_elevator );
		m_icon playsound( "zmb_sq_symbol_light" );
	}

	flag_set( "sq_atd_elevator_activated" );
    [[getfunction("maps/mp/zm_highrise_sq_atd", "vo_richtofen_atd_elevators")]]();
    level thread [[getfunction("maps/mp/zm_highrise_sq_atd", "vo_maxis_atd_elevators")]]();
}

//Require as many floor symbols as there are players ingame
replace_sq_atd_drg_puzzle()
{
	level.sq_atd_cur_drg = 0;
	a_puzzle_trigs = getentarray( "trig_atd_drg_puzzle", "targetname" );
	a_puzzle_trigs = array_randomize( a_puzzle_trigs );

	for ( i = 0; i < a_puzzle_trigs.size; i++ )
        a_puzzle_trigs[i] thread [[getfunction("maps/mp/zm_highrise_sq_atd", "drg_puzzle_trig_think")]]( i );

	while ( level.sq_atd_cur_drg < level.starting_player_count )
		wait 1;

    flag_set( "sq_atd_drg_puzzle_complete" );
    foreach ( t_trig in a_puzzle_trigs )
    {
        //Disable trigger and light icon for reamaning floor symbols
        if(t_trig.drg_active == 0)
        {
            t_trig disable_trigger();
            symbol = getent( t_trig.target, "targetname" );
            lit_icon = symbol.lit_icon;
            original_pos = symbol.origin;
            symbol.origin = lit_icon.origin;
            lit_icon.origin = original_pos;
        }
    }

    level thread [[getfunction("maps/mp/zm_highrise_sq_atd", "vo_maxis_atd_order_complete")]]();
}

//[Richtofen] Require only one tramplesteam per player
replace_wait_for_all_springpads_placed( str_type, str_flag )
{
	a_spots = getstructarray( str_type, "targetname" );

	while ( !flag( str_flag ) )
	{
		is_clear = 0;
		foreach ( s_spot in a_spots )
		{
			if ( !isdefined( s_spot.springpad ) ) is_clear++;
		}

		if ( is_clear <= 4 - level.starting_player_count ) flag_set( str_flag );
		wait 1;
	}
}

//[Maxis] Allow springpad step to complete with <4 players
replace_place_ball_think( t_place_ball, s_lion_spot )
{
	t_place_ball endon( "delete" );
	t_place_ball waittill( "trigger" );

	if ( level.starting_player_count > 3 )	//normal behaviour
	{
        [[getfunction("maps/mp/zm_highrise_sq_pts", "pts_putdown_trigs_remove_for_spot")]]( s_lion_spot );
        [[getfunction("maps/mp/zm_highrise_sq_pts", "pts_putdown_trigs_remove_for_spot")]]( s_lion_spot.springpad_buddy );
	}

	self.zm_sq_has_ball = undefined;
	s_lion_spot.which_ball = self.which_ball;
	self notify( "zm_sq_ball_used" );
	s_lion_spot.zm_pts_animating = 1;
	s_lion_spot.springpad_buddy.zm_pts_animating = 1;
	flag_set( "pts_2_generator_" + level.current_generator + "_started" );
	s_lion_spot.which_generator = level.current_generator;
	level.current_generator++;
	if ( !isdefined( s_lion_spot.springpad_buddy.springpad ) ) s_lion_spot.springpad_buddy.springpad = s_lion_spot.springpad;
    s_lion_spot.springpad thread[[getfunction("maps/mp/zm_highrise_sq_pts", "pts_springpad_fling")]]( s_lion_spot.script_noteworthy, s_lion_spot.springpad_buddy.springpad );
	self.t_putdown_ball delete();

	//After first ball is flung, ball carrier may place theirs on the tample steam of opposite trajectory
	if ( level.starting_player_count == 3 )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			if ( isdefined( level.players[i].zm_sq_has_ball ) && level.players[i].zm_sq_has_ball )
			{
				foreach ( s_spot in getstructarray( "pts_lion", "targetname" ) )
				{
					if ( isdefined( s_spot.springpad ) && s_spot != s_lion_spot && s_spot.springpad_buddy != s_lion_spot )
						replace_pts_putdown_trigs_create_for_spot( s_spot, level.players[i] );
				}
			}
		}
	}
}

//[Maxis] Solo/3p: ball can be placed on an active tramplesteam without needing a tramplesteam on opposite spot. In 3p only if a ball is already flying.
replace_pts_should_player_create_trigs( player )
{
	a_lion_spots = getstructarray( "pts_lion", "targetname" );

	foreach ( s_lion_spot in a_lion_spots )
	{
		if ( isdefined( s_lion_spot.springpad ) && ( isdefined( s_lion_spot.springpad_buddy.springpad ) || ( ( level.starting_player_count == 1 || ( level.starting_player_count == 3 && flag( "pts_2_generator_1_started" ) ) ) ) ) )
			replace_pts_putdown_trigs_create_for_spot( s_lion_spot, player );
	}
}

//[Maxis] Solo/3p: allow ball placement on tramplesteam without a receiving spot having a tramplesteam
replace_pts_should_springpad_create_trigs( s_lion_spot )
{
	if ( isdefined( s_lion_spot.springpad ) && isdefined( s_lion_spot.springpad_buddy ) && ( isdefined( s_lion_spot.springpad_buddy.springpad ) || ( level.starting_player_count == 1 || ( level.starting_player_count == 3 && flag( "pts_2_generator_1_started" ) ) ) ) )
	{
		a_players = getplayers();

		foreach ( player in a_players )
		{
			if ( isdefined( player.zm_sq_has_ball ) && player.zm_sq_has_ball )
			{
				replace_pts_putdown_trigs_create_for_spot( s_lion_spot, player );

				if ( isdefined( s_lion_spot.springpad_buddy.springpad ) )
					replace_pts_putdown_trigs_create_for_spot( s_lion_spot.springpad_buddy, player );
			}
		}
	}
}

//[Maxis] Picking up a ball lets you place a second ball on a tramplesteam set already flinging one
replace_pts_putdown_trigs_create_for_spot( s_lion_spot, player )
{
	if ( level.starting_player_count >= 4  && ( isdefined( s_lion_spot.which_ball ) || isdefined( s_lion_spot.springpad_buddy ) && isdefined( s_lion_spot.springpad_buddy.which_ball ) ) )
		return;

    t_place_ball = [[getfunction("maps/mp/zm_highrise_sq_pts", "sq_pts_create_use_trigger")]]( s_lion_spot.origin, 16, 70, &"ZM_HIGHRISE_SQ_PUTDOWN_BALL" );
	player clientclaimtrigger( t_place_ball );
	t_place_ball.owner = player;
    player thread[[getfunction("maps/mp/zm_highrise_sq_pts", "place_ball_think")]]( t_place_ball, s_lion_spot );

	if ( !isdefined( s_lion_spot.pts_putdown_trigs ) )
		s_lion_spot.pts_putdown_trigs = [];

	s_lion_spot.pts_putdown_trigs[player.characterindex] = t_place_ball;
    level thread[[getfunction("maps/mp/zm_highrise_sq_pts", "pts_putdown_trigs_springpad_delete_watcher")]]( player, s_lion_spot );
}

/* =============================================================================================  */
/*                                   BURIED FUNCTION OVERRIDES                                    */
/* =============================================================================================  */

replace_are_all_players_in_time_bomb_volume( e_volume )
{
	n_players_in_position = 0;
    a_players = get_players();
	foreach ( player in a_players )
	{
		if ( player istouching( e_volume ) ) n_players_in_position++;
	}

	return n_players_in_position == a_players.size;;
}

replace_ctw_max_fail_watch()
{
    self endon( "death" );

    do
    {
        wait 1;
        n_starter_dist = distancesquared( self.origin, level.e_sq_sign_attacker.origin );
    }
    while (n_starter_dist < 262144 );

    level thread[[getfunction("maps/mp/zm_buried_sq_ctw", "ctw_max_fail_vo")]]();
    flag_set( "sq_wisp_failed" );
}

replace_sq_bp_set_current_bulb( str_tag )
{
	level endon( "sq_bp_correct_button" );
	level endon( "sq_bp_wrong_button" );
	level endon( "sq_bp_timeout" );

	if ( isdefined( level.m_sq_bp_active_light ) )
		level.str_sq_bp_active_light = "";

    level.m_sq_bp_active_light = [[getfunction("maps/mp/zm_buried_sq_ip", "sq_bp_light_on")]]( str_tag, "yellow" );
	level.str_sq_bp_active_light = str_tag;

	if ( level.starting_player_count > 2 )  //No timelimit for 1p/2p
	{
		wait 10;
		level notify( "sq_bp_timeout" );
	}
}

replace_ows_target_delete_timer()
{
	self endon( "death" );
	wait 4;
	self notify( "ows_target_timeout" );
	level.misses_remaining--;

	if ( level.misses_remaining < 0 )
		flag_set( "sq_ows_target_missed" );
}

replace_ows_targets_start()
{
	n_cur_second = 0;
	flag_clear( "sq_ows_target_missed" );
	level.misses_remaining = sharpshooter_allowed_misses();
    level thread[[getfunction("maps/mp/zm_buried_sq_ows", "sndsidequestowsmusic")]]();
	a_sign_spots = getstructarray( "otw_target_spot", "script_noteworthy" );

	while ( n_cur_second < 40 )
	{
        a_spawn_spots = [[getfunction("maps/mp/zm_buried_sq_ows", "ows_targets_get_cur_spots")]]( n_cur_second );

		if ( isdefined( a_spawn_spots ) && a_spawn_spots.size > 0 )
            [[getfunction("maps/mp/zm_buried_sq_ows", "ows_targets_spawn")]](a_spawn_spots);

		wait 1;
		n_cur_second++;
	}

	if ( !flag( "sq_ows_target_missed" ) )
	{
		flag_set( "sq_ows_success" );
		playsoundatposition( "zmb_sq_target_success", ( 0, 0, 0 ) );
	}
	else
		playsoundatposition( "zmb_sq_target_fail", ( 0, 0, 0 ) );

	level notify( "sndEndOWSMusic" );
}

sharpshooter_allowed_misses()
{
    total_targets = 84;
	switch ( level.starting_player_count )
	{
		case 1: return total_targets - 20;  //Candy Shop 20 targets
		case 2: return total_targets - 39;  // + Candy Shop 19 targets
		default: return 0; //All targets
	}
}


//Super EE reward button
replace_sq_metagame()
{
	level endon( "sq_metagame_player_connected" );
	flag_wait( "sq_intro_vo_done" );

	if ( flag( "sq_started" ) )
		level waittill( "buried_sidequest_achieved" );

    level thread[[getfunction("maps/mp/zm_buried_sq", "sq_metagame_turn_off_watcher")]]();
	is_blue_on = 0;
	is_orange_on = 0;
	m_endgame_machine = getstruct( "sq_endgame_machine", "targetname" );
	a_tags = [];
	a_tags[0][0] = "TAG_LIGHT_1";
	a_tags[0][1] = "TAG_LIGHT_2";
	a_tags[0][2] = "TAG_LIGHT_3";
	a_tags[1][0] = "TAG_LIGHT_4";
	a_tags[1][1] = "TAG_LIGHT_5";
	a_tags[1][2] = "TAG_LIGHT_6";
	a_tags[2][0] = "TAG_LIGHT_7";
	a_tags[2][1] = "TAG_LIGHT_8";
	a_tags[2][2] = "TAG_LIGHT_9";
	a_tags[3][0] = "TAG_LIGHT_10";
	a_tags[3][1] = "TAG_LIGHT_11";
	a_tags[3][2] = "TAG_LIGHT_12";
	a_stat = [];
	a_stat[0] = "sq_transit_last_completed";
	a_stat[1] = "sq_highrise_last_completed";
	a_stat[2] = "sq_buried_last_completed";
	a_stat_nav = [];
	a_stat_nav[0] = "navcard_applied_zm_transit";
	a_stat_nav[1] = "navcard_applied_zm_highrise";
	a_stat_nav[2] = "navcard_applied_zm_buried";
	a_stat_nav_held = [];
	a_stat_nav_held[0] = "navcard_applied_zm_transit";
	a_stat_nav_held[1] = "navcard_applied_zm_highrise";
	a_stat_nav_held[2] = "navcard_applied_zm_buried";
	bulb_on = [];
	bulb_on[0] = 0;
	bulb_on[1] = 0;
	bulb_on[2] = 0;
	level.n_metagame_machine_lights_on = 0;
	flag_wait( "start_zombie_round_logic" );
    [[getfunction("maps/mp/zm_buried_sq", "sq_metagame_clear_lights")]]();
	players = get_players();
	player_count = players.size;

	for ( n_player = 0; n_player < player_count; n_player++ )
	{
		for ( n_stat = 0; n_stat < a_stat.size; n_stat++ )
		{
			if ( isdefined( players[n_player] ) )
			{
				n_stat_value = players[n_player] maps\mp\zombies\_zm_stats::get_global_stat( a_stat[n_stat] );
				n_stat_nav_value = players[n_player] maps\mp\zombies\_zm_stats::get_global_stat( a_stat_nav[n_stat] );
			}

			if ( n_stat_value == 1 )
			{
                m_endgame_machine [[getfunction("maps/mp/zm_buried_sq", "sq_metagame_machine_set_light")]]( n_player, n_stat, "sq_bulb_blue" );
				is_blue_on = 1;
			}
			else if ( n_stat_value == 2 )
			{
                m_endgame_machine [[getfunction("maps/mp/zm_buried_sq", "sq_metagame_machine_set_light")]]( n_player, n_stat, "sq_bulb_orange" );
				is_orange_on = 1;
			}

			if ( n_stat_nav_value )
			{
				level setclientfield( "buried_sq_egm_bulb_" + n_stat, 1 );
				bulb_on[n_stat] = 1;
			}
		}
	}

	if ( level.n_metagame_machine_lights_on == player_count * 3 ) //Any player count
	{
		if ( is_blue_on && is_orange_on )
			return;
		else if ( !bulb_on[0] || !bulb_on[1] || !bulb_on[2] )
			return;
	}
	else
		return;

	m_endgame_machine.activate_trig = spawn( "trigger_radius", m_endgame_machine.origin, 0, 128, 72 );
	m_endgame_machine.activate_trig waittill( "trigger" );
	m_endgame_machine.activate_trig delete();
	m_endgame_machine.activate_trig = undefined;
	level setclientfield( "buried_sq_egm_animate", 1 );
	m_endgame_machine.endgame_trig = spawn( "trigger_radius_use", m_endgame_machine.origin, 0, 16, 16 );
	m_endgame_machine.endgame_trig setcursorhint( "HINT_NOICON" );
	m_endgame_machine.endgame_trig sethintstring( &"ZM_BURIED_SQ_EGM_BUT" );
	m_endgame_machine.endgame_trig triggerignoreteam();
	m_endgame_machine.endgame_trig usetriggerrequirelookat();
	m_endgame_machine.endgame_trig waittill( "trigger" );
	m_endgame_machine.endgame_trig delete();
	m_endgame_machine.endgame_trig = undefined;
    level thread[[getfunction("maps/mp/zm_buried_sq", "sq_metagame_clear_tower_pieces")]]();
	playsoundatposition( "zmb_endgame_mach_button", m_endgame_machine.origin );
	players = get_players();

	foreach ( player in players )
	{
		for ( i = 0; i < a_stat.size; i++ )
		{
			player maps\mp\zombies\_zm_stats::set_global_stat( a_stat[i], 0 );
			player maps\mp\zombies\_zm_stats::set_global_stat( a_stat_nav_held[i], 0 );
			player maps\mp\zombies\_zm_stats::set_global_stat( a_stat_nav[i], 0 );
		}
	}

    [[getfunction("maps/mp/zm_buried_sq", "sq_metagame_clear_lights")]]();

	if ( is_orange_on )
		level notify( "end_game_reward_starts_maxis" );
	else
		level notify( "end_game_reward_starts_richtofen" );
}

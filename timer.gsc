#include maps\mp\_utility;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include common_scripts\utility;

main()
{
	replaceFunc(maps\mp\animscripts\zm_utility::wait_network_frame, ::wait_network_frame_fix);
	replaceFunc(maps\mp\zombies\_zm_utility::wait_network_frame, ::wait_network_frame_fix);
}

init()
{
    if(level.scr_zm_ui_gametype_group != "zclassic") return;

    level.eet_version = "V2.4";
    level.eet_side = "none";
    level.eet_split = 0;

    level.x_offset = 2;
    level.y_offset = -34;
    level.split_y_increment = 16;

    level.eet_active_color = (0.99, 0.91, 0.99);
    level.eet_complete_color = (0.99, 0.58, 0.99);

    level thread network_frame_print();
    level thread on_player_connect();
    level thread chat_restart();
    if(upgrades_active()) level thread upgrade_dvars();

    flag_wait( "initial_players_connected" );
    solo = level.players.size == 1;

    switch (level.script)
    {
        case "zm_transit":
            if(solo)   level.split_list = strtok("jetgun|tower|EMP", "|");
            else       level.split_list =  array("jetgun_power_off");
            break;

        case "zm_highrise":
            if(solo)   level.split_list = array("highrise_end");
            else       level.split_list = array("highrise_end");
            break;

        case "zm_prison":
            level.y_offset = 16;
            if(solo)   level.split_list = strtok("dryer|gondola_1|plane_1|gondola_2|plane_2|gondola_3|plane_3|codes|headphones", "|");
            else       level.split_list = strtok("COOP_plane_1|COOP_plane_2|COOP_plane_3|codes|fight", "|");
            break;

        case "zm_buried":
            level.split_list = strtok("cipher|sharpshooter", "|");
            break;

        case "zm_tomb":
            level.y_offset = 76;
            if(solo)    level.split_list = strtok("NML|boxes|staff_1|staff_2|staff_3|staff_4|AFD|rain_fire|freedom", "|");
            else        level.split_list = strtok("boxes|AFD|freedom", "|");
            break;
    }

    create_timer();
    run_splits();
}

on_player_connect()
{
    level endon( "game_ended" );
    while(true)
    {
        level waittill( "connected", player );
        player thread on_player_spawned();
    }
}

on_player_spawned()
{
    self waittill( "spawned_player" );
    if(upgrades_active()) self thread upgrades_bank();
    wait 2.5;
    self iprintln("^8[^3EE Timer^8][^5" + level.eet_version + "^8]^7 github.com/HuthTV/T6-EE-Timer");
}

run_splits()
{

    split_loop();

    if(level.eet_side == "richtofen")
    {
        switch(level.script)
        {
            case "zm_transit": richtofen_splits = array("tower", "EMP"); break;
        }

        foreach(split in richtofen_splits)
            level.split_list[level.split_list.size] = split;

        split_loop();
    }
    else if(level.eet_side == "maxis")
    {
        switch(level.script)
        {
            case "zm_transit":  maxis_splits = array("turbines"); break;
        }

        foreach(split in maxis_splits)
            level.split_list[level.split_list.size] = split;

        split_loop();
    }
}

split_loop()
{
    level endon( "game_ended" );

    for(i = level.eet_split; i < level.split_list.size; i++)
    {
        set_label(level.eet_timer, level.split_list[i]);
        level.eet_timer.alpha = 0.8 * (level.eet_split != 0);
        split = level.split_list[i];
        split(split, wait_split(split));
    }
}

split(split_name, time)
{
    split = newhudelem();
    split.alignx = "left";
    split.aligny = "center";
    split.horzalign = "user_left"; // user_left respects aspect ratio
    split.vertalign = "top";
    split.x = level.x_offset;
    split.y = level.y_offset + (level.eet_split * level.split_y_increment);
    split.fontscale = 1.4;
    split.hidewheninmenu = 0;
    split.alpha = 0.8;
    split.color = level.eet_complete_color;
    if(level.eet_side != "none")
        split_name = split_name + "_" + level.eet_side;
    set_label(split, split_name);
    split settext(game_time_string(time - level.eet_start_time));

    level.eet_split++;
    level.eet_timer.y += level.split_y_increment;
    level.eet_timer.alpha = 0;
}

create_timer()
{
    level.eet_timer = newhudelem();
    level.eet_timer.alignx = "left";
    level.eet_timer.aligny = "center";
    level.eet_timer.horzalign = "user_left"; // user_left respects aspect ratio
    level.eet_timer.vertalign = "top";
    level.eet_timer.x = level.x_offset;
    level.eet_timer.y = level.y_offset;
    level.eet_timer.fontscale = 1.4;
    level.eet_timer.hidewheninmenu = 0;
    level.eet_timer.alpha = 0;
    level.eet_timer.color = level.eet_active_color;
    level thread timer_start_thread();
}

timer_start_thread()
{
    flag_init("timer_start");
    flag_clear("timer_start");
    level thread game_start_check();

    flag_wait("timer_start");
    level.eet_start_time = gettime();
    level.eet_timer settenthstimerup(0.05);
    level.eet_timer.alpha = 0.8;
}

game_start_check()
{
    if(level.script == "zm_prison") level thread mob_start_check();
    flag_wait( "initial_blackscreen_passed" );
    flag_set("timer_start");
}

mob_start_check()
{
    players = getplayers();
    while(!flag("timer_start"))
    {
        foreach(ghost in players)
        {
            if(isdefined(ghost.e_afterlife_corpse))
            {
                wait 1.5;
                flag_set("timer_start");
            }
        }
        wait 0.05;
    }
}

chat_restart()
{
    while(true)
    {
        level waittill("say", message, player);

        msg = tolower(message);

        switch (msg)
        {
            case "r":
            case "restart":
            case "fast_restart":
                map_restart();
        }
    }
}

wait_split(split)
{
    switch (split)
    {
        //Tranzit splits
        case "jetgun_power_off":
            level waittill( "power_event_complete" );
            split = false;
            while(!split)
            {
                if( level.sq_progress["rich"]["A_jetgun_built"] > 0 )
                {
                    split = true;
                    level.eet_side = "richtofen";
                    continue;
                }

                if( level.power_event_in_progress )
                {
                    split = true;
                    level.eet_side = "maxis";
                    continue;
                }

                wait 0.05;
            }
            break;

        case "jetgun":
            while(level.sq_progress["rich"]["A_jetgun_built"] == 0) wait 0.05;
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

        //Die Rise splits
        case "highrise_end":
            level waittill("highrise_sidequest_achieved");
            break;

        //Mob splits
        case "dryer":
            flag_wait("dryer_cycle_active");
            break;

        case "gondola_1":
            flag_wait("fueltanks_found");
            flag_wait("gondola_in_motion");
            break;

        case "gondola_2":
        case "gondola_3":
            flag_wait("gondola_in_motion");
            break;

        case "COOP_plane_2":
        case "COOP_plane_3":
            flag_wait("spawn_fuel_tanks");
        case "COOP_plane_1":
        case "plane_1":
        case "plane_2":
        case "plane_3":
            flag_wait("plane_boarded");
            break;

        case "codes":
            level waittill_multiple( "nixie_final_" + 386, "nixie_final_" + 481, "nixie_final_" + 101, "nixie_final_" + 872 );
            break;

        case "headphones":
            wait 10;
            while( isdefined(level.m_headphones) ) wait 0.05;
            break;

        case "fight":
            level waittill("showdown_over");
            wait 2;
            break;

        //Buried splits
        case "cipher":
            wait_for_buildable( "buried_sq_oillamp" );
            break;

        case "time_travel":
            //while( !flag("sq_tpo_special_round_active") && !flag("sq_wisp_saved_with_time_bomb") ) wait 0.05;
            break;

        case "sharpshooter":
            level waittill_any("sq_richtofen_complete", "sq_maxis_complete");
            break;

        //Origins splits
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
            //Change staff label?
            break;

        case "rain_fire":
            flag_wait("ee_mech_zombie_hole_opened");
            break;

        case "AFD":
            flag_wait("ee_all_staffs_placed");
            break;

        case "freedom":
            flag_wait( "ee_samantha_released" );
            level waittill("end_game");
            break;
    }

    return gettime();
}

set_label(elem, split_name)
{
    switch (split_name)
    {
        //Tranzit
        case "jetgun": elem.label = &"^3Jetgun ^7"; break;
        case "tower_richtofen":
        case "tower": elem.label = &"^3Tower ^7"; break;
        case "EMP_richtofen":
        case "EMP": elem.label = &"^3Lights ^7"; break;
        case "turbines_maxis":
        case "turbines": elem.label = &"^3Turbines ^7"; break;
        case "jetgun_power_off": elem.label = &"^3Power off/Jetgun ^7"; break;
        case "jetgun_power_off_maxis": elem.label = &"^3Power off ^7"; break;
        case "jetgun_power_off_richtofen": elem.label = &"^3Jetgun ^7"; break;

        //Die Rise
        case "highrise_end": elem.label = &"^3High Maintenance ^7"; break;

        //Mob of the Dead
        case "dryer": elem.label = &"^3Dryer ^7"; break;
        case "gondola_1": elem.label = &"^3Gondola I ^7"; break;
        case "gondola_2": elem.label = &"^3Gondola II ^7"; break;
        case "gondola_3": elem.label = &"^3Gondola III ^7"; break;
        case "COOP_plane_1":
        case "plane_1": elem.label = &"^3Plane I ^7"; break;
        case "COOP_plane_2":
        case "plane_2": elem.label = &"^3Plane II ^7"; break;
        case "COOP_plane_3":
        case "plane_3": elem.label = &"^3Plane III ^7"; break;
        case "codes": elem.label = &"^3Codes ^7"; break;
        case "headphones": elem.label = &"^3Headphones ^7"; break;
        case "fight": elem.label = &"^3Fight ^7"; break;

        //Buried
        case "cipher": elem.label = &"^3Cipher ^7"; break;
        case "time_travel": elem.label = &"^3Time travel ^7"; break;
        case "sharpshooter": elem.label = &"^3Sharpshooter ^7"; break;

        //Origins
        case "NML": elem.label = &"^3NML ^7"; break;
        case "boxes": elem.label = &"^3Boxes ^7"; break;
        case "staff_1": elem.label = &"^3Staff I ^7"; break;
        case "staff_2": elem.label = &"^3Staff II ^7"; break;
        case "staff_3": elem.label = &"^3Staff III ^7"; break;
        case "staff_4": elem.label = &"^3Staff IV ^7"; break;
        case "AFD": elem.label = &"^3AFD ^7"; break;
        case "rain_fire": elem.label = &"^3Rain Fire ^7"; break;
        case "freedom": elem.label = &"^3Freedom ^7"; break;

        case "done": elem.label = &"^3End ^7"; break;
    }
}

upgrade_dvars()
{
    foreach(upgrade in level.pers_upgrades)
    {
        foreach(stat_name in upgrade.stat_names)
            level.eet_upgrades[level.eet_upgrades.size] = stat_name;
    }

    create_bool_dvar("full_bank", 1);
    create_bool_dvar("pers_insta_kill", level.script != "zm_transit");

    foreach(pers_perk in level.eet_upgrades)
        create_bool_dvar(pers_perk, 1);
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

    flag_wait("initial_blackscreen_passed");
    if(getdvarint("full_bank"))
    {
        self maps\mp\zombies\_zm_stats::set_map_stat("depositBox", level.bank_account_max, level.banking_map);
        self.account_value = level.bank_account_max;
    }
}

upgrades_active()
{
    return maps\mp\zombies\_zm_pers_upgrades::is_pers_system_active();
}

game_time_string(duration)
{
    if(!isdefined(level.eet_start_time))
    {
        return "00:00.00";
    }

	total_sec = int(duration / 1000);
	mn = int(total_sec / 60);       //minutes
	se = int(total_sec % 60);       //seconds
    ce = (duration % 1000) / 10;    //centiseconds
    time_string = "";

    //minutes
    if(mn > 9)        { time_string = time_string + int(mn); }
	else              { time_string = time_string + "0" + int(mn); }
    //seconds
	if(se > 9)        { time_string = time_string + ":" + se; }
	else              { time_string = time_string + ":0" + se; }
    //centiseconds
    if(ce > 9)        { time_string = time_string + "." + int(ce); }
    else              { time_string = time_string + ".0" + int(ce); }

	return time_string;
}

create_bool_dvar( dvar, start_val )
{
    if(getdvar(dvar) == "") setdvar(dvar, start_val);
}

wait_network_frame_fix()
{
    if (level.players.size == 1)
        wait 0.1;
    else if (numremoteclients())
    {
        snapshot_ids = getsnapshotindexarray();

        for (acked = undefined; !isdefined(acked); acked = snapshotacknowledged(snapshot_ids))
            level waittill("snapacknowledged");
    }
    else
        wait 0.1;
}

network_frame_print()
{
    flag_wait("initial_blackscreen_passed");
    if(!isdefined(level.network_frame_checked))
    {
        level.network_frame_checked = true;

        start = gettime();
        wait_network_frame();
        end = gettime();
        delay = end - start;

        msgstring = "^8[^6Network Frame Fix^8] ^7" + delay + "ms ";

        if( (level.players.size == 1 && delay == 100) || (level.players.size > 1 && delay == 50) )
            msgstring += "^2good";
        else
            msgstring += "^1bad";

        Print(msgstring);
        IPrintLn(msgstring);
    }
}
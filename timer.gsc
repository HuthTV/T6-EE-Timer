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

    level.eet_version = "V2.6";
    level.eet_side = "none";
    level.eet_split = 0;
    level.eet_hud_elems = [];

    level.x_offset = 2;
    level.split_y_increment = 16;
    level.string_count = 0;

    level.eet_active_color = (0.99, 0.91, 0.99);
    level.eet_complete_color = (0.99, 0.58, 0.99);

    populate_split_arrays();

    level thread network_frame_print();
    level thread on_player_connect();
    level thread chat_restart();
    level thread strafe_dvars();
    level thread overflow_fix();

    if(upgrades_active()) level thread upgrade_dvars();

    flag_wait( "initial_players_connected" );
    
    solo = level.players.size == 1;

    level.labels = [];
    level.split_list = [];
    populate_split_labels();
    
    switch(level.script)
    {
        case "zm_prison": level.y_offset = 16; break;
        case "zm_tomb": level.y_offset = 76; break;
        default: level.y_offset = -34; break;
    }

    timer_start_wait();
    run_splits(); 
}

populate_split_labels()
{
    level.labels["jetgun_power_off"] = "Jetgun/Power off";
    level.labels["power_off"] = "Power off";
    level.labels["jetgun"] = "Jetgun";
    level.labels["turbines"] = "Turbines";
    level.labels["tower"] = "Tower";
    level.labels["EMP"] = "Lights";

    level.labels["highrise_symbols"] = "Symbols";
    level.labels["highrise_perks"] = "High Maintenance";

    level.labels["dryer"] = "Dryer";
    level.labels["gondola_1"] = "Gondola I";
    level.labels["gondola_2"] = "Gondola II";
    level.labels["gondola_3"] = "Gondola III";
    level.labels["plane_1"] = "Plane I";
    level.labels["plane_2"] = "Plane II";
    level.labels["plane_3"] = "Plane III";
    level.labels["codes"] = "Codes";
    level.labels["headphones"] = "Headphones";
    level.labels["fight"] = "Showdown";

    level.labels["cipher"] = "Cipher";
    level.labels["sharpshooter"] = "Sharpshooter";

    level.labels["NML"] = "NML";
    level.labels["boxes"] = "Boxes";
    level.labels["staff_1"] = "Staff I";
    level.labels["staff_2"] = "Staff II";
    level.labels["staff_3"] = "Staff III";
    level.labels["staff_4"] = "Staff IV";
    level.labels["AFD"] = "AFD";
    level.labels["rain_fire"] = "Rain Fire";
    level.labels["freedom"] = "Freedom";

    splits["zm_transit"] = array("jetgun_power_off");
    splits["zm_highrise"] = strtok("highrise_symbols|highrise_perks", "|");
    splits["zm_buried"] = strtok("cipher|sharpshooter", "|");

    if(solo)
    {
        splits["zm_prison"] = strtok("dryer|gondola_1|plane_1|gondola_2|plane_2|gondola_3|plane_3|codes|headphones", "|");
        splits["zm_tomb"] = strtok("NML|boxes|staff_1|staff_2|staff_3|staff_4|AFD|rain_fire|freedom", "|");
    }
    else
    {
        splits["zm_prison"] = strtok("COOP_plane_1|COOP_plane_2|COOP_plane_3|codes|fight", "|");
        splits["zm_tomb"] = strtok("boxes|AFD|freedom", "|");
    }

    level.split_list = splits[level.script];
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
    split.sort = 2000;
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
    level.eet_timer.sort = 2000;
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
            if(isdefined(ghost.afterlife_visionset) && ghost.afterlife_visionset == 1)
            {
                wait 0.45;
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
        case "highrise_symbols":
            flag_wait( "sq_atd_drg_puzzle_complete" );
            break;

        case "highrise_perks":
            level waittill( "sq_fireball_hit_player" );
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

strafe_dvars()
{
    create_bool_dvar("strafe_unlocked", 1);

    if(getdvarint("strafe_unlocked"))
    {
        setDvar("player_backSpeedScale", 1);    //Console values
        setDvar("player_strafeSpeedScale", 1);
    }
    else
    {
        setDvar("player_backSpeedScale", 0.7);  //Steam values
        setDvar("player_strafeSpeedScale", 0.8);
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

set_safe_text(text)
{
	level.string_count += 1;
	level notify("textset");
    self.text_string = text;
	self setText(text);
}

overflow_fix()
{
    level endon("game_ended");
	level endon("host_migration_begin");

    level.dummy_string = createServerFontString("default", 1);
	level.dummy_string setText("overflow");
	level.dummy_string.alpha = 0;

    level.string_count = 0;
    max_string_count = 55;

    while(true)
    {
            level waittill("textset");

            if(level.string_count >= max_string_count)
            {
                level.dummy_string ClearAllTextAfterHudElem();
                level.string_count = 0;
                foreach(elem in level.eet_hud_elems)
                {
                    elem set_safe_text(elem.text_string);
                }
            }
    }
}
#include maps\mp\_utility;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include common_scripts\utility;

init()
{
    if(level.scr_zm_ui_gametype_group != "zclassic") return;

    level.eet_version = "V1.3 - WIP";
    level.eet_active_color = (0.82, 0.97, 0.97);
    level.eet_complete_color = (0.01, 0.62, 0.74);
    level thread on_player_connect();
    if(upgrades_active()) level thread upgrade_dvars();

    flag_wait( "initial_players_connected" );
    solo = (level.players.size == 1);

    switch (level.script)
    {
        case "zm_transit":
            if(solo)    level thread timer( strtok("Jetgun|Tower|EMP", "|"), 0, 0);
            //else        level thread branching_timer( strtok("Power|branch_split", "|"), strtok("corpse|flings", "|"), strtok("corpse|flings", "|"), 0);
            break;

        case "zm_highrise":
            //level thread branching_timer( strtok("Power|Elevators|Symbols|sniper|branch_split", "|"), strtok("corpse|flings", "|"), strtok("corpse|flings", "|"), 0);
            break;

        case "zm_prison":
            if(solo)    level thread timer( strtok("Dryer|Gondola1|Plane1|Gondola2|Plane2|Gondola3|Plane3|Codes|Done", "|"), 50, 0);
            else        level thread timer( strtok("COOP_Plane1|COOP_Plane2|COOP_Plane3|Codes|Fight", "|"), 50, 0);
            break;

        case "zm_buried":
            //level thread branching_timer( strtok("Paralyzer|balls|targets|branch_split", "|"), strtok("Jetgun|Tower|EMP", "|"), strtok("Jetgun|Tower|EMP", "|"), 0);
            break;

        case "zm_tomb":
            if(solo)    level thread timer( strtok("NML|Boxes|Staff 1|Staff 2|Staff 3|Staff 4|AFD|Freedom", "|"), 110, 0);
            else        level thread timer( strtok("Boxes|AFD|Freedom", "|"), 110, 0);
            break;
    }
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
    self iPrintLn("^6GSC EE Autotimer ^5" + level.eet_version + " ^8| ^3github.com/HuthTV/BO2-Easter-Egg-GSC-timer");
}

timer( split_list, y_offset, branching )
{
    level endon( "game_ended" );

    foreach(split in split_list)
        create_new_split(split, y_offset);

    if(!isdefined(level.eet_start_time))
    {
        flag_wait("initial_blackscreen_passed");
        level.eet_start_time = gettime();
    }

    for(i = 0; i < split_list.size - branching; i++)
    {
        split = split_list[i];
        unhide(split);
        split(split, wait_split(split));
    }
}

branching_timer( common_split_list, richtofen_split_list, maxis_split_list, y_offset)
{
    level endon( "game_ended" );
    branch_split_list = [];

    timer( common_split_list, y_offset, 1);

    branch_split = common_split_list[common_split_list.size];
    path = wait_branch_split(branch_split);
    set_split_label(branch_split + "_" + path);
    split(branch_split);

    switch(path)
    {
        case "richtofen":   branch_split_list = richtofen_split_list; break;
        case "maxis":       branch_split_list = maxis_split_list; break;
    }

    timer( branch_split_list, y_offset, 0);
}

create_new_split(split_name, y_offset)
{
    y = y_offset;
    if(isdefined(level.eet_splits)) y += level.eet_splits.size * 16;
    level.eet_splits[split_name] = newhudelem();
    level.eet_splits[split_name].alignx = "left";
    level.eet_splits[split_name].aligny = "center";
    level.eet_splits[split_name].horzalign = "left";
    level.eet_splits[split_name].vertalign = "top";
    level.eet_splits[split_name].x = -62;
    level.eet_splits[split_name].y = -34 + y;
    level.eet_splits[split_name].fontscale = 1.4;
    level.eet_splits[split_name].hidewheninmenu = 1;
    level.eet_splits[split_name].alpha = 0;
    level.eet_splits[split_name].color = level.eet_active_color;
    level thread split_start_thread(split_name);
    set_split_label(split_name);
}

split_start_thread(split_name)
{
    flag_wait("initial_blackscreen_passed");
    level.eet_splits[split_name] settenthstimerup(0.05);
}

set_split_label(split_name)
{
    switch (split_name)
    {
        //Tranzit
        case "Jetgun": level.eet_splits[split_name].label = &"^3Jetgun ^7"; break;
        case "Tower": level.eet_splits[split_name].label = &"^3Tower ^7"; break;
        case "NML": level.eet_splits[split_name].label = &"^3NML ^7"; break;

        //Die Rise

        //Mob of the Dead
        case "Dryer": level.eet_splits[split_name].label = &"^3Dryer ^7"; break;
        case "Gondola1": level.eet_splits[split_name].label = &"^3Gondola I ^7"; break;
        case "Gondola2": level.eet_splits[split_name].label = &"^3Gondola II ^7"; break;
        case "Gondola3": level.eet_splits[split_name].label = &"^3Gondola III ^7"; break;
        case "COOP_Plane1":
        case "Plane1": level.eet_splits[split_name].label = &"^3Plane I ^7"; break;
        case "COOP_Plane2":
        case "Plane2": level.eet_splits[split_name].label = &"^3Plane II ^7"; break;
        case "COOP_Plane3":
        case "Plane3": level.eet_splits[split_name].label = &"^3Plane III ^7"; break;
        case "Codes": level.eet_splits[split_name].label = &"^3Codes ^7"; break;

        //Buried

        //Origins
        case "Boxes": level.eet_splits[split_name].label = &"^3Boxes ^7"; break;
        case "Staff 1": level.eet_splits[split_name].label = &"^3Staff I ^7"; break;
        case "Staff 2": level.eet_splits[split_name].label = &"^3Staff II ^7"; break;
        case "Staff 3": level.eet_splits[split_name].label = &"^3Staff III ^7"; break;
        case "Staff 4": level.eet_splits[split_name].label = &"^3Staff IV ^7"; break;
        case "AFD": level.eet_splits[split_name].label = &"^3AFD ^7"; break;

        //End splits
        case "Fight":
        case "Freedom":
        case "EMP":
        case "Done":
            level.eet_splits[split_name].label = &"^3End ^7"; break;
    }
}

unhide(split_name)
{
    level.eet_splits[split_name].alpha = 0.8;
}

split(split_name, time)
{
    level.eet_splits[split_name].color = level.eet_complete_color;
    level.eet_splits[split_name] settext(game_time_string(time - level.eet_start_time));
}

wait_branch_split(split)
{
    switch (split)
    {
        case "Tranzit":
            return "rictofen";
        case "Die_Rise":
            return "maxis";
        case "Buried":
            return "rictofen";
    }
}

wait_split(split)
{
    switch (split)
    {
        //Tranzit splits
        case "Jetgun":
            while(level.sq_progress["rich"]["A_jetgun_built"] == 0) wait 0.05;
            break;

        case "Tower":
            while(level.sq_progress["rich"]["A_jetgun_tower"] == 0) wait 0.05;
            break;

        case "EMP":
            while(level.sq_progress["rich"]["FINISHED"] == 0) wait 0.05;
            break;

        //Die Rise splits

        //Mob splits
        case "Dryer":
            flag_wait("dryer_cycle_active");
            break;

        case "Gondola1":
            flag_wait("fueltanks_found");
            flag_wait("gondola_in_motion");
            break;

        case "Gondola2":
        case "Gondola3":
            flag_wait("gondola_in_motion");
            break;

        case "COOP_Plane2":
        case "COOP_Plane3":
            flag_wait("spawn_fuel_tanks");
        case "COOP_Plane1":
        case "Plane1":
        case "Plane2":
        case "Plane3":
            flag_wait("plane_boarded");
            break;

        case "Codes":
            level waittill_multiple( "nixie_final_" + 386, "nixie_final_" + 481, "nixie_final_" + 101, "nixie_final_" + 872 );
            break;

        case "Done":
            wait 10;
            while( isdefined(level.m_headphones) ) wait 0.05;
            break;

        case "Fight":
            level waittill("showdown_over");
            wait 2;
            break;

        //Buried splits

        //Origins splits
        case "NML":
        flag_wait("activate_zone_nml");
        break;

        case "Boxes":
            while(level.n_soul_boxes_completed < 4) wait 0.05;
            wait 4.3;
            break;

        case "Staff 1":
        case "Staff 2":
        case "Staff 3":
        case "Staff 4":
            curr = level.n_staffs_crafted;
            while(curr == level.n_staffs_crafted && level.n_staffs_crafted < 4) wait 0.05;
            //Change staff label?
            break;

        case "AFD":
            flag_wait("ee_all_staffs_placed");
            break;

        //Origins end
        case "Freedom":
            while(!isdefined(level.sndgameovermusicoverride)) wait 0.05;
            level waittill("end_game");
            break;
    }

    return gettime();
}

upgrade_dvars()
{
    foreach(upgrade in level.pers_upgrades)
    {
        foreach(stat_name in upgrade.stat_names)
            level.eet_upgrades[level.eet_upgrades.size] = stat_name;
    }

    create_bool_dvar("full_bank", 1);
    create_bool_dvar("pers_insta_kill", !is_map("zm_transit"));

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

    if(getdvarint("full_bank"))
    {
        self maps\mp\zombies\_zm_stats::set_map_stat("depositBox", level.bank_account_max, level.banking_map);
        self.account_value = level.bank_account_max;
    }
}

game_time_string(duration)
{
    total_sec = int(duration / 1000);
    total_min = int(total_sec / 60);
    remaining_ms = (duration % 1000) / 10;
    remaining_sec = total_sec % 60;
    time_string = "";

    if(total_min > 9)       { time_string += total_min + ":"; }
    else                    { time_string += "0" + total_min + ":"; }
    if(remaining_sec > 9)   { time_string += remaining_sec + "."; }
    else                    { time_string += "0" + remaining_sec + "."; }
    if(remaining_ms > 9)    { time_string += remaining_ms; }
    else                    { time_string += "0" + remaining_ms; }

    return time_string;
}

upgrades_active()
{
    return maps\mp\zombies\_zm_pers_upgrades::is_pers_system_active();
}

create_bool_dvar( dvar, start_val )
{
    if(getdvar(dvar) == "") setdvar(dvar, start_val);
}
#include maps\mp\_utility;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include common_scripts\utility;
#include scripts\zm\utils;

init()
{
    level.version = "v1.0";
    level.splits = [];
    level.active_color = (0.82, 0.97, 0.97);
    level.complete_color = (0.01, 0.62, 0.74);

    solo = level.is_forever_solo_game;

    if(is_origins())
    {
        if(solo)    level thread origins_timer( strtok("NML|Boxes|Staff 1|Staff 2|Staff 3|Staff 4|AFD|End", "|") );
        else        level thread origins_timer( strtok("Boxes|AFD|End", "|") );
    }  
    else if(is_mob()) 
    {
        if(solo)    level thread mob_timer( strtok("Dryer|Gondola1|Plane1|Gondola2|Plane2|Gondola3|Plane3|Codes|End", "|") );
        else        level thread mob_timer( strtok("Plane1|Plane2|Plane3|Codes|Fight", "|") );   
    } 
    else if(is_tranzit()) 
    {
        if(solo)    level thread tranzit_timer( strtok("Jetgun|Tower|End", "|") );
    }
    else
    {
        return;
    }
    
    level thread on_player_connect();
    flag_wait("initial_blackscreen_passed");
    level.timer_level_start_time = GetTime();
}

on_player_connect()
{
        while(true)
        {
           level waittill( "connected", player );
           player thread persistent_upgrades_bank();
           player thread on_player_spawned(); 
        }
}

on_player_spawned()
{
    self waittill( "spawned_player" );
    wait 2;
    iPrintLn("^3EE Timer ^7" + level.version);
    wait 1;
    iPrintLn("source: github.com/HuthTV/BO2-Easter-Egg-GSC-timer");
}

tranzit_timer( split_list )
{
    foreach(split in split_list)
        create_new_split(split, 15); 

    flag_wait("initial_blackscreen_passed");
    for(i = 0; i < split_list.size; i++)
    {
        unhide(split_list[i]);
        time = tranzit_wait_split(split_list[i]);
        split(split_list[i], time);
    } 
}

tranzit_wait_split( split )
{
    switch (split) 
    {
        case "Jetgun": 
            while(level.sq_progress["rich"]["A_jetgun_built"] == 0) wait 0.05;
            break;

        case "Tower":
            while(level.sq_progress["rich"]["A_jetgun_tower"] == 0) wait 0.05;
            break;
            
        case "End":
            while(level.sq_progress["rich"]["FINISHED"] == 0) wait 0.05;
            break;
    }

    return GetTime();     
}

origins_timer( split_list )
{
    foreach(split in split_list)
        create_new_split(split, 65);
    
    flag_wait("initial_blackscreen_passed");

    for(i = 0; i < split_list.size; i++)
    {
        unhide(split_list[i]);
        time = origins_wait_split(split_list[i]);
        split(split_list[i], time);
    } 
}

origins_wait_split( split )
{
    switch (split) {
    case "NML": 
        flag_wait("activate_zone_nml");
        break;

    case "Boxes":
        while(level.n_soul_boxes_completed < 4) wait 0.05;
        wait 4;
        break;
        
    case "Staff 1":
    case "Staff 2":
    case "Staff 3":
    case "Staff 4":
        curr = level.n_staffs_crafted;
        while(curr <= level.n_staffs_crafted) wait 0.05;
        //Change staff label?
        break;

    case "AFD":
        flag_wait("ee_all_staffs_placed");
        break;

    case "End":
        level waittill("end_game");
        break;
    }

    return GetTime(); 
}

mob_timer( split_list )
{
    foreach(split in split_list)
    {
        create_new_split(split, 65);
    }

    flag_wait("initial_blackscreen_passed");

    for(i = 0; i < split_list.size; i++)
    {
        unhide(split_list[i]);
        time = mob_wait_split(split_list[i]);
        split(split_list[i], time);
    } 
}

mob_wait_split( split )
{
    switch (split) {
    case "Dryer": 
        flag_wait("dryer_cycle_active");
        break;  

    case "Gondola1":
        flag_wait("fueltanks_found");
        flag_wait("gondola_in_motion");
        break;  
        
    case "Plane1":
    case "Plane2":
    case "Plane3":
        flag_wait("plane_boarded");
        break;  

    case "Gondola2":
    case "Gondola3":
        flag_wait("gondola_in_motion");
        break;  

    case "Codes":
        level waittill_multiple( "nixie_final_" + 386, "nixie_final_" + 481, "nixie_final_" + 101, "nixie_final_" + 872 );
        break;  

    case "End":
        wait 10;
        while( isdefined(level.m_headphones) ) wait 0.05;
        break;  

    case "Fight":
        level waittill("end_game");
        break;        
    }

    return GetTime(); 
}

split(split_name, time)
{
    level.splits[split_name].color = level.complete_color;
    level.splits[split_name] settext(game_time_string(time - level.timer_level_start_time)); 
}

unhide(split_name)
{
    level.splits[split_name].alpha = 0.8;
}

create_new_split(split_name, yoffset)
{
    y = yoffset;
    y += (level.splits.size - 1) * 16;
    level.splits[split_name] = newHudElem();
    level.splits[split_name].alignx = "left";
    level.splits[split_name].aligny = "center";
    level.splits[split_name].horzalign = "left";
    level.splits[split_name].vertalign = "top";
    level.splits[split_name].x = -62;
    level.splits[split_name].y = -34 + y;
    level.splits[split_name].fontscale = 1.4;
    level.splits[split_name].hidewheninmenu = 0;
    level.splits[split_name].alpha = 0.2;
    level.splits[split_name].color = level.active_color;
    set_split_label(split_name);
    level thread split_start_thread(split_name);
}

set_split_label(split_name)
{
    switch (split_name) {
    case "Jetgun": level.splits[split_name].label = &"^3Jetgun ^7"; break;
    case "Tower": level.splits[split_name].label = &"^3Tower ^7"; break;
    case "NML": level.splits[split_name].label = &"^3NML ^7"; break;
    case "Boxes": level.splits[split_name].label = &"^3Boxes ^7"; break;
    case "Staff 1": level.splits[split_name].label = &"^3Staff I ^7"; break;
    case "Staff 2": level.splits[split_name].label = &"^3Staff II ^7"; break;
    case "Staff 3": level.splits[split_name].label = &"^3Staff III ^7"; break;
    case "Staff 4": level.splits[split_name].label = &"^3Staff IV ^7"; break;
    case "AFD": level.splits[split_name].label = &"^3AFD ^7"; break;
    case "Dryer": level.splits[split_name].label = &"^3Dryer ^7"; break;
    case "Gondola1": level.splits[split_name].label = &"^3Gondola I ^7"; break;
    case "Gondola2": level.splits[split_name].label = &"^3Gondola II ^7"; break;
    case "Gondola3": level.splits[split_name].label = &"^3Gondola III ^7"; break;
    case "Plane1": level.splits[split_name].label = &"^3Plane I ^7"; break;
    case "Plane2": level.splits[split_name].label = &"^3Plane II ^7"; break;
    case "Plane3": level.splits[split_name].label = &"^3Plane III ^7"; break;
    case "Codes": level.splits[split_name].label = &"^3Codes ^7"; break;
    case "Fight": level.splits[split_name].label = &"^Fight ^7"; break;
    case "End": level.splits[split_name].label = &"^3End ^7"; break;
    }
}

split_start_thread(split_name)
{
    flag_wait("initial_blackscreen_passed");
    level.splits[split_name] SetTenthsTimerUp(0.05);
}

persistent_upgrades_bank()
{
    pers_perks = strtok("board|revive|multikill_headshots|insta_kill|jugg|carpenter|perk_lose|pistol_points|double_points|sniper|box_weapon|nube", "|")

    create_bool_dvar( "pers_insta_kill", 0 )
    create_bool_dvar( "full_bank", 1 )
    create_bool_dvar( "pers_cash_back", 1 )

    foreach(pers_perk in pers_perks)
        create_bool_dvar( "pers_" + pers_perk, 1 )
    
    foreach (pers_perk in pers_perks)
	{
        if( getDvar( "pers_" + pers_perk ) )
        {
            self maps\mp\zombies\_zm_stats::set_global_stat(level.pers_upgrades[pers_perk].stat_names[0], level.pers_upgrades[pers_perk].stat_desired_values[0]);
            wait_network_frame();
        } 
	}
    
    if( getDvar( "pers_cash_back" ))
    {
        self maps\mp\zombies\_zm_stats::set_global_stat(level.pers_upgrades["cash_back"].stat_names[0], level.pers_upgrades["cash_back"].stat_desired_values[0]);
        self maps\mp\zombies\_zm_stats::set_global_stat(level.pers_upgrades["cash_back"].stat_names[1], level.pers_upgrades["cash_back"].stat_desired_values[1]);
    }

    bank_points = (getDvarInt("full_bank") > 0) * 250;
	if(bank_points)
	{
		self maps\mp\zombies\_zm_stats::set_map_stat("depositBox", bank_points, level.banking_map);
		self.account_value = bank_points;
	}
}

is_tranzit()
{
	return level.script == "zm_transit" &&  level.scr_zm_ui_gametype_group == "zclassic";
}

is_mob()
{
	return level.script == "zm_prison";
}

is_origins()
{
	return level.script == "zm_tomb";
}

game_time_string( duration )
{
        time_string = "";

        total_sec = int(duration / 1000);
        total_min = int(total_sec / 60);
		remaining_sec = total_sec % 60;
        remaining_ms = (duration % 1000)/10; 

        if(total_min > 9)       { time_string += total_min + ":"; }
        else                    { time_string += "0" + total_min + ":"; }
        if(remaining_sec > 9)   { time_string += remaining_sec + "."; }
        else                    { time_string += "0" + remaining_sec + "."; }
        if(remaining_ms > 9)    { time_string += remaining_ms; }
        else                    { time_string += "0" + remaining_ms; } 

        return time_string;
}

create_bool_dvar( dvar, start_val )
{
    
    if( getDvar( dvar ) == "" ) 
		setDvar( dvar, (1 * isDefined(start_val)) );
}

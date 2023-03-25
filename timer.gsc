#include maps\mp\_utility;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include common_scripts\utility;

init()
{
    level.splits = [];
    level.ingame_timer_version = "V1.1";
    level.active_color = (0.82, 0.97, 0.97);
    level.complete_color = (0.01, 0.62, 0.74);

    solo = level.is_forever_solo_game;
    
    if(is_origins())
    {
        if(solo)    level thread timer( strtok("NML|Boxes|Staff 1|Staff 2|Staff 3|Staff 4|AFD|End", "|"), 125);
        else        level thread timer( strtok("Boxes|AFD|End", "|"), 125 );
    }  
    else if(is_mob())
    {
        if(solo)    level thread timer( strtok("Dryer|Gondola1|Plane1|Gondola2|Plane2|Gondola3|Plane3|Codes|Done", "|"), 65);
        else        level thread timer( strtok("Plane1|Plane2|Plane3|Codes|End", "|"), 65);   
    } 
    else if(is_tranzit())
    {
        if(solo)    level thread timer( strtok("Jetgun|Tower|EMP", "|"), 15);
        level thread upgrades();
    }
    else
    {
        return;
    }
    
    level thread on_player_connect();
    flag_wait("initial_blackscreen_passed");
    level.timer_level_start_time = gettime();
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
    self thread persistent_upgrades_bank();
    wait 2.5;
    self iPrintLn("^6GSC EE Autotimer ^5" + level.ingame_timer_version + " ^8| ^3github.com/HuthTV/BO2-Easter-Egg-GSC-timer");
}

upgrades()
{
    level.persistent_upgrades = [];
    
    foreach(upgrade in level.pers_upgrades)
    {
        for(i = 0; i < upgrade.stat_names.size; i++)
        { 
            level.persistent_upgrades[level.persistent_upgrades.size] = upgrade.stat_names[i];
            print("stat: added " + upgrade.stat_names[i]);
        }
    }
  
    create_bool_dvar( "pers_insta_kill", 0 );
    create_bool_dvar( "full_bank", 1 );

    foreach(pers_perk in level.persistent_upgrades)
	{
        if(pers_perk != "pers_insta_kill")
            create_bool_dvar( pers_perk, 1 );
	}
}

timer( split_list, yoffset )
{
    level endon( "game_ended" );

    foreach(split in split_list)
        create_new_split(split, yoffset); 

    flag_wait("initial_blackscreen_passed");
    for(i = 0; i < split_list.size; i++)
    {
        unhide(split_list[i]);
        time = wait_split(split_list[i]);
        split(split_list[i], time);
    } 
}

wait_split( split )
{
    switch (split) 
    {
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

        //Mob splits
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

        case "Done":
            wait 10;
            while( isdefined(level.m_headphones) ) wait 0.05;
            break;  

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

        //General split
        case "End":
            level waittill("end_game");
            break;  
    }

    return gettime(); 
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
    level.splits[split_name] = newhudelem();
    level.splits[split_name].alignx = "left";
    level.splits[split_name].aligny = "center";
    level.splits[split_name].horzalign = "left";
    level.splits[split_name].vertalign = "top";
    level.splits[split_name].x = -62;
    level.splits[split_name].y = -34 + y;
    level.splits[split_name].fontscale = 1.4;
    level.splits[split_name].hidewheninmenu = 1;
    level.splits[split_name].alpha = 0;
    level.splits[split_name].color = level.active_color;
    set_split_label(split_name);
    level thread split_start_thread(split_name);
}

set_split_label(split_name)
{
    switch (split_name) 
    {
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
        case "Fight":
        case "End": 
        case "EMP":
        case "Done":
            level.splits[split_name].label = &"^3End ^7"; break;
    }
}

split_start_thread(split_name)
{
    flag_wait("initial_blackscreen_passed");
    level.splits[split_name] settenthstimerup(0.05);
}

persistent_upgrades_bank()
{
    foreach(upgrade in level.pers_upgrades)
    {
        for(i = 0; i < upgrade.stat_names.size; i++)
        {
            val = 0;
            if(getDvarInt(upgrade.stat_names[i]))
                val = upgrade.stat_desired_values[i];

            self maps\mp\zombies\_zm_stats::set_client_stat(upgrade.stat_names[i], val);
            wait_network_frame();
        }
    }

    bank_points = (getdvarint("full_bank") > 0) * 250;
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
    if( getdvar( dvar ) == "" ) 
		setdvar( dvar, start_val);
}

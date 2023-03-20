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

    if(is_origins())
    {
        if(level.is_forever_solo_game)
            level thread origins_timer( strtok("NML|Boxes|Staff 1|Staff 2|Staff 3|Staff 4|AFD|End", "|") );
        else
            level thread origins_timer( strtok("Boxes|AFD|End", "|") );
    }  
    else if(is_mob()) 
    {
        if(level.is_forever_solo_game)
            level thread mob_timer( strtok("Dryer|Gondola1|Plane1|Gondola2|Plane2|Gondola3|Plane3|Codes|End", "|") );
        else
            level thread mob_timer( strtok("Plane1|Plane2|Plane3|Codes|Fight", "|") );   
    } 
    else if(is_tranzit() && level.is_forever_solo_game) 
    {
        level thread tranzit_timer( strtok("Jetgun|Tower|End", "|") );
    }
    else
    {
        return;
    }
    
    level thread on_player_connect();
    level thread tick_tracker();

    flag_wait("initial_blackscreen_passed");
    level.starttick = level.ticks;
    level.level_start_time = GetTime();
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
    self.score = 2500000;
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
        tranzit_wait_split(split_list[i]);
        split(split_list[i]);
    } 
}

tranzit_wait_split( split )
{
    switch (split) 
    {
        case "Jetgun": 
            while(level.sq_progress["rich"]["A_jetgun_built"] == 0) wait 0.05;
            return;

        case "Tower":
            while(level.sq_progress["rich"]["A_jetgun_tower"] == 0) wait 0.05;
            return;
            
        case "End":
            while(level.sq_progress["rich"]["FINISHED"] == 0) wait 0.05;
            return;
    }     
}

origins_timer( split_list )
{
    foreach(split in split_list)
        create_new_split(split, 65);
    
    flag_wait("initial_blackscreen_passed");

    for(i = 0; i < split_list.size; i++)
    {
        unhide(split_list[i]);
        origins_wait_split(split_list[i]);
        split(split_list[i]);
    } 
}

origins_wait_split( split )
{
    switch (split) {
    case "NML": 
        flag_wait("activate_zone_nml");
        return;

    case "Boxes":
        while(level.n_soul_boxes_completed < 4) wait 0.05;
        wait 4;
        return;
        
    case "Staff 1":
    case "Staff 2":
    case "Staff 3":
    case "Staff 4":
        curr = level.n_staffs_crafted;
        while(curr <= level.n_staffs_crafted) wait 0.05;
        //Change staff label?
        return;

    case "AFD":
        flag_wait("ee_all_staffs_placed");
        return;

    case "End":
        level waittill("end_game");
        return;
    }   
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
        mob_wait_split(split_list[i]);
        split(split_list[i]);
    } 
}

mob_wait_split( split )
{
    switch (split) {
    case "Dryer": 
        flag_wait("dryer_cycle_active");
        return;

    case "Gondola1":
        flag_wait("fueltanks_found");
        flag_wait("gondola_in_motion");
        return;
        
    case "Plane1":
    case "Plane2":
    case "Plane3":
        flag_wait("plane_boarded");
        return;

    case "Gondola2":
    case "Gondola3":
        flag_wait("gondola_in_motion");
        return;

    case "Codes":
        level waittill_multiple( "nixie_final_" + 386, "nixie_final_" + 481, "nixie_final_" + 101, "nixie_final_" + 872 );
        return;

    case "End":
        wait 10;
        while( isdefined(level.m_headphones) ) wait 0.05;
        return;

    case "Fight":
        level waittill("end_game");
        return;        
    }
}

split(split_name)
{
    level.splits[split_name].color = level.complete_color;
    level.splits[split_name] settext(tick_time_string(level.ticks - level.starttick));
    print("total ticks - " + (level.ticks - level.starttick));
    print("game_time_string - " + game_time_string());
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
    level.splits[split_name].alpha = 0.8;
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
    case "Staff 1": level.splits[split_name].label = &"^3Staff 1 ^7"; break;
    case "Staff 2": level.splits[split_name].label = &"^3Staff 2 ^7"; break;
    case "Staff 3": level.splits[split_name].label = &"^3Staff 3 ^7"; break;
    case "Staff 4": level.splits[split_name].label = &"^3Staff 4 ^7"; break;
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
    level.splits[split_name] SetTenthsTimerUp(0.01);
}

tick_tracker()
{
    level.tick_hud = newHudElem();
	level.tick_hud.alignx = "center";
	level.tick_hud.aligny = "bottom";
	level.tick_hud.horzalign = "right";
	level.tick_hud.vertalign = "top";
	level.tick_hud.x += 0;
	level.tick_hud.y += 0;
	level.tick_hud.fontscale = 1.4;
	level.tick_hud.hidewheninmenu = 0;
    level.tick_hud.label = &"TICKS :^3";
    level.tick_hud.alpha = 0.8;
    
    level.ticks = 1;

    while (true) 
    {
        level.tick_hud setvalue(level.ticks);
        level.ticks++;
        wait 0.05;
    }

}

persistent_upgrades_bank()
{
    pers_perks = array("board", "revive", "multikill_headshots", "insta_kill", "jugg", "carpenter", "perk_lose", "pistol_points", "double_points", "sniper", "box_weapon", "nube");

    if( getDvar( "full_bank" ) == "" ) 
		setDvar( "full_bank", 1 );

    if( getDvar( "pers_insta_kill" ) == "" )
			setDvar( "pers_insta_kill", 0 );

    if( getDvar( "pers_cash_back" ) == "" )
			setDvar( "pers_cash_back", 1 );

    foreach(pers_perk in pers_perks)
	{
 		if( getDvar( "pers_" + pers_perk ) == "" )
			setDvar( pers_perk, 1 );
	}
    
    foreach (pers_perk in pers_perks)
	{
        self maps\mp\zombies\_zm_stats::set_global_stat(level.pers_upgrades[pers_perk].stat_names[0], level.pers_upgrades[pers_perk].stat_desired_values[0]);
        wait_network_frame();
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
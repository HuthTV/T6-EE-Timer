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

    if(is_origins())
    {
        if(level.is_forever_solo_game)
        {
            level thread solo_origins_timer();
        }
        else
        {
            level thread coop_origins_timer();
        }
    }  
    else if(is_mob()) 
    {
        if(level.is_forever_solo_game)
        {
            level thread solo_mob_timer();
        }
        else
        {
            level thread coop_mob_timer();
        } 
    } 
    else if(is_tranzit() && level.is_forever_solo_game) 
    {
        level thread solo_tranzit_timer();
    }
    else
        return;

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
    wait 2;
    iPrintLn("^3EE Timer ^7" + level.version);
    wait 1;
    iPrintLn("source: github.com/HuthTV/BO2-Easter-Egg-GSC-timer");
}

solo_tranzit_timer()
{
    split_list = array("Jetgun", "Tower", "End");
    foreach(split in split_list)
    {
        create_new_split(split);
    }    
    flag_wait("initial_blackscreen_passed");

    unhide("Jetgun");
    while(level.sq_progress["rich"]["A_jetgun_built"] == 0) wait 0.05;
    split("Jetgun");

    unhide("Tower");
    while(level.sq_progress["rich"]["A_jetgun_tower"] == 0) wait 0.05;
    split("Tower");

    unhide("End");
    while(level.sq_progress["rich"]["FINISHED"] == 0) wait 0.05;
    split("End");
}

solo_origins_timer()
{
    split_list = array("NML", "Boxes", "Staff 1", "Staff 2", "Staff 3", "Staff 4", "AFD", "End");
    foreach(split in split_list)
    {
        create_new_split(split);
    } 
    flag_wait("initial_blackscreen_passed");

    unhide("NML");
    flag_wait("activate_zone_nml");
    split("NML");

    unhide("Boxes");
    while(level.n_soul_boxes_completed < 4) wait 0.05;
    wait 4;
    split("Boxes");

    unhide("Staff 1");
    while(level.n_staffs_crafted < 1) wait 0.05;
    split("Staff 1");
    //change staff label

    unhide("Staff 2");
    while(level.n_staffs_crafted < 2) wait 0.05;
    split("Staff 2");
    //change staff label

    unhide("Staff 3");
    while(level.n_staffs_crafted < 3) wait 0.05;
    split("Staff 3");
    //change staff label

    //change staff label
    unhide("Staff 4");
    while(level.n_staffs_crafted < 4) wait 0.05;
    split("Staff 4");

    unhide("AFD");
    flag_wait("ee_all_staffs_placed");
    split("AFD");

    unhide("End");
    level waittill("end_game");
    split("End"); 
}

coop_origins_timer()
{
    split_list = array("Boxes", "AFD", "End");
    foreach(split in split_list)
    {
        create_new_split(split);
    } 
    flag_wait("initial_blackscreen_passed");

    unhide("Boxes");
    while(level.n_soul_boxes_completed < 4) wait 0.05;
    wait 4;
    split("Boxes");

    unhide("AFD");
    flag_wait("ee_all_staffs_placed");
    split("AFD");

    unhide("End");
    level waittill("end_game");
    split("End"); 
}

solo_mob_timer()
{
    split_list = array("Dryer", "Gondola1", "Plane1", "Gondola2", "Plane2", "Gondola3", "Plane3", "Codes", "End");
    foreach(split in split_list)
    {
        create_new_split(split);
    } 
}

coop_mob_timer()
{
    split_list = array("Plane1", "Plane2", "Plane3", "Codes", "End");
    foreach(split in split_list)
    {
        create_new_split(split);
    }  
}

split(split_name)
{
    level.splits[split_name] settext(tick_time_string(level.ticks - level.starttick));
    print("total ticks - " + (level.ticks - level.starttick));
    print("game_time_string - " + game_time_string());
}

unhide(split_name)
{
    level.splits[split_name].alpha = 0.8;
}

create_new_split(split_name)
{
    level.splits[split_name] = newHudElem();
    level.splits[split_name].alignx = "left";
	level.splits[split_name].aligny = "center";
	level.splits[split_name].horzalign = "left";
	level.splits[split_name].vertalign = "top";
    level.splits[split_name].x = -62;
	level.splits[split_name].y = -34 + ( (level.splits.size - 1) * 16);
    level.splits[split_name].fontscale = 1.4;
    level.splits[split_name].hidewheninmenu = 0;
    level.splits[split_name].alpha = 0.8;
    level.splits[split_name].fontscale = 1.4;
    set_split_label(split_name);
    level thread split_start_thread(split_name);
}

set_split_label(split_name)
{
    switch (split_name) {
    case "Jetgun": level.splits[split_name].label = &"Jetgun ^3"; break;
    case "Tower": level.splits[split_name].label = &"Tower ^3"; break;
    case "End": level.splits[split_name].label = &"End ^3"; break;
    case "NML": level.splits[split_name].label = &"NML ^3"; break;
    case "Boxes": level.splits[split_name].label = &"Boxes ^3"; break;
    case "Staff 1": level.splits[split_name].label = &"Staff 1 ^3"; break;
    case "Staff 2": level.splits[split_name].label = &"Staff 2 ^3"; break;
    case "Staff 3": level.splits[split_name].label = &"Staff 3 ^3"; break;
    case "Staff 4": level.splits[split_name].label = &"Staff 4 ^3"; break;
    case "Dryer": level.splits[split_name].label = &"Dryer ^3"; break;
    case "Gondola1": level.splits[split_name].label = &"Gondola I ^3"; break;
    case "Plane1": level.splits[split_name].label = &"Plane I ^3"; break;
    case "Gondola2": level.splits[split_name].label = &"Gondola II ^3"; break;
    case "Plane2": level.splits[split_name].label = &"Plane II ^3"; break;
    case "Gondola3": level.splits[split_name].label = &"Gondola III ^3"; break;
    case "Plane3": level.splits[split_name].label = &"Plane III ^3"; break;
    case "Codes": level.splits[split_name].label = &"Codes ^3"; break;
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
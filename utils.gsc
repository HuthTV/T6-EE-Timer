is_tranzit()
{
	if(level.script == "zm_transit" && level.scr_zm_map_start_location == "transit" && level.scr_zm_ui_gametype_group == "zclassic") return true;
	return false;
}

is_mob()
{
	if(level.script == "zm_prison") return true;
	return false;
}

is_origins()
{
	if(level.script == "zm_tomb") return true;
	return false;
}

game_time_string()
{
        time_string = "";
        duration = int(GetTime() - level.level_start_time);
	
        mid = int(duration / 1000);
        
        min = mid / 60;
		sec = mid % 60;

        m_m = min * 60000;
        s_m = sec * 1000;

        ms = duration % 1000;     
	
        if(sec > 9)
	{ time_string = time_string + int(min) + ":" + sec + "." + int(ms);}
	else
	{ time_string = time_string + int(min) + ":0" + sec + "." + int(ms);}

        return time_string;
}

tick_time_string(ticks)
{
    
    ms = ticks * 50;
    total_sec = int(ms / 1000);
    seconds = (total_sec % 60); 
    min = int(total_sec / 60);
    ms_left = (ticks % 20) * 5;
    time_string = "";

    if(min > 9)
        { time_string += min + ":"; }
    else
        { time_string += "0" + min + ":"; }

    if(seconds > 9)
        { time_string += seconds + ":"; }
    else
        { time_string += "0" + seconds + ":"; }

    if(ms_left > 9)
        { time_string += ms_left; }
    else
        { time_string += "0" + ms_left; }

    return time_string;
}
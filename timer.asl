state("plutonium-bootstrapper-win32"){}

startup
{
	refreshRate = 40;
	vars.mapName = "zm_map";
    vars.split = 0;
	vars.splitValue = 0;
	vars.timeValue = 0;
    vars.solo = 1;

    vars.solo_map_splits = new Dictionary<string, string[]>
    {
        { "zm_transit", new[] { "Jetgun/Power Off", "Tower/Turbines", "Emp" } },
        { "zm_highrise", new[] { "Symbols", "High Maintenance" } },
        { "zm_prison", new[] { "Dryer", "Gondola 1", "Flight 1", "Gondola 2", "Flight 2", "Gondola 3", "Flight 3", "Codes", "Headphones" } },
        { "zm_buried", new[] { "Boxhit", "Ghosts", "Cipher", "Time Travel", "Sharpshooter", "Mined Games (Super EE)" } },
        { "zm_tomb", new[] { "No Man's Land", "Chests Filled", "Staff 1", "Staff 2", "Staff 3", "Staff 4", "Ascend from Darkness", "Rain Fire", "Freedom" } }
    };

    vars.coop_map_splits = new Dictionary<string, string[]>
    {
        { "zm_transit", new[] { "Jetgun/Power Off", "Tower/Turbines", "Emp" } },
        { "zm_highrise", new[] { "Symbols", "High Maintenance" } },
        { "zm_prison", new[] { "Flight 1", "Flight 2", "Flight 3", "Codes", "Headphones", "Showdown" } },
        { "zm_buried", new[] { "Cipher", "Time Travel", "Sharpshooter", "Mined Games (Super EE)" } },
        { "zm_tomb", new[] { "Chests Filled", "Ascend from Darkness", "Freedom" } }
    };

	vars.map_uiNames = new Dictionary<string, string>
	{
		{ "zm_transit", "Tranzit" },
		{ "zm_highrise", "Die Rise" },
		{ "zm_prison", "Mob of the Dead" },
		{ "zm_buried", "Buried" },
		{ "zm_tomb", "Origins" }
	};

    string soloTag = ">>>> SOLO <<<<";
    settings.Add(soloTag);
    foreach (var map in vars.solo_map_splits)
    {
        string mapString = map.Key + "_solo";
        settings.Add(mapString, true, vars.map_uiNames[map.Key], soloTag);

        foreach (var split in map.Value)
        {
            settings.Add(split + "_solo", true, split, mapString);
        }
    }

    string coopTag = ">>>> COOP <<<<";
    settings.Add(coopTag);
    foreach (var map in vars.coop_map_splits)
    {
        string mapString = map.Key + "_coop";
        settings.Add(mapString, true, vars.map_uiNames[map.Key], coopTag);

        foreach (var split in map.Value)
        {
            settings.Add(split + "_coop", true, split, mapString);
        }
    }

	vars.filePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"Plutonium", "storage", "t6", "raw", "scriptdata", "T6EE", "T6EE.dat");
}

update
{
    try
    {
        if(File.Exists(vars.filePath))
        {
            using (StreamReader r = new StreamReader(new FileStream(vars.filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)))
            {
                int parsedTime, parsedSplits, solo;
                string[] data = r.ReadToEnd().Split('|');
                if (data.Length >= 4)
                {
                    string newMapName = data[0];
                    if(int.TryParse(data[1], out parsedSplits) && int.TryParse(data[2], out parsedTime) && int.TryParse(data[3], out solo))
                    {
                        if(vars.mapName != newMapName)
                        {
                            vars.split = 0;
                        }
                        vars.splitValue = parsedSplits;
                        vars.timeValue = parsedTime;
                        vars.mapName = newMapName;
                        vars.solo = solo;
                    }
                }
            }
        }
    }
    catch (Exception) {}
}

gameTime
{
	return TimeSpan.FromMilliseconds( vars.timeValue );
}

isLoading
{
	return true;
}

start
{
	if(vars.timeValue == 50) //start after game writes 1st tick in T6EE.dat
	{
        vars.split = 0;
        vars.splits = (vars.solo == 1)
            ? vars.solo_map_splits[vars.mapName]
            : vars.coop_map_splits[vars.mapName];
		return true;
	}
}

split
{
	if(vars.splitValue > vars.split)
	{
		if(settings[vars.splits[vars.split++] + "_" + (vars.solo == 1 ? "solo" : "coop")])
            return true;
	}
}

reset
{
    if(vars.timeValue == 0) return true;
}

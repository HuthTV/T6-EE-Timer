state("plutonium-bootstrapper-win32")
{
}

startup
{
	refreshRate = 40;
	vars.mapName = "zm_map";
    vars.split = 0;
	vars.splitValue = 0;
	vars.timeValue = 0;

    vars.map_splits = new Dictionary<string, string[]>
    {
        { "zm_transit", new[] { "Jetgun/Power Off", "Tower/Turbines", "Emp" } },
        { "zm_highrise", new[] { "Symbols", "Sniper", "High Maintenance" } },
        { "zm_prison", new[] { "Dryer", "Gondola 1", "Flight 1", "Gondola 2", "Flight 2", "Gondola 3", "Flight 3", "Codes", "Headphones" } },
        { "zm_buried", new[] { "Boxhit", "Ghosts", "Cipher", "Time Travel", "Sharpshooter" } },
        { "zm_tomb", new[] { "No Man's Land", "Chests Filled", "Staff 1", "Staff 2", "Staff 3", "Staff 4", "Ascend from Darkness", "Rain Fire", "Freedom" } }
    };

	vars.map_uiNames = new Dictionary<string, string>
	{
		{ "zm_transit", "Tranzit" },
		{ "zm_highrise", "Die Rise" },
		{ "zm_prison", "Mob of the Dead" },
		{ "zm_buried", "Buried" },
		{ "zm_tomb", "Origins" }
	};


    foreach (var map in vars.map_splits)
    {
        string uiName = vars.map_uiNames[map.Key];
        settings.Add(uiName); // top-level map

        foreach (var split in map.Value)
        {
            settings.Add(split, true, split, uiName); // map split
        }
    }

	vars.filePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"Plutonium", "storage", "t6", "raw", "scriptdata", "T6EE", "T6EE.dat");
}

update
{
    {
        if(File.Exists(vars.filePath))
        {
            using (StreamReader r = new StreamReader(new FileStream(vars.filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)))
            {
                int parsedSplits;
                int parsedTime;
                string[] data = r.ReadToEnd().Split('|');
                if (data.Length >= 3)
                {
                    string newMapName = data[0];
                    if (int.TryParse(data[1], out parsedSplits) && int.TryParse(data[2], out parsedTime))
                    {
                        if(vars.mapName != newMapName)
                        {
                            vars.split = 0;
                        }

                        vars.splitValue = parsedSplits;
                        vars.timeValue = parsedTime;
                        vars.mapName = newMapName;
                    }
                }
            }
        }
    } catch (Exception) {}
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
		vars.splits = vars.map_splits[vars.mapName];
		vars.split = 0;
		return true;
	}
}

split
{
	if(vars.splitValue > vars.split)
	{
		if(settings[vars.splits[vars.split++]])
            return true;
	}
}

reset
{
	if(vars.timeValue == 0)
	{
		return true;
	}
}

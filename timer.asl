state("plutonium-bootstrapper-win32")
{
	int tick:     0x002AA13C, 0x14;
    string map_name:  0x002AA13C, 0x24, 256;
}

startup
{
	refreshRate = 40;
	vars.splitValue = 0;
	vars.timeValue = 0;
    
    vars.map_splits = new Dictionary<string, string[]>
    {
        { "Tranzit", new[] { "Jetgun/Power Off", "Tower/Turbines", "Emp" } },
        { "Die Rise", new[] { "Symbols", "Sniper", "High Maintenance" } },
        { "Mob of the Dead", new[] { "Dryer", "Gondola 1", "Flight 1", "Gondola 2", "Flight 2", "Gondola 3", "Flight 3", "Codes", "Headphones" } },
        { "Buried", new[] { "Cipher", "Time Travel", "Sharpshooter" } },
        { "Origins", new[] { "No Man's Land", "Chests Filled", "Staff 1", "Staff 2", "Staff 3", "Staff 4", "Ascend from Darkness", "Rain Fire", "Freedom" } }
    };

    
    foreach (var map in vars.map_splits)
    {
        settings.Add(map.Key); // top-level parent, collapsed

        foreach (var split in map.Value)
        {
            settings.Add(split, true, split, map.Key); // child setting under map
        }
    }

	vars.timerString = "0|0";
	vars.filePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"Plutonium", "storage", "t6", "raw", "scriptdata", "timer");
}

update
{
	if(File.Exists(vars.filePath))
	{
		using (StreamReader r = new StreamReader(new FileStream(vars.filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)))
		{
			vars.timerString = r.ReadToEnd();
			string[] data = vars.timerString.Split('|');
			vars.splitValue = int.Parse(data[0]);
			vars.timeValue = int.Parse(data[1]);
		}
	}
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
	if(vars.timeValue == 50)
	{
		vars.split = 0;
		return true;
	}
}

split
{
	if(vars.splitValue > vars.split)
	{
        vars.split++;
		if(settings[vars.map_splits[vars.currentMap][vars.split]])
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
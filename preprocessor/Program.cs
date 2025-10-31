using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

class GscPreprocessor
{
    static void Main(string[] args)
    {
        // ===== ARGUMENT CHECK =====
        if (args.Length < 3)
        {
            Console.WriteLine("Usage: GscPreprocessor <input.gsc> <output.gsc> --version=XXX");
            Environment.Exit(1);
        }

        string inputPath = args[0];
        string outputPath = args[1];
        string versionValue = null;

        // ===== PARSE VERSION =====
        foreach (var arg in args)
        {
            if (arg.StartsWith("--version=", StringComparison.OrdinalIgnoreCase))
                versionValue = arg.Substring("--version=".Length);
        }

        if (string.IsNullOrEmpty(versionValue))
        {
            Console.WriteLine("Error: VERSION is mandatory. Use --version=XXX");
            Environment.Exit(1);
        }

        if (!File.Exists(inputPath))
        {
            Console.WriteLine($"Error: Input file not found: {inputPath}");
            Environment.Exit(1);
        }

        try
        {
            // ===== COLLECT DEFINES =====
            var defines = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

            // Match any #DEFINE line: #DEFINE <key> <value>
            var defineLineRegex = new Regex(@"^\s*#DEFINE\s+(\S+)\s+(.+)$", RegexOptions.IgnoreCase);

            var lines = File.ReadAllLines(inputPath).ToList();

            // Collect defines
            foreach (var line in lines)
            {
                var match = defineLineRegex.Match(line);
                if (match.Success)
                {
                    string key = match.Groups[1].Value;
                    string value = match.Groups[2].Value;
                    defines[key] = value;
                }
            }

            // Add mandatory VERSION
            defines["VERSION"] = versionValue;

            // ===== SUBSTITUTE DEFINES =====
            for (int i = 0; i < lines.Count; i++)
            {
                foreach (var kv in defines)
                {
                    lines[i] = Regex.Replace(lines[i], $@"\b{Regex.Escape(kv.Key)}\b", kv.Value);
                }
            }

            // ===== REMOVE ORIGINAL #DEFINE LINES =====
            var outputLines = lines.Where(line => !defineLineRegex.IsMatch(line)).ToArray();
            File.WriteAllLines(outputPath, outputLines);

            // ===== CONSOLE OUTPUT =====
            Console.WriteLine($"Preprocessed: {inputPath} -> {outputPath}");
            Console.WriteLine("DEFINES");

            // VERSION first
            Console.WriteLine($"  VERSION = {defines["VERSION"]}");

            // Other defines alphabetically
            foreach (var kv in defines
                     .Where(kv => !kv.Key.Equals("VERSION", StringComparison.OrdinalIgnoreCase))
                     .OrderBy(kv => kv.Key, StringComparer.OrdinalIgnoreCase))
            {
                Console.WriteLine($"  {kv.Key} = {kv.Value}");
            }

            Console.WriteLine();
        }
        catch (Exception ex)
        {
            Console.WriteLine("Error: " + ex.Message);
            Environment.Exit(1);
        }
    }
}

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using static System.Console;
using static System.StringComparer;

static class ToolboxIndex
{
    const string BaseUrl = "https://raw.githubusercontent.com/royalapplications/toolbox/master/Dynamic%20Folder/";

    static readonly Dictionary<string, string> InterpreterScriptExtensions = new()
    {
        { "json", ".json" },
        { "php", ".php" },
        { "powershell", ".ps1" },
        { "python", ".py" },
    };

    static int Main(string[] args)
    {
        if (args.Length < 1)
            return Error("Missing required argument: <input-dir>");

        string inputDir = args[0];
        if (string.IsNullOrEmpty(inputDir) || !Directory.Exists(inputDir))
            return Error($"Input directory not found or not accessible: {inputDir}");

        inputDir = Path.GetFullPath(inputDir);
        bool migrateToRdfx = args.Length > 1 && args[1] is "--migrate-rdfe-to-rdfx";

        return ProcessFiles(inputDir, migrateToRdfx);

        static int Error(string message)
        {
            Console.Error.WriteLine($"""
                {message}

                Usage: {typeof(ToolboxIndex).Assembly.GetName().Name} <input-dir> [--migrate-rdfe-to-rdfx]

                Arguments:
                    <input-dir>
                        Path to the directory containing .rdfe/.rdfx files to process.
                    --migrate-rdfe-to-rdfx
                        If specified, migrates .rdfe (JSON) files to .rdfx (XML) format,
                        removing the original .rdfe files. (optional; default = no)
                """);
            return 1;
        }
    }

    static int ProcessFiles(string inputDir, bool migrateToRdfx)
    {
        var extensionsToCleanup = new HashSet<string>(InterpreterScriptExtensions.Values, OrdinalIgnoreCase);
        var filesToProcess = new SortedDictionary<string, SortedSet<string>>(OrdinalIgnoreCase);
        var filesToCleanup = new SortedSet<string>(OrdinalIgnoreCase);

        foreach (string dir in Directory.EnumerateDirectories(inputDir, "*", SearchOption.AllDirectories))
        {
            var sourceFiles = new SortedSet<string>(OrdinalIgnoreCase);
            var toCleanup = new HashSet<string>(OrdinalIgnoreCase);

            foreach (string file in Directory.EnumerateFiles(dir))
            {
                string ext = Path.GetExtension(file);

                if (ext is ".rdfe" or ".rdfx")
                    sourceFiles.Add(file);

                if (extensionsToCleanup.Contains(ext) || Path.GetFileName(file) is "README.md")
                    toCleanup.Add(file);
            }

            if (sourceFiles.Count > 0)
            {
                filesToProcess.Add(dir, sourceFiles);
                filesToCleanup.UnionWith(toCleanup);
            }
        }

        string prefix = inputDir + Path.DirectorySeparatorChar;
        var indexEntries = new List<JsonIndexEntry>();

        foreach ((string dir, var dirFiles) in filesToProcess)
        {
            var readme = new List<DynamicFolderExport>();

            foreach (string file in dirFiles)
            {
                WriteLine($"Processing {file}");

                bool isJson = Path.GetExtension(file) is ".rdfe";
                DynamicFolderExport rdf;

                try
                {
                    rdf = isJson ? RdfJson.Load(file) : RdfXml.Load(file);
                }
                catch (Exception ex)
                {
                    Error.WriteLine($"Could not load '{file}': {ex}");
                    return 1;
                }

                if (rdf.Objects.Count is not 1)
                {
                    Error.WriteLine($"Cannot process '{file}' because 'Objects' is missing or empty");
                    return 1;
                }

                rdf.FileName = Path.GetFileName(file);
                if (isJson && migrateToRdfx)
                {
                    string newName = Path.ChangeExtension(file, ".rdfx");
                    RdfXml.Save(rdf, newName);
                    WriteLine($"Migrated to {newName}  (will delete .rdfe file)");

                    filesToCleanup.Add(file);
                    rdf.FileName = Path.GetFileName(newName);
                }

                readme.Add(rdf);
                ExtractScriptFiles(rdf, file, filesToCleanup);

                string shortPath = dir[prefix.Length..];
                var dirSegments = new List<string>(shortPath.Split(Path.DirectorySeparatorChar));

                var urlSegments = new List<string>(dirSegments.Count + 1);
                foreach (string segment in dirSegments)
                    urlSegments.Add(Uri.EscapeDataString(segment));
                urlSegments.Add(Uri.EscapeDataString(rdf.FileName));

                var obj = rdf.Objects[0];
                indexEntries.Add(new JsonIndexEntry
                {
                    Categories = dirSegments,
                    ContentURL = BaseUrl + string.Join('/', urlSegments),
                    Description = obj.Description,
                    DynamicCredentialScriptInterpreter = obj.DynamicCredentialScriptInterpreter ?? "",
                    Name = Path.GetFileNameWithoutExtension(rdf.FileName),
                    Notes = obj.Notes ?? "",
                    ScriptInterpreter = obj.ScriptInterpreter ?? "",
                });
            }

            Markdown.GenerateReadme(readme, dir, filesToCleanup);
        }

        JsonIndex.Generate(indexEntries, inputDir);
        WriteLine($"Processed {indexEntries.Count:N0} files.");
        WriteLine();

        foreach (string file in filesToCleanup)
        {
            WriteLine($"Removing {file}");
            File.Delete(file);
        }

        return 0;
    }

    static void ExtractScriptFiles(DynamicFolderExport rdf, string filePath, SortedSet<string> filesToCleanup)
    {
        Debug.Assert(rdf.Objects.Count is 1);
        var data = rdf.Objects[0];

        string baseName = Path.GetFileNameWithoutExtension(filePath);
        string dir = Path.GetDirectoryName(filePath)!;

        rdf.ScriptFile = WriteFile(data.Script, data.ScriptInterpreter, dir, baseName + ".script", filesToCleanup);

        rdf.DynamicCredentialScriptFile = WriteFile(data.DynamicCredentialScript,
            data.DynamicCredentialScriptInterpreter, dir, baseName + ".dynamicCredential", filesToCleanup);
    }

    static string? WriteFile(string? script, string? interpreter, string dir, string baseName,
        SortedSet<string> filesToDelete)
    {
        Debug.Assert(Path.IsPathRooted(dir));
        Debug.Assert(!baseName.Contains(Path.DirectorySeparatorChar));

        if (string.IsNullOrWhiteSpace(script))
            return null;

        if (!InterpreterScriptExtensions.TryGetValue(interpreter ?? "", out string? extension))
            throw new Exception($"Unknown file extension for interpreter: '{interpreter}'");

        string filePath = Path.Join(dir, $"{baseName}{extension}");
        File.WriteAllText(filePath, script);
        filesToDelete.Remove(filePath);
        return Path.GetFileName(filePath);
    }
}

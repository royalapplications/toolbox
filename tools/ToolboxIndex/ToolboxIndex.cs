using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Text.Json.Nodes;
using static System.Console;
using static System.StringComparer;

static class ToolboxIndex
{
    const string BaseUrl = "https://raw.githubusercontent.com/royalapplications/toolbox/master/Dynamic%20Folder/";
    const string GeneratedSuffix = ".autogen";

    static readonly Dictionary<string, (string Extension, string? CommentPrefix)> KnownInterpreters = new(OrdinalIgnoreCase)
    {
        { "bash", (".sh", "#") },
        { "javascript", (".js", "//") },
        { "json", (".json", null) }, // avoid JSON comments; can break consumers if their parses aren't tolerant
        { "perl", (".pl", "#") },
        { "php", (".php", "#") },
        { "powershell", (".ps1", "#") },
        { "python", (".py", "#") },
        { "ruby", (".rb", "#") },
    };

    static int Main(string[] args)
    {
        if (args.Length < 1)
            return Error("Missing required argument: <input-dir>");

        string inputDir = args[0];
        if (string.IsNullOrEmpty(inputDir) || !Directory.Exists(inputDir))
            return Error($"Input directory not found or not accessible: {inputDir}");

        inputDir = Path.GetFullPath(inputDir);

        var extractScripts = false;
        var generateReadme = false;
        var migrateToRdfx = false;
        for (var i = 1; i < args.Length; i++)
        {
            switch (args[i])
            {
            case "--extract-script-files":
                extractScripts = true;
                break;
            case "--generate-readme-files":
                generateReadme = true;
                break;
            case "--migrate-rdfe-to-rdfx":
                migrateToRdfx = true;
                break;
            default:
                return Error($"Invalid argument: '{args[i]}'");
            }
        }

        return ProcessFiles(inputDir, extractScripts, generateReadme, migrateToRdfx);

        static int Error(string message)
        {
            Console.Error.WriteLine($"""
                {message}

                Usage: {typeof(ToolboxIndex).Assembly.GetName().Name} <input-dir> [options...]

                Required arguments:
                    <input-dir>
                        Path to the directory containing .rdfe/.rdfx files to process.

                Options:
                    --extract-script-files
                        If specified, extracts `Script` and `DynamicCredentialScript` contents
                        into files placed next to the original .rdfe/.rdfx files. (optional; default = no)
                    --generate-readme-files
                        If specified, converts the HTML `Notes` content in .rdfe/.rdfx files into
                        Markdown, writing one `README.md` file per directory.  (optional; default = no)
                    --migrate-rdfe-to-rdfx
                        If specified, migrates .rdfe (JSON) files to .rdfx (XML) format,
                        removing the original .rdfe files. (optional; default = no)
                """);
            return 1;
        }
    }

    static int ProcessFiles(string inputDir, bool extractScripts, bool generateReadme, bool migrateToRdfx)
    {
        var extensionsToCleanup = new HashSet<string>(OrdinalIgnoreCase);
        foreach ((string extension, _) in KnownInterpreters.Values)
            extensionsToCleanup.Add(extension);

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

                if (extractScripts)
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

            if (generateReadme)
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

        rdf.ScriptFile = WriteFile(data.Script, data.ScriptInterpreter, dir, baseName + ".script",
            rdf.FileName, filesToCleanup);

        if (data.DynamicCredentialScript is string credScript
            && data.DynamicCredentialScriptInterpreter is string credInterpreter
            && !IsDefaultCredentialScript(credScript, credInterpreter))
        {
            rdf.DynamicCredentialScriptFile = WriteFile(credScript, credInterpreter, dir,
                baseName + ".dyncred-script", rdf.FileName, filesToCleanup);
        }
    }

    static string? WriteFile(string? script, string? interpreter, string dir, string baseName, string? sourceName,
        SortedSet<string> filesToDelete)
    {
        Debug.Assert(Path.IsPathRooted(dir));
        Debug.Assert(!string.IsNullOrWhiteSpace(sourceName));
        Debug.Assert(!baseName.Contains(Path.DirectorySeparatorChar));

        if (string.IsNullOrWhiteSpace(script))
            return null;

        if (!KnownInterpreters.TryGetValue(interpreter ?? "", out var config))
            throw new Exception($"Unknown file extension for interpreter: '{interpreter}'");

        if (config.CommentPrefix is {} prefix)
        {
            string autoGeneratedComment = $"""
                {prefix} ----------------------
                {prefix} <auto-generated>
                {prefix}    WARNING: this file was generated by an automated tool; manual edits will be lost when it is re-generated.
                {prefix}
                {prefix}    The source code below was extracted from `./{sourceName}`
                {prefix}
                {prefix}    Do not edit this file; instead update the scripts embedded in `./{sourceName}`
                {prefix} </auto-generated>
                {prefix} ----------------------


                """.ReplaceLineEndings("\n");

            script = autoGeneratedComment + script;
        }

        string filePath = Path.Join(dir, $"{baseName}{GeneratedSuffix}{config.Extension}");
        File.WriteAllText(filePath, script);
        filesToDelete.Remove(filePath);
        return Path.GetFileName(filePath);
    }

    static bool IsDefaultCredentialScript(string? script, string? interpreter)
    {
        if (string.IsNullOrWhiteSpace(script))
            return true;

        if (!OrdinalIgnoreCase.Equals(interpreter, "json"))
            return false;

        JsonNode? rootNode;
        try
        {
            rootNode = JsonNode.Parse(script);
        }
        catch
        {
            return false;
        }

        if (rootNode is not JsonObject root) return false;
        if (root.Count is not 2) return false;

        if (!root.TryGetPropertyValue("Username", out var usernameNode)
            || usernameNode is not JsonValue username
            || username.GetValueKind() is not JsonValueKind.String
            || username.GetValue<string>() is not "user")
            return false;

        if (!root.TryGetPropertyValue("Password", out var passwordNode)
            || passwordNode is not JsonValue password
            || password.GetValueKind() is not JsonValueKind.String
            || password.GetValue<string>() is not "pass")
            return false;

        return true;
    }
}

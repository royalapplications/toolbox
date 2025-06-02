using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Serialization;
using static System.StringComparer;

static class JsonIndex
{
    internal static void Generate(List<JsonIndexEntry> scripts, string dir)
    {
        Debug.Assert(Path.IsPathRooted(dir));

        scripts.Sort(static (a, b) => OrdinalIgnoreCase.Compare(a.Name, b.Name));
        var index = new JsonIndexData { Scripts = scripts };

        using var stream = File.Create(Path.Join(dir, "index.json"));
        JsonSerializer.Serialize(stream, index, index.GetType(), JsonWriteOptions);
    }

    static readonly JsonSerializerOptions JsonWriteOptions = new()
    {
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping,
        NewLine = "\n",
        WriteIndented = true,
        IndentCharacter = ' ',
        IndentSize = 4,
    };
}

sealed class JsonIndexData
{
    public required List<JsonIndexEntry> Scripts { get; init; }
}

sealed class JsonIndexEntry
{
    public required string Name { get; init; }
    // ReSharper disable once InconsistentNaming
    public required string ContentURL { get; init; }
    public required List<string> Categories { get; init; }
    public required string? Description { get; init; }
    public required string Notes { get; init; }
    public required string ScriptInterpreter { get; init; }
    public required string DynamicCredentialScriptInterpreter { get; init; }
}

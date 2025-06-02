using System;
using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;

static class RdfJson
{
    internal static DynamicFolderExport Load(string filePath)
    {
        Debug.Assert(Path.IsPathRooted(filePath));
        Debug.Assert(Path.GetExtension(filePath) is ".rdfe");

        using var stream = File.OpenRead(filePath);
        return JsonSerializer.Deserialize<DynamicFolderExport>(stream, JsonReadOptions)
            ?? throw new Exception("JSON data missing or invalid");
    }

    static readonly JsonSerializerOptions JsonReadOptions = new()
    {
        IncludeFields = false,
        MaxDepth = 8,
        AllowTrailingCommas = true,
        ReadCommentHandling = JsonCommentHandling.Skip,
        UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow,
    };
}

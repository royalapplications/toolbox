using System.Collections.Generic;
using System.Runtime.Serialization;

[DataContract]
public sealed class DynamicFolderExport
{
    [DataMember] public string? Name { get; set; }
    [DataMember] public List<DynamicFolderExportObject> Objects { get; set; } = new();

    // for internal use
    internal string? FileName { get; set; }
    internal string? ScriptFile { get; set; }
    internal string? DynamicCredentialScriptFile { get; set; }
}

[DataContract]
public sealed class DynamicFolderExportObject
{
    [DataMember] public string? Type { get; set; }
    [DataMember] public string? Name { get; set; }
    [DataMember] public string? Description { get; set; }
    [DataMember] public string? Notes { get; set; }
    [DataMember] public List<CustomProperty> CustomProperties { get; set; } = new();
    [DataMember] public string? Script { get; set; }
    [DataMember] public string? ScriptInterpreter { get; set; }
    [DataMember] public string? DynamicCredentialScriptInterpreter { get; set; }
    [DataMember] public string? DynamicCredentialScript { get; set; }
}

[DataContract]
public sealed class CustomProperty
{
    [DataMember] public string? Name { get; set; }
    [DataMember] public string? Type { get; set; }
    [DataMember] public string? Value { get; set; }
}

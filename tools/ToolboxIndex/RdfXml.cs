using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Xml;
using System.Xml.Serialization;

static class RdfXml
{
    internal static DynamicFolderExport Load(string filePath)
    {
        Debug.Assert(Path.IsPathRooted(filePath));
        Debug.Assert(Path.GetExtension(filePath) is ".rdfx");

        using var stream = File.OpenRead(filePath);
        return Serializer.Deserialize(stream) as DynamicFolderExport
            ?? throw new Exception("XML data missing or invalid");
    }

    internal static void Save(DynamicFolderExport data, string filePath)
    {
        Debug.Assert(Path.IsPathRooted(filePath));
        Debug.Assert(Path.GetExtension(filePath) is ".rdfx");

        using var stream = File.Create(filePath);
        using var xml = XmlWriter.Create(stream, XmlOptions);

        xml.WriteStartElement(nameof(DynamicFolderExport));
        WriteStringValue(xml, nameof(data.Name), data.Name);

        xml.WriteStartElement(nameof(data.Objects));
        foreach (var obj in data.Objects)
        {
            xml.WriteStartElement(nameof(DynamicFolderExportObject));
            xml.WriteStringValue(nameof(obj.Type), obj.Type);
            xml.WriteStringValue(nameof(obj.Name), obj.Name);
            xml.WriteStringValue(nameof(obj.Description), obj.Description);
            xml.WriteStringValue(nameof(obj.Notes), obj.Notes);

            xml.WriteStartElement(nameof(obj.CustomProperties));
            foreach (var prop in obj.CustomProperties)
            {
                xml.WriteStartElement(nameof(CustomProperty));
                xml.WriteStringValue(nameof(prop.Name), prop.Name);
                xml.WriteStringValue(nameof(prop.Type), prop.Type);
                xml.WriteStringValue(nameof(prop.Value), prop.Value);
                xml.WriteEndElement(/* CustomProperty */);
            }
            xml.WriteEndElement(/* CustomProperties */);

            xml.WriteStringValue(nameof(obj.ScriptInterpreter), obj.ScriptInterpreter);
            xml.WriteStringValue(nameof(obj.Script), obj.Script);

            xml.WriteStringValue(nameof(obj.DynamicCredentialScriptInterpreter), obj.DynamicCredentialScriptInterpreter);
            xml.WriteStringValue(nameof(obj.DynamicCredentialScript), obj.DynamicCredentialScript);

            xml.WriteEndElement(/* DynamicFolderExportObject */);
        }

        xml.WriteEndElement(/* Objects */);
        xml.WriteEndElement(/* DynamicFolderExport) */);

        xml.Flush();
        stream.Flush();
    }

    static void WriteStringValue(this XmlWriter writer, string elementName, string? value)
    {
        if (string.IsNullOrEmpty(value) || !value.Contains('\n'))
            writer.WriteElementString(elementName, value);
        else
        {
            writer.WriteStartElement(elementName);
            writer.WriteCData(value);
            writer.WriteEndElement();
        }
    }

    static readonly XmlSerializer Serializer = new(typeof(DynamicFolderExport),
    [
        typeof(DynamicFolderExportObject),
        typeof(CustomProperty),
    ]);

    static readonly XmlWriterSettings XmlOptions = new()
    {
        Encoding = new UTF8Encoding(encoderShouldEmitUTF8Identifier: false),
        Indent = true,
        IndentChars = "    ",
        CloseOutput = true,
        ConformanceLevel = ConformanceLevel.Fragment,
        NewLineHandling = NewLineHandling.None,
        OmitXmlDeclaration = true,
        WriteEndDocumentOnClose = true,
    };
}

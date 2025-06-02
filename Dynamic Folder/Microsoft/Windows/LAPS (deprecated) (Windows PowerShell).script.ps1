$ErrorActionPreference = "Stop"

[string] $JSON = "{ `"Objects`" : [ `n"

$JSON += "{`n"
$JSON += " `"Type`" : `"DynamicCredential`",`n"
$JSON += " `"Name`" : `"Administrator`",`n"
$JSON += " `"ID`" : `"LAPS`"`n"
$JSON += "},`n"

foreach ($comp in (Get-ADComputer -SearchBase $CustomProperty.SearchBase$ -filter *))
{
    $JSON += "{`n"
    $JSON += " `"Type`" : `"RemoteDesktopConnection`",`n"
    $JSON += " `"Name`" : `"$($comp.Name)`",`n"
    $JSON += " `"ComputerName`" : `"$($comp.DNSHostName)`",`n"
	$JSON += " `"Path`" : `"Connections`",`n"
	$JSON += " `"CredentialID`" : `"LAPS`"`n"
    $JSON += "},`n"
}

$JSON = $JSON.Substring(0, $JSON.Length - 2)
$JSON += "`n]`n}`n"

Write-Host $JSON
$ErrorActionPreference = "Stop"

[string] $JSON = "{ `"Objects`" : [ `n"

#foreach ($comp in (Get-ADComputer -SearchBase "$CustomProperty.SearchBase$" -filter *))
foreach ($comp in (Get-ADComputer -SearchBase "$CustomProperty.SearchBase$" -Properties Description -filter '$CustomProperty.Filter$')|sort)
{
    $JSON += "{`n"
    $JSON += " `"Type`" : `"RemoteDesktopConnection`",`n"
    $JSON += " `"Name`" : `"$($comp.Name)`",`n"
    $JSON += " `"ComputerName`" : `"$($comp.DNSHostName)`",`n"
    $JSON += " `"Description`" : `"$($comp.Description)`",`n"
#	$JSON += " `"Path`" : `"Connections`",`n"
	$JSON += " `"CredentialID`" : `"LAPS`"`n"
    $JSON += "},`n"
}

$JSON += "{`n"
$JSON += " `"Type`" : `"DynamicCredential`",`n"
$JSON += " `"Name`" : `"LAPSAdmin`",`n"
$JSON += " `"ID`" : `"LAPS`"`n"
$JSON += "},`n"


$JSON = $JSON.Substring(0, $JSON.Length - 2)
$JSON += "`n]`n}`n"
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host $JSON
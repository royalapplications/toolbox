# ---------------------------------------------------------------------------------------------------------------------
# Note that the whole output of the script will be parsed as rJSON and should be UTF8 encoded
# The following lines ensure that informational cmdlet output, warnings or errors are not written to the output stream 
# ---------------------------------------------------------------------------------------------------------------------
$global:ErrorActionPreference = "Stop"
$global:WarningPreference = "SilentlyContinue"
$global:InformationPreference = "SilentlyContinue"
$global:VerbosePreference = "SilentlyContinue"
$global:DebugPreference = "SilentlyContinue"
$global:ProgressPreference = "SilentlyContinue"
$global:OutputEncoding = New-Object Text.Utf8Encoding -ArgumentList (,$false) # BOM-less
[Console]::OutputEncoding = $global:OutputEncoding
# ---------------------------------------------------------------------------------------------------------------------

$computername = "$Target.Name$"
#$computername = "wvie01002"
$LAPS = Get-LapsADPassword -AsPlainText $computername
$Pass = $LAPS.Password
$Username = $computername + "\\" + $LAPS.Account
#$Username = (Get-LapsADPassword -AsPlainText $computername).Account



$JSON = ""
$JSON += "{`n"
$JSON += "  `"Username`" : `"$Username`",`n"
$JSON += "  `"Password`" : `"$($Pass)`"`n"
$JSON += "}`n"
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host $JSON
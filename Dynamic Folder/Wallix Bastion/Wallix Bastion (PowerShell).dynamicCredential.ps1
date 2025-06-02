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

<#
	Credentials script for connection to Wallix Bastion throw SSH or RDP
#>

# Variables replaced by Royal TS (using single quotes to avoid interpretation of the $ character)
$WallixUsername = '$Target.CustomField1$:$EffectiveUsername$'
$WallixPassword = '$EffectivePassword$'

# Return credentials
$Object = @{
	Username = "${WallixUsername}"
	Password = "${WallixPassword}"
}
$Object | ConvertTo-Json -Depth 100 | Write-Host

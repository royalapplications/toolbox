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
	Folder script for import Wallix Bastion connections
#>

# Variables replaced by Royal TS (using single quotes to avoid interpretation of the $ character)
$WallixUsername = '$EffectiveUsername$'
$WallixPassword = '$EffectivePassword$'
$WallixHostname = '$CustomProperty.Hostname$'.Trim()
$WallixUseHTPPS = '$CustomProperty.UseHTTPS$'
$WallixFingerprint = '$CustomProperty.WallixFingerprint$'.Trim()

# Constants
$ROYALTS_ID_CREDENTIALS = "DynamicCred01"

$Protocol = "http"
if ($WallixUseHTPPS) {
	$Protocol = "https"
}

# Call Wallix Bastion API with basic authentication
$EncodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${WallixUsername}:${WallixPassword}"))
$Headers = @{
	Authorization = "Basic ${EncodedCreds}"
}
$Response = Invoke-RestMethod -Uri "${Protocol}://${WallixHostname}/api/sessionrights?limit=500&fields=service_protocol,account,domain,device,service,authorization,device_description" -Method "GET" -Headers $Headers
$ListObjects = @()

foreach ($Item in $Response) {
	$WallixFullTargetName = "$($Item.account)@$($Item.domain)@$($Item.device):$($Item.service):$($Item.authorization)"
	$RoyalTSObjectType = $null
	$RoyalTSIconName = ""
	if ($Item.service_protocol.Equals("SSH")) {
		$RoyalTSObjectType = "TerminalConnection"
		$RoyalTSIconName = "Flat/Hardware/Platform OS Linux"
	}
	elseif ($Item.service_protocol.Equals("RDP")) {
		$RoyalTSObjectType = "RemoteDesktopConnection"
		$RoyalTSIconName = "Flat/Hardware/Platform OS Windows"
	}
	if ($null -ne $RoyalTSObjectType) {
		# Create serveur connection
		$Object = @{
			Type = $RoyalTSObjectType
			Name = $Item.device
			ComputerName = $WallixHostname
			Description = $Item.device_description
			IconName = $RoyalTSIconName
			Path = "Connections"
			# Dynamic credentials
			CredentialID = $ROYALTS_ID_CREDENTIALS
			# Used for the dynamic credential Script
			CustomField1 = $WallixFullTargetName
		}
		# Add fingerprint
		if ($Item.service_protocol.Equals("SSH") -and $WallixFingerprint.Length -gt 0) {
			$Object["Properties"] = @{
				Fingerprint = $WallixFingerprint
			}
		}
		$ListObjects += $Object
	}
}

# Creating dynamic credentials
$ListObjects += @{
	Type = "DynamicCredential"
	Name = "Dynamic credentials"
	Description = "Dynamically generated identifiers on login"
	ID = $ROYALTS_ID_CREDENTIALS
	Path = "Credentials"
}

# Create final object
$Result = @{
	Objects = ($ListObjects | Sort-Object -Property Path, Name)
}
$Result | ConvertTo-Json -Depth 100 | Write-Host

$ErrorActionPreference = "Stop"

function Get-DynamicCredential-Result ($passwordObject) {
	$username = $passwordObject.UserName
	$password = $passwordObject.Password

	$result = New-Object pscustomobject -Property @{
		"Username" = $username;
		"Password" = $password;
	}
	
	return $result
}

function Get-Password($url, $apiKey, $passwordID, $preventAuditing, $skipCertificateCheck) {
	$api = "$url/api"
	
    $headers = @{
        "APIKey" = $apiKey
	}

	$passwordsBasePath = "/passwords/"

	$preventAuditingParam = "PreventAuditing=false"

	if ($preventAuditing) {
		$preventAuditingParam = "PreventAuditing=true"
	}
	
	$urlPassword = $api + $passwordsBasePath + $passwordID + "?" + $preventAuditingParam
	
	$webRequestParams = @{}

	if ($skipCertificateCheck) {
		$webRequestParams["-SkipCertificateCheck"] = $true
	}

	$passwordObjectJSON = Invoke-WebRequest -Uri $urlPassword -Headers $headers @webRequestParams
	$passwordObject = (ConvertFrom-Json $passwordObjectJSON.Content)

	$credentialResult = Get-DynamicCredential-Result -passwordObject $passwordObject

	$credentialResultJSON = (ConvertTo-Json -InputObject $credentialResult -Depth 100)

    $credentialResultJSON
}

$baseURL = "$CustomProperty.ServerURL$"
$apiKey = "$EffectivePassword$"
$passwordID = "$DynamicCredential.EffectiveID$"
$skipCertificateCheck = "$CustomProperty.SkipCertificateCheck$" -like "yes"

Get-Password -url $baseURL -apiKey $apiKey -passwordID $passwordID -preventAuditing $false -skipCertificateCheck $skipCertificateCheck
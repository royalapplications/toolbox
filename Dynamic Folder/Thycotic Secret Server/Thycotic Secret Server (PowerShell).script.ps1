$ErrorActionPreference = "Stop"
$ProgressPreference="SilentlyContinue"

function Is-MacOS() {
    [String]$os = $PSVersionTable.OS

    return $os.StartsWith("darwin", [System.StringComparison]::CurrentCultureIgnoreCase)
}

function Run-Native([String] $command, [Array] $commandArgs) {
    $env:commandlineargumentstring=($commandArgs | %{'"'+ ($_ -replace '(\\*)"','$1$1\"' -replace '(\\*)$','$1$1') + '"'}) -join ' ';
    return & $command --% %commandlineargumentstring%
}

function Show-Prompt-Mac([String] $prompt, [String] $defaultValue) {
    $command = "/usr/bin/osascript"
    $script = "set resp to text returned of (display dialog ""$prompt"" default answer ""$defaultValue"" buttons {""Cancel"", ""OK""} default button ""OK"")"
    $commandArgs = @( "-e", $script )

    $ret = Run-Native -command $command -commandArgs @( "-e", $script )

    return $ret
}

function Show-Prompt-Windows([String] $prompt, [String] $defaultValue) {
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
    $ret = [Microsoft.VisualBasic.Interaction]::InputBox($prompt, "", $defaultValue)

    return $ret
}

function Show-Prompt([String] $prompt, [String] $defaultValue) {
    if (Is-MacOS) {
        return Show-Prompt-Mac -prompt $prompt -defaultValue $defaultValue
    } else {
        return Show-Prompt-Windows -prompt $prompt -defaultValue $defaultValue
    }
}

function Convert-Notes-To-HTML ($notes) {
    $notes -Replace "\r\n", "<br />" -Replace "\r", "<br />" -Replace "\n", "<br />"
}

function Create-Credential ($apiURL, $secret, $folderDict) {
    $credentialID = $secret.id
    $credentialName = $secret.name

    $folderPath = ""
    
    if ($secret.folderId -and $folderDict.ContainsKey($secret.folderId)) {
        $folderPath = $folderDict[$secret.folderId]
    }
    
    $credential = New-Object pscustomobject -Property @{
        "Type" = "DynamicCredential";
        "ID" = $credentialID;
        "Name" = $credentialName;
        "Path" = $folderPath;
    }

    return $credential
}

function Get-Entries($url, $username, $password, $requiresMFA) {
    $api = "$url/api/v1"
    $tokenRoute = "$url/oauth2/token";

    $tokenParams = @{
        grant_type = "password";
        username = $username;
        password = $password;
    }

    $headers = $null

    If ($requiresMFA) {
        $headers = @{
            "OTP" = Show-Prompt -prompt "Enter your OTP for MFA:"
        }
    }

    $tokenJSON = Invoke-WebRequest -SkipCertificateCheck -Uri $tokenRoute -Method POST -Body $tokenParams -Headers $headers
    $token = (ConvertFrom-Json $tokenJSON.Content).access_token

    $headers = @{
        "Authorization" = "Bearer $token"
    }

    $foldersRequestBody = @{
        "paging.take" = 1000;
    }

    $foldersJSON = Invoke-WebRequest -SkipCertificateCheck -Uri "$api/folders" -Headers $headers -Body $foldersRequestBody
    $folders = (ConvertFrom-Json $foldersJSON.Content)

    $folderDict = @{}

    ForEach ($folder in $folders.records) {
        $folderDict.Add($folder.id, $folder.folderPath)
    }

    $secretsRequestBody = @{
        "paging.take" = 1000;
    }

    $secretsJSON = Invoke-WebRequest -SkipCertificateCheck -Uri "$api/secrets" -Headers $headers -Body $secretsRequestBody
    $secrets = (ConvertFrom-Json $secretsJSON.Content)

    $storeObjects = @()

    ForEach ($secret in $secrets.records) {
        $credential = Create-Credential -apiURL $api -secret $secret -folderDict $folderDict
        
        $storeObjects += $credential
    }

    $store = New-Object pscustomobject -Property @{
        "Objects" = $storeObjects;
    }

    $storeJSON = (ConvertTo-Json -InputObject $store -Depth 100)
    
    $storeJSON
}

Get-Entries -url "$CustomProperty.ServerURL$" -username "$EffectiveUsername$" -password "$EffectivePassword$" -requiresMFA $false
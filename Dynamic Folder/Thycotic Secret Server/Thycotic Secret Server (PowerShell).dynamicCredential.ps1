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

$SLUGS_USERNAME =   ( "username", "licensed-to" );
$SLUGS_DOMAIN =     ( "domain" );
$SLUGS_PASSWORD =   ( "password", "pin-code", "combination", "license-key", "pin" );
$SLUGS_PASSPHRASE = ( "private-key-passphrase", "passphrase" );

function Create-Credential ($restricted) {
    $restrictedItems = $restricted.items

    $credentialUsername = ""
    $credentialPassword = ""
    $credentialPassphrase = ""
    
    ForEach ($restrictedItem in $restrictedItems) {
        $restrictedItemValue = $restrictedItem.itemValue

        if (!$restrictedItemValue) {
            continue
        }

        $slug = $restrictedItem.slug
        
        if ($SLUGS_USERNAME.Contains($slug)) {
            $credentialUsername = $restrictedItemValue
        } elseif ($SLUGS_DOMAIN.Contains($slug)) {
            $credentialDomain = $restrictedItemValue
        } elseif ($SLUGS_PASSWORD.Contains($slug)) {
            $credentialPassword = $restrictedItemValue
        } elseif ($SLUGS_PASSPHRASE.Contains($slug)) {
            $credentialPassphrase = $restrictedItemValue
        }
    }

    if ($credentialDomain -and $credentialUsername) {
        $credentialUsername = "$credentialDomain\$credentialUsername"
    }
    
    $credential = New-Object pscustomobject -Property @{
        "Username" = $credentialUsername;
        "Password" = $credentialPassword;
        "KeyFilePassphrase" = $credentialPassphrase;
    }

    return $credential
}

function Get-Credential($url, $username, $password, $requiresMFA, $secretID) {
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

    $restrictedJSON = Invoke-WebRequest -SkipCertificateCheck -Uri "$api/secrets/$secretID/restricted" -Headers $headers -Method POST
    $restricted = (ConvertFrom-Json $restrictedJSON.Content)

    $credential = Create-Credential -restricted $restricted

    $credentialJSON = (ConvertTo-Json -InputObject $credential -Depth 100)
    
    $credentialJSON
}

Get-Credential -url "$CustomProperty.ServerURL$" -username "$EffectiveUsername$" -password "$EffectivePassword$" -secretID "$DynamicCredential.EffectiveID$" -requiresMFA $false
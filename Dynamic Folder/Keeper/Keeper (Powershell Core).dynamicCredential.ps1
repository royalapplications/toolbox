$ErrorActionPreference = 'Stop'

if ('$CustomProperty.PowerShellVaultName$' -eq '') {
    throw 'Vault Name needed'
}
if ('$CustomProperty.PowerShellVaultPassword$' -eq '') {
    throw 'Vault password needed'
}

$Secure = ConvertTo-SecureString -String '$CustomProperty.PowerShellVaultPassword$' -AsPlainText -Force
Unlock-SecretStore -Password $Secure

$results = Get-Secret '$DynamicCredential.EffectiveID$' -AsPlainText
$results | Select-Object @{Name='username';Expression={$_.login}},password | ConvertTo-Json -Depth 100 | Write-Output
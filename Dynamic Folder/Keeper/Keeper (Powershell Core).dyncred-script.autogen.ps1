# ----------------------
# <auto-generated>
#    WARNING: this file was generated by an automated tool; manual edits will be lost when it is re-generated.
#
#    The source code below was extracted from `./Keeper (Powershell Core).rdfe`
#
#    Do not edit this file; instead update the scripts embedded in `./Keeper (Powershell Core).rdfe`
# </auto-generated>
# ----------------------

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
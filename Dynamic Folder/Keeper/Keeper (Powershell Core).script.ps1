$ErrorActionPreference = 'Stop'

if ('$CustomProperty.PowerShellVaultName$' -eq '') {
    throw 'Vault Name needed'
}
if ('$CustomProperty.PowerShellVaultPassword$' -eq '') {
    throw 'Vault password needed'
}

$Secure = ConvertTo-SecureString -String '$CustomProperty.PowerShellVaultPassword$' -AsPlainText -Force
Unlock-SecretStore -Password $Secure

$results = Get-SecretInfo -Vault '$CustomProperty.PowerShellVaultName$'
$credentials = @()
foreach ($item in $results) {
    $ID,$name = $item.Name -split ' ',2
    $credentials += [pscustomobject]@{
        Type     = 'DynamicCredential'
        Name     = $name
        Username = ''
        Password = ''
        ID       = $ID
    }
}

$final = [pscustomobject]@{
    Objects = ($credentials | Sort-Object Name)
}
$final | ConvertTo-Json -Depth 100 | Write-Output
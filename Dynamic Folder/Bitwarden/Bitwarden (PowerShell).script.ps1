# Env config
$global:OutputEncoding = New-Object Text.Utf8Encoding -ArgumentList (,$false) # BOM-less
[Console]::OutputEncoding = $global:OutputEncoding
$PSStyle.OutputRendering = 'PlainText'

# Bitwarden access config
$Bitwarden = ( New-Object PSObject |
  Add-Member -PassThru NoteProperty exec_path '$CustomProperty.BitWardenCLIExecutable$' |
  Add-Member -PassThru NoteProperty serverUrl '$CustomProperty.BitWardenServerURL$' |
  Add-Member -PassThru NoteProperty clientId '$CustomProperty.APIClientID$' |
  Add-Member -PassThru NoteProperty clientSecret '$CustomProperty.APIClientSecret$' |
  Add-Member -PassThru NoteProperty password '$CustomProperty.AccountPassword$' |
  Add-Member -PassThru NoteProperty session '' )

# Check bw.exe path validity
if (!(Test-Path -Path "$($Bitwarden.exec_path)" -PathType Leaf)) {
  Write-Error -Message "Bitwarden CLI utility not found at specified path. Please check CLI utility path in Custom Properties." -ErrorAction Stop
}

# Structures
$final = @{ Objects = @(@{ Type = "Folder"; ID = "personal"; Name = "Personal Vault"; IconName = "Flat/Objects/User Record"; Objects = @(); }); }

# Functions
function Get-VaultItems {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$false)]
    [string]$folderId = "",
    [Parameter(Mandatory=$false)]
    [string]$collectionId = ""
  )

  if ($folderId -eq "" -and $collectionId -eq "") { Write-Error -Message "Folder ID or Collection ID needed, none provided." -ErrorAction Stop }

  if ($folderId -ne "" -and $collectionId -eq "") {
    $tmpItems = (Invoke-Command -ScriptBloc { & "$($Bitwarden.exec_path)" list items --folderid $folderId --session "$($Bitwarden.session)"}) | ConvertFrom-Json
  } elseif ($folderId -eq "" -and $collectionId -ne "") {
    $tmpItems = (Invoke-Command -ScriptBloc { & "$($Bitwarden.exec_path)" list items --collectionid $collectionId --session "$($Bitwarden.session)"}) | ConvertFrom-Json
  } else {
    Write-Error -Message "Either FolderId or CollectionId are needed, not both." -ErrorAction Stop
  }
  $items = [array]@()
  foreach ($item in $tmpItems) {
    # Skip shared items with an organization to prevent duplicates
    if ($folderid -ne "" -and $null -ne $item.organizationid) { continue }

    # Parse item of type Login/Secure Note only
    switch ($item.type) {
      "1" { # Login
        $row = "" | Select-Object Type,ID,Name,Notes,Favorite,Username,Password,URL,CustomProperties
        $row.Type = "Credential"
        $row.ID = $item.id
        $row.Name = $item.name
        if ($null -ne $item.notes) {
          $row.Notes = $item.notes.Replace("`r`n", "<br />").Replace("`r", "<br />").Replace("`n", "<br />")
        }
        if ($item.favorite -eq "true") { $row.Favorite = $true } else { $row.Favorite = $false }
        $row.Username = $item.login.username
        $row.Password = $item.login.password
        if ($item.login.uris.Count -gt 0) {
          $row.URL = $item.login.uris[0].uri
        }
        $row.CustomProperties = [array]@()
        if ($item.fields.count -gt 0) {
          $itemFields = [array]@()
          $fieldIndex = 0
          foreach ($field in $item.fields) {
            $frow = "" | Select-Object Type,Name,Value
            switch ($field.type) {
              "0" { $frow.Type = "Text" }
              "1" { $frow.Type = "Protected" }
              "2" { $frow.Type = "YesNo" }
            }
			if ($null -eq $frow.Type) {
			  continue
			}
            if ($null -eq $field.name) {
              $frow.Name = "UnnamedField$($fieldIndex)"
              $fieldIndex++
            } else {
              $frow.Name = $field.name
            }
			
			$frow.Value = $field.value

            $itemFields += $frow
          }
          
          $row.CustomProperties = $itemFields
        }
        $items += $row
      }
      "2" { # Secure Note
        $row = "" | Select-Object Type,ID,Name,Notes,TemplateID,CustomProperties
        $row.Type = "Information"
        $row.ID = $item.id
        $row.Name = $item.name
        if ($null -ne $item.notes) {
          $row.Notes = $item.notes.Replace("`r`n", "<br />").Replace("`r", "<br />").Replace("`n", "<br />")
        }
        $row.TemplateID = "Custom"
        $row.CustomProperties = @()
        $itemFields = [array]@()
        if ($item.fields.count -gt 0) {
          $fieldIndex = 0
          foreach ($field in $item.fields) {
            $frow = "" | Select-Object Type,Name,Value
            switch ($field.type) {
              "0" { $frow.Type = "Text" }
              "1" { $frow.Type = "Protected" }
              "2" { $frow.Type = "YesNo" }
            }
			if ($null -eq $frow.Type) {
			  continue
			}
            if ($null -eq $field.name) {
              $frow.Name = "UnnamedField$($fieldIndex)"
              $fieldIndex++
            } else {
              $frow.Name = $field.name
            }
			
			$frow.Value = $field.value

            $itemFields += $frow
          }
        } else {
          $itemFields += @{ Type = "Header"; Name = "See notes for details"; Value = ""; }
        }
        $row.CustomProperties = $itemFields
        $items += $row
      }
    }
  }

  return $items
}

# Get Vault status
$status = (Invoke-Command -ScriptBloc { & "$($Bitwarden.exec_path)" status }) | ConvertFrom-Json

if ($null -ne $status) {
  switch ($status.status) {
    "unauthenticated" {
      if ($null -eq $status.serverUrl -or $status.serverUrl -ne $Bitwarden.serverUrl) {
        # Vault not configured, configure server
        [void](Invoke-Command -ScriptBlock { & "$($Bitwarden.exec_path)" config server "$($Bitwarden.serverUrl)" })
      }

      # Prepare Vault login using API key
      $env:BW_CLIENTID = $Bitwarden.clientId
      $env:BW_CLIENTSECRET = $Bitwarden.clientSecret
      $env:BW_PASSWORD = $Bitwarden.password
      [void](Invoke-Command -ScriptBlock { & "$($Bitwarden.exec_path)" login --apikey})

      # Unlock Vault using password
      $Bitwarden.session = Invoke-Command -ScriptBlock { & "$($Bitwarden.exec_path)" unlock --passwordenv BW_PASSWORD --raw }

      if ($null -eq $Bitwarden.session -or $Bitwarden.session -eq "") {
        Write-Error -Message "Unable to authenticate and unlock your vault. Please check your API credentials and master password in Custom Properties." -ErrorAction Stop
      }

      # Clear env variables
      Remove-Item -Path Env:\BW_*
    }
    "locked" {
      # Vault is locked, unlock it with password
      $env:BW_PASSWORD = $Bitwarden.password
      $Bitwarden.session = Invoke-Command -ScriptBlock { & "$($Bitwarden.exec_path)" unlock --passwordenv BW_PASSWORD --raw }

      if ($null -eq $Bitwarden.session -or $Bitwarden.session -eq "") {
        Write-Error -Message "Unable to unlock your vault. Please check your master password in Custom Properties." -ErrorAction Stop
      }

      # Clear env variables
      Remove-Item -Path Env:\BW_*
    }
  }
} else {
  Write-Error -Message "Unable to get Vault status, check Server URL in Custom Properties or your connectivity." -ErrorAction Stop
}

if ($null -ne $Bitwarden.session) {
  # Sync Vault to latest version from server
  [void](Invoke-Command -ScriptBlock { & "$($Bitwarden.exec_path)" sync --session "$($Bitwarden.session)"})

  # Get and parse Personal Vault folders
  $tmpFolders = (Invoke-Command -ScriptBloc { & "$($Bitwarden.exec_path)" list folders --session "$($Bitwarden.session)"}) | ConvertFrom-Json

  foreach ($folder in $tmpFolders) {
    if ($null -ne $folder.id) {
      $tF = @{ Type = "Folder"; ID = $folder.id; Name = $folder.name; Objects = [array]@(Get-VaultItems -folderId $folder.id); }
      if ($tF.Objects.Count -ne 0) { $final.Objects[0].Objects += $tF; $tF = $null }
    } else {
      # Add default folder
      $tF = @{ Type = "Folder"; ID = "nofolder"; Name = "No folder"; Objects = [array]@(Get-VaultItems -folderId null); }
      if ($tF.Objects.Count -ne 0) { $final.Objects[0].Objects += $tF; $tF = $null }
    }
  }

  # Get and parse Organisations and Collections
  $organizations = (Invoke-Command -ScriptBloc { & "$($Bitwarden.exec_path)" list organizations --session "$($Bitwarden.session)"}) | ConvertFrom-Json

  foreach ($org in $organizations) {
    # Get collections for the organization
    $collections = (Invoke-Command -ScriptBloc { & "$($Bitwarden.exec_path)" list collections --organizationid $org.id --session "$($Bitwarden.session)"}) | ConvertFrom-Json
    $tOrgCollections = [array]@()
    foreach ($coll in $collections) {
      $tF = @{ Type = "Folder"; ID = $coll.id; Name = $coll.name; IconName = "Flat/Software/Tree"; Objects = [array]@(Get-VaultItems -collectionId $coll.id); }
      if ($tF.Objects.Count -ne 0) { $tOrgCollections += $tF; $tF = $null }
    }
    if ($tOrgCollections.Count -gt 0) {
      # Create organization folder
      $final.Objects += @{ Type = "Folder"; ID = $org.id; Name = $org.name; IconName = "Flat/Money/Bank"; Objects = $tOrgCollections; }
    }
  }
}

# Adapt JSON output for PowerShell version
if ($PSVersionTable.PSVersion -ge '6.2') {
  #ConvertTo-Json -InputObject $final -Depth 100 -EscapeHandling EscapeHtml |Out-file ".\bitwarden_output.json" -Force
  ConvertTo-Json -InputObject $final -Depth 100 -EscapeHandling EscapeHtml
} else {
  #ConvertTo-Json -InputObject $final -Depth 100 |Out-file ".\bitwarden_output.json" -Force
  ConvertTo-Json -InputObject $final -Depth 100
}

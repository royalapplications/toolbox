<#
Description:
This PowerShell script generates a random password for Active Directory (AD) users stored in a Royal TS document and sets the password using the Set-ADAccountPassword cmdlet. The script uses the royaldocument.powershell and ActiveDirectory modules to access the Royal TS document and AD, respectively.

The script performs the following tasks:
- Imports the ActiveDirectory and royaldocument.powershell modules
- Defines the IP address of a domain controller
- Defines a function to generate a random 20-character string
- Sets the configuration for the Documents store using the New-RoyalStore cmdlet from the royaldocument.powershell module
- Specifies the base directory where GUID-named subdirectories are located
- Gets a list of subdirectories with GUID names
- Loops through each subdirectory and opens the default.rtsz file in the current subdirectory using the Open-RoyalDocument cmdlet
- Gets the credentials from the Royal TS document using the Get-RoyalObject cmdlet
- Finds the Domain Administrator credential object and stores the login details
- Loops through each credential object and checks if the CustomField3 property is equal to "msad"
- If the CustomField3 property is equal to "msad", generates a random 20-character string and sets the AD user password using the Set-ADAccountPassword cmdlet from the ActiveDirectory module
- Stores the new password in the credential object and saves the changes to the Royal TS document using the Out-RoyalDocument cmdlet
- Closes the document using the Close-RoyalDocument cmdlet
#>

Import-Module ActiveDirectory
Import-Module royaldocument.powershell
# Define DC
$ComputerName = "192.168.13.2"

# Function to generate a random 20-character string
function Generate-RandomString {
    $characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/*-+.'
    $randomString = ""
    for ($i = 0; $i -lt 20; $i++) {
        $randomString += $characters[(Get-Random -Minimum 0 -Maximum $characters.Length)]
    }
    return $randomString
}


# Set the Configuration for the Documents store
$Password = ConvertTo-SecureString "PASSWORD" -AsPlainText -Force
$Username = "automated_task"
$RoyalStore = New-RoyalStore -UserName $Username

# Specify the base directory where GUID-named subdirectories are located
$baseDirectory = "C:\RoyalServer\DocumentStore\Documents"

# Get a list of subdirectories with GUID names
$subdirectories = Get-ChildItem -Path $baseDirectory -Directory


    # Construct the path to the default.rtsz file in the current subdirectory
    $documentPath = "C:\RoyalServer\DocumentStore\Documents\ID\default.rtsz"


        # Open the Royal Document
        $RoyalDocument = Open-RoyalDocument -FileName $documentPath -Store $RoyalStore -Password $Password

        # Get the credentials from the Royal TS document
        $credentials = Get-RoyalObject -Store $RoyalStore -Type RoyalCredential

        # Find the Domain Administrator credential object and store the login details
        $domainAdminCredential = $credentials | Where-Object { $_.Name -eq "Domain Administrator" }
        $domainAdminCredential = New-Object System.Management.Automation.PSCredential ($domainAdminCredential.UserName, ($domainAdminCredential.Password | ConvertTo-SecureString -AsPlainText -Force))

        # Loop through each credential object
        foreach ($credential in $credentials) {
            if ($credential.CustomField3 -eq "msad") {
                Write-Host "found"
                # Generate a random 20-character string
                $newPassword = Generate-RandomString
                $secureNewPassword = ConvertTo-SecureString -String $newPassword -AsPlainText -Force

                # Set the AD user password
                $sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck
                try {
                    Invoke-Command -ComputerName $ComputerName -Credential $domainAdminCredential -UseSSL -SessionOption $sessionOption -ScriptBlock {
                        param($adUserName, $secureNewPassword)
                        Set-ADAccountPassword -Identity $adUserName -NewPassword $secureNewPassword -Reset
                    } -ArgumentList $credential.Name, $secureNewPassword

                    # Store the new password in the credential object
                    $credential.Password = $newPassword
                    Write-Host "Password updated successfully for AD user $($credential.Name)."
                } catch {
                    Write-Host "Failed to update password for AD user $($credential.Name): $_"
                    Write-Host "Failed to update password for AD user $($credential.Name): $_"
            }
        }
        }
        
        # Save the changes to the Royal TS document
        Out-RoyalDocument -Document $RoyalDocument -FileName $documentPath

        # Close the document
        Close-RoyalDocument -Document $RoyalDocument
    

# Check-DocumentPasswordsHIBP

**THIS IS CURRENTLY IN BETA AND WORK IN PROGRESS! Feedback strongly appreciated.**

This script allows you to check all your document passwords against the famous and great service called "Have I been pwned?". More information about this service can be found at the official site at: [HaveIBeenPwned.com](https://haveibeenpwned.com)

For your own security not your full passwords will be submitted to HIBP. The first 5 letters from each passwords are going to be hashed using SHA-1 and submitted to the HIBP-API. Afterwards the returned dataset will be checked if your SHA-1 hashed password is within the returned list. This way your full password will never leave your local machine.

Good luck that there are no matches! If so - taking action is recommended!

## SUPPORT

Please see details [here](https://github.com/royalapplications/scripts/tree/master/README.md#support).

## REQUIREMENTS

- Operating System: any Windows OS with PowerShell installed (PowerShell Core not supported)
- PowerShell modules:
  - RoyalDocument (for interacting with Royal Documents, [Installation guide](https://content.royalapplications.com/Help/RoyalTS/V4/index.html?scripting_gettingstarted.htm))
- Internet access to the [HIBP](https://haveibeenpwned.com) API

## USAGE

- Download the script. [See below.](#download)
- Execute the script with the corrected [parameters](#parameters). See [examples](#examples) below.
- Wait until your document passwords are checked, which will look like [this](#example-output).

### DOWNLOAD

Some recent PowerShell versions have a cool `wget` alias to the cmdlet `Invoke-WebRequest` allowing you to easily download files. This way you can use it to quickly download the script like here:

```powershell
C:\PS> wget -OutFile Check-DocumentPasswordsHIBP.ps1 https://raw.githubusercontent.com/royalapplications/scripts/master/powershell/Check-DocumentPasswordsHIBP/Check-DocumentPasswordsHIBP.ps1
```

### PARAMETERS

| Parameter                 | Type          | Description | Required | Default |
| ------------------------- | ------------- | ----------- | -------- | ------- |
| **File**               | `String`              | The path to your document file. | True | *None* |
| **EncryptionPassword** | `String/SecureString` | Provide the encryption password for the specified document, if required. | False, True if Lockdown enabled. | *None* |
| **LockdownPassword**   | `String/SecureString` | Provide the lockdown password for the specified document, if required. | False | *None* |

### EXAMPLES

Here are some usage examples:

```powershell
C:\PS> .\Check-DocumentPasswordsHIBP.ps1 -File "servers.rtsz"
[...processing...]

C:\PS> .\Check-DocumentPasswordsHIBP.ps1 -File "servers.rtsz" -EncryptionPassword "EncryptionP@ssw0rd"
[...processing...]

C:\PS> .\Check-DocumentPasswordsHIBP.ps1 -File "servers.rtsz" -EncryptionPassword "EncryptionP@ssw0rd" -LockdownPassword "LockdownP@ssw0rd"
[...processing...]
```

## EXAMPLE OUTPUT

![Script Output Screenshot](https://raw.githubusercontent.com/royalapplications/scripts/master/powershell/Check-DocumentPasswordsHIBP/screenshots/Check-DocumentPasswordsHIBP-1.jpg)

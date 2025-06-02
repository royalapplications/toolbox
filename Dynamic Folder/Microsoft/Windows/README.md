# Table of Contents

- [CurrentAccount (Windows PowerShell).rdfx](#toc-CurrentAccount-Windows-PowerShell-rdfx)
- [LAPS (deprecated) (Windows PowerShell).rdfx](#toc-LAPS-deprecated-Windows-PowerShell-rdfx)
- [LAPS April 2023 (Windows PowerShell).rdfx](#toc-LAPS-April-2023-Windows-PowerShell-rdfx)

# <a name="toc-CurrentAccount-Windows-PowerShell-rdfx"></a> CurrentAccount (Windows PowerShell).rdfx

This returns dynamic objects reflecting data from the current user account.

Source files:

- [`CurrentAccount (Windows PowerShell).rdfx`](./CurrentAccount%20%28Windows%20PowerShell%29.rdfx)
- [`CurrentAccount (Windows PowerShell).script.ps1`](./CurrentAccount%20%28Windows%20PowerShell%29.script.ps1)

Version: 1.0

Requirements

- Working PowerShell installation
- PowerShell Script Interpreter correctly configured in Royal TS/X

# <a name="toc-LAPS-deprecated-Windows-PowerShell-rdfx"></a> LAPS (deprecated) (Windows PowerShell).rdfx

Source files:

- [`LAPS (deprecated) (Windows PowerShell).rdfx`](./LAPS%20%28deprecated%29%20%28Windows%20PowerShell%29.rdfx)
- [`LAPS (deprecated) (Windows PowerShell).script.ps1`](./LAPS%20%28deprecated%29%20%28Windows%20PowerShell%29.script.ps1)
- [`LAPS (deprecated) (Windows PowerShell).dynamicCredential.ps1`](./LAPS%20%28deprecated%29%20%28Windows%20PowerShell%29.dynamicCredential.ps1)

Local Administrator Password Solution (LAPS)

More information on LAPS can be found here:

[https://www.microsoft.com/en-us/download/details.aspx?id=46899](https://www.microsoft.com/en-us/download/details.aspx?id=46899)

Requirements:

The dynamic credential script executes the Get-AdmPwdPassword cmdlet of the AdmPwd.PS module:

[https://www.powershellgallery.com/packages/AdmPwd.PS](https://www.powershellgallery.com/packages/AdmPwd.PS)

Make sure the module is installed/available on your system!

Configuration:

The dynamic folder script creates a list of available machine from the Active Directory. Configure the SearchBase path in the Custom Properties.

# <a name="toc-LAPS-April-2023-Windows-PowerShell-rdfx"></a> LAPS April 2023 (Windows PowerShell).rdfx

Source files:

- [`LAPS April 2023 (Windows PowerShell).rdfx`](./LAPS%20April%202023%20%28Windows%20PowerShell%29.rdfx)
- [`LAPS April 2023 (Windows PowerShell).script.ps1`](./LAPS%20April%202023%20%28Windows%20PowerShell%29.script.ps1)
- [`LAPS April 2023 (Windows PowerShell).dynamicCredential.ps1`](./LAPS%20April%202023%20%28Windows%20PowerShell%29.dynamicCredential.ps1)

Local Administrator Password Solution (LAPS)

More information on LAPS can be found here:

[https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-overview](https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-overview) 

Requirements:

The dynamic credential script executes the Get-LapsADPassword cmdlet of the new LAPS (April 2023 Update) module:
Make sure the new LAPS is installed on the System

Configuration:

The dynamic folder script creates a list of available machine from the Active Directory. Configure the SearchBase and Filter path in the Custom Properties.


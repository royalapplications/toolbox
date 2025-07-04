> [!NOTE]
>
> This file was generated by an automated tool; manual edits will be lost when it is re-generated.
>
> The content below was generated from the `Description` and `Notes` entries of `.rdfe` and `.rdfx` files in this directory.
> In particular, the `Notes` conversion from HTML to Markdown may not be fully accurate.
>
> Do not edit this file; instead, update the `Description` and `Notes` entries in the original files.

# <a name="toc-Keeper-Powershell-Core-rdfe"></a> Keeper (Powershell Core).rdfe

Get dynamic credentials from Keeper Secrets Manager

Source files:

- [`Keeper (Powershell Core).rdfe`](./Keeper%20%28Powershell%20Core%29.rdfe)
- [`Keeper (Powershell Core).script.autogen.ps1`](./Keeper%20%28Powershell%20Core%29.script.autogen.ps1)
- [`Keeper (Powershell Core).dyncred-script.autogen.ps1`](./Keeper%20%28Powershell%20Core%29.dyncred-script.autogen.ps1)

# 
		Keeper (Powershell) Dynamic Folder

	
# 
		Version: 1.0.0
Author: [https://github.com/WillEllis](https://github.com/WillEllis)

	
## 
		How to use

	
Ensure you set the RoyalTS script interpreter as Powershell Core. E.g. "C:\Program Files\PowerShell\7\pwsh.exe"

### 
		Create a Keeper application

	
You will need to create an application in Keeper and get a one time access token. Follow the quick start guide here: [Keeper Create an Application](https://docs.keeper.io/secrets-manager/secrets-manager/quick-start-guide#create-a-secrets-manager-application)

### 
		Create a Keeper application

	
Setup Keeper Secrets Manager for Powershell (in Powershell core) following this guide [Keeper Powershell Plugin - Installation](https://docs.keeper.io/secrets-manager/secrets-manager/integrations/powershell-plugin#installation)

### 
		Connect Dynamic Folder to Powershell Keeper Vault

	
### 
		If you've done the above then you'll have a Powershell Vault in place for Keeper. Simply set the name of the vault and the password (if set) within the custom properties of this Dynamic folder.


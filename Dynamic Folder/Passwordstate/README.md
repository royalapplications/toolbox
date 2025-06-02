# Table of Contents

- [Passwordstate (PowerShell).rdfx](#toc-Passwordstate-PowerShell-rdfx)
- [Passwordstate - Based on management module (PowerShell).rdfx](#toc-Passwordstate-Based-on-management-module-PowerShell-rdfx)

# <a name="toc-Passwordstate-PowerShell-rdfx"></a> Passwordstate (PowerShell).rdfx

This Dynamic Folder sample for Passwordstate supports Dynamic Credentials or regular credentials.

Source files:

- [`Passwordstate (PowerShell).rdfx`](./Passwordstate%20%28PowerShell%29.rdfx)
- [`Passwordstate (PowerShell).script.ps1`](./Passwordstate%20%28PowerShell%29.script.ps1)
- [`Passwordstate (PowerShell).dynamicCredential.ps1`](./Passwordstate%20%28PowerShell%29.dynamicCredential.ps1)

## **Dynamic Folder sample for Passwordstate**

**Version**: 1.0.0

**Author**: Royal Apps

This Dynamic Folder sample for Passwordstate supports Dynamic Credentials and regular credentials.

### **Requirements**

- This script has only been tested with PowerShell Core 6.x. If you're using an older version, adjustments might be necessary.

### **Setup**

- Enter your "**Server URL**" in the "Custom Properties" section. (ie. *https://passwordstatehost:9119*)
- If you're using an **untrusted SSL** certificate on your server, set **Skip Certificate Check** to "Yes".
- Assign a credential to the dynamic folder which contains the following information:
    - **Username**: Either leave the username blank if you're using a system-wide API key and want to retrieve all credentials or enter the ID of the password list you want to retrieve.
    - **Password**: Enter your Passwordstate API key.
- By default, the dynamic folder script generates **dynamic credentials**. If you want to use **regular credentials** instead, edit the last line of the dynamic folder script and change -createDynamicCredential $true to -createDynamicCredential $false.

# <a name="toc-Passwordstate-Based-on-management-module-PowerShell-rdfx"></a> Passwordstate - Based on management module (PowerShell).rdfx

Get dynamic credentials from passwordstate server

Source files:

- [`Passwordstate - Based on management module (PowerShell).rdfx`](./Passwordstate%20-%20Based%20on%20management%20module%20%28PowerShell%29.rdfx)
- [`Passwordstate - Based on management module (PowerShell).script.ps1`](./Passwordstate%20-%20Based%20on%20management%20module%20%28PowerShell%29.script.ps1)
- [`Passwordstate - Based on management module (PowerShell).dynamicCredential.ps1`](./Passwordstate%20-%20Based%20on%20management%20module%20%28PowerShell%29.dynamicCredential.ps1)

# 
		Password State Dynamic Folder

	
## 
		How to use

	
Install passwordstate-management powershell module [PSGalleryLink](https://www.powershellgallery.com/packages/passwordstate-management/)

### 
		Setup your passwordstate management environment

	
First you will need to setup the environment for PasswordState. This prevents you having to enter the api key all the time as it's stored in an encrypted format. Or you can use Windows authentication using the currently logged on user.

#### 
		For API Key

	
    Set-PasswordStateEnvironment  -baseuri "https://passwordstatserver.co.uk" -apikey "dsiwjdi9e0377dw84w45dsw5sw"

#### 
		For Windows Auth With Pass Through Authentication

	
    Set-PasswordStateEnvironment  -baseuri "https://passwordstateserver.co.uk" -WindowsAuthOnly

#### 
		For Windows Auth With Custom Credentials

	
    Set-PasswordStateEnvironment  -baseuri "https://passwordstateserver.co.uk" -customcredentials $(Get-Credential)

This will save a file called passwordstate.json under the users profile folder.

For more infor about the module consult powershell help or the [github repository](https://github.com/dnewsholme/PasswordState-Management)


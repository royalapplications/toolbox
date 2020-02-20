# Password State Dynamic Folder

## How to use

Install passwordstate-management powershell module [PSGalleryLink](https://www.powershellgallery.com/packages/passwordstate-management/)

### Setup your passwordstate management environment

First you will need to setup the environment for PasswordState. This prevents you having to enter the api key all the time as it's stored in an encrypted format. Or you can use Windows authentication using the currently logged on user.

#### For API Key

```powershell
    Set-PasswordStateEnvironment  -baseuri "https://passwordstatserver.co.uk" -apikey "dsiwjdi9e0377dw84w45dsw5sw"
```

#### For Windows Auth With Pass Through Authentication

```powershell
    Set-PasswordStateEnvironment  -baseuri "https://passwordstateserver.co.uk" -WindowsAuthOnly
```

#### For Windows Auth With Custom Credentials

```powershell
    Set-PasswordStateEnvironment  -baseuri "https://passwordstateserver.co.uk" -customcredentials $(Get-Credential)
```

This will save a file called `passwordstate.json` under the users profile folder.

For more infor about the module consult powershell help or the [github repository](https://github.com/dnewsholme/PasswordState-Management)
# Table of Contents

- [Bitwarden (PowerShell).rdfx](#toc-Bitwarden-PowerShell-rdfx)
- [Bitwarden (Python).rdfx](#toc-Bitwarden-Python-rdfx)

# <a name="toc-Bitwarden-PowerShell-rdfx"></a> Bitwarden (PowerShell).rdfx

This Dynamic Folder sample allows you to import credentials from Bitwarden using Powershell.

Source files:

- [`Bitwarden (PowerShell).rdfx`](./Bitwarden%20%28PowerShell%29.rdfx)
- [`Bitwarden (PowerShell).script.ps1`](./Bitwarden%20%28PowerShell%29.script.ps1)

##  Bitwarden Dynamic Folder sample with Powershell

Version: 1.0.1

Author: Nicolas Grimler

This Dynamic Folder sample allows you to import credentials from Bitwarden. The Bitwarden CLI client is required and the full executable path where it is installed must be configured in the "Custom Properties" section. Also, your Bitwarden login details must be provided in the "Credentials" section.

It use the Bitwarden User API to login and the master password to unlock the vault. Please read [https://bitwarden.com/help/personal-api-key/](https://bitwarden.com/help/personal-api-key/) to know how to get your personal API Key.

If you don't want to use an API Key, please ensure that you are already logged in using the bw.exe CLI tool as the script will not handle the TOTP 2FA handshake.

At the moment, only credentials and secure notes are collected. The folder structure is as presented in Bitwarden (Folder, Folder/Subfolder, ...). Support for full directory structure may be implemented in future version.

### Requirements

- [Bitwarden command-line tool (CLI)](https://help.bitwarden.com/article/cli)
- PowerShell, either:
    - Legacy PowerShell (version 5.1 as standard Windows installation)
    - PowerShell Core (6.x and later) available in [Microsoft Store](https://apps.microsoft.com/store/detail/powershell/9MZ1SNWT0N5D?hl=en-us&amp;gl=us) or [GitHub](https://github.com/PowerShell/PowerShell)

### Setup

- Specify the full, absolute path to the Bitwarden CLI tool in the "Custom Properties" section.
- Specify your server URL if on-premise instance, or offical Bitwarden URL
- Specify your ClientID & ClientSecret for the API
- Specify you master password to unlock the vault

Important note:

In the configuration of the interpreter used to run the script, check the box "Do not load the PowerShell profile" as it may otherwise add unwanted messages invalidating the JSON output and causing errors.

# <a name="toc-Bitwarden-Python-rdfx"></a> Bitwarden (Python).rdfx

This Dynamic Folder sample allows you to import credentials from Bitwarden.

Source files:

- [`Bitwarden (Python).rdfx`](./Bitwarden%20%28Python%29.rdfx)
- [`Bitwarden (Python).script.py`](./Bitwarden%20%28Python%29.script.py)
- [`Bitwarden (Python).dynamicCredential.json`](./Bitwarden%20%28Python%29.dynamicCredential.json)

## **Bitwarden Dynamic Folder sample**

**Version**: 1.0.7

**Author**: Royal Apps

This Dynamic Folder sample allows you to import credentials from Bitwarden. The Bitwarden CLI client is required and the path where it is installed must be configured in the "Custom Properties" section. Also, your Bitwarden login details must be provided in the "Credentials" section. Optionally, you can configure API Key based authentication by providing your Client ID and Client Secret in the "Custom Properties" section. Note that, your Bitwarden password must still be provided even when using API Key based authentication.

At the moment, all items are placed in the root folder. There is no support for custom folders at the moment. Bitwarden two-step login is supported, but only tested with the "Authenticator App" and "Email" providers, the 2FA (TOTP) code can be automatically generated.

Note that if your account is hosted on any other domain than vault.bitwarden.com, you must configure that domain using the Bitwarden command-line tool (CLI) before using this dynamic folder script. (see [https://bitwarden.com/help/cli/#config](https://bitwarden.com/help/cli/#config)).

### **Requirements**

- [Bitwarden command-line tool (CLI)](https://help.bitwarden.com/article/cli)
- Python Module: \_\_future\_\_
- Python Module: sys
- Python Module: functools
- Python Module: json
- Python Module: subprocess
- Python Module: os
- Python Module: tkinter
- Python Module: [pyotp](https://github.com/pyauth/pyotp) (only needed when using the auto TOTP 2FA code generation)

### **Setup**

- Specify the full, absolute path to the Bitwarden CLI tool in the "Custom Properties" section.
- Specify credentials for accessing your Bitwarden vault in the "Credentials" section.
- When using the auto TOTP 2FA code generation, specify the TOTP key in the "Custom Properties" section.
- Optionally, specify your Client ID and Client Secret for API Key based authentication in the "Custom Properties" section.
- Optionally, specify a custom server url in the "Custom Properties" section.


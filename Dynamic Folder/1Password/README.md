# <a name="toc-1Password-v8-Python-rdfx"></a> 1Password v8 (Python).rdfx

This Dynamic Folder sample allows you to import dynamic credentials from 1Password v8+

Source files:

- [`1Password v8 (Python).rdfx`](./1Password%20v8%20%28Python%29.rdfx)
- [`1Password v8 (Python).script.py`](./1Password%20v8%20%28Python%29.script.py)
- [`1Password v8 (Python).dynamicCredential.py`](./1Password%20v8%20%28Python%29.dynamicCredential.py)

## 1Password v8+ Dynamic Folder sample

This Dynamic Folder sample allows you to import credentials from 1Password. It requires both the 1Password app (version 8 or above) and the 1Password CLI tool (version 2.19 or above). The [1Password CLI tool](https://developer.1password.com/docs/cli/get-started/) must be installed, and the path where it is installed must be configured in the "Custom Properties" section. You also need to turn on the 1Password CLI/desktop integration in the 1Password app (Settings -> Developer -> enable "Integrate with 1Password CLI").

Items are imported as Dynamic Credentials. This means that the username and password fields will remain empty after reloading the dynamic folder and only be requested when a connection is established that uses one of the credentials of this dynamic folder.

By default, the last signed in account in 1Password is used (this is defined by the 1Password CLI tool). If you require fetching from a specific account, you can specify this in the "Account" custom property.

By default, items of all vaults are imported. If you only want to retrieve items of a specific vault (or a list of specific vaults, comma-separated), you can configure the "Vaults" custom property.

### Requirements

- Royal TS v7 or higher / Royal TSX v6 or higher
- [1Password CLI tool](https://developer.1password.com/docs/cli/get-started) (Version 2+)
- Python 3 (Python 2 is not supported)
- Python Module: sys
- Python Module: json
- Python Module: subprocess

### Setup

- Specify the full, absolute path to the 1Password command-line tool in the "OP Path" variable in the "Custom Properties" section.
- Optionally specify the 1Password account ID (found via `op account list`) in the "Account" variable in the "Custom Properties" section.
- Optionally specify the vault ID or ID's (via `op vault list`) you want to filter on in the "Vaults" variable in the "Custom Properties" section.


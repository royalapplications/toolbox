# <a name="toc-Keychain-Python-rdfx"></a> Keychain (Python).rdfx

This script dynamically retrieves usernames and passwords from the macOS Keychain.

Source files:

- [`Keychain (Python).rdfx`](./Keychain%20%28Python%29.rdfx)
- [`Keychain (Python).script.py`](./Keychain%20%28Python%29.script.py)
- [`Keychain (Python).dynamicCredential.py`](./Keychain%20%28Python%29.dynamicCredential.py)

## Keychain (Python)

Version: 1.0

Author: Royal Apps

### Description

This script dynamically retrieves usernames and passwords from the macOS Keychain. You provide the names of the keychain items as a semicolon separated list in the custom properties section. When reloading the dynamic folder, a dynamic credential object will be created for each provided keychain item. When opening a connection that uses one of the dynamic credentials, the username and password will be requested from the keychain.

### Configuration

- Add the names of keychain items you want to retrieve as a semicolon separated list to the "**Keychain Item Names**" custom property.

### Prerequisits

- **Python 3** must be installed and configured.


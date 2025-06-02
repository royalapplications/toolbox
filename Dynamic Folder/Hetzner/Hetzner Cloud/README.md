# <a name="toc-Hetzner-Cloud-Python-rdfe"></a> Hetzner Cloud (Python).rdfe

This Dynamic Folder script will list all your servers for the given API Key of the Hetzner Cloud.

Source files:

- [`Hetzner Cloud (Python).rdfe`](./Hetzner%20Cloud%20%28Python%29.rdfe)
- [`Hetzner Cloud (Python).script.py`](./Hetzner%20Cloud%20%28Python%29.script.py)

## 
		Dynamic Folder support for Hetzner Cloud

	
Version: 1.0
Author: Max Schmitt

This Dynamic Folder script will list all your servers for the given API Key of the Hetzner Cloud.

Prerequisites

- [Hetzner Cloud Command Line Interface](https://github.com/hetznercloud/cli) (CLI) needs to be installed, so it's binary is available in the PATH environment variable.

	
### 
		Setup

- Enter your API Key, which you've got from the Hetzner Cloud Console and place it under the Custom Properties section of the Dynamic Folder. There's a property"API Key", which is used to store the API Key of your project.

	
### 
		Notes

- Per default the auto created servers are setup to inherit their credentials from the Dynamic Folder. So if you set their the credentials all underlying servers will use them.


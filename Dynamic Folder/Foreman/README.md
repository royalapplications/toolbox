# <a name="toc-Foreman-PHP-rdfx"></a> Foreman (PHP).rdfx

This Dynamic Folder script will list all your servers from your Foreman Instance

Source files:

- [`Foreman (PHP).rdfx`](./Foreman%20%28PHP%29.rdfx)
- [`Foreman (PHP).script.php`](./Foreman%20%28PHP%29.script.php)

## 
		Dynamic Folder support for Foreman

	
Version: 1.0
Author: Daniel Rieper

This Dynamic Folder script will list all your servers from your Foreman Instance.

Prerequisites

- A [Foreman Instance](https://www.theforeman.org/) with API v2.

	
Setup

- Enter your Foreman URL under the Custom Properties section of the Dynamic Folder. There's a property "Foreman URL", which is used to store the URL of your Instance.
- Enter your Foreman Credentials under the Credentials section of the Dynamic Folder.

	

- If you Prefer a Connection over IP instead of DNS set the property "Connect by IP" to Yes.

	
Notes

- All Servers with Windows are configured as RDP all other as SSH.


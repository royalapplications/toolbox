import json
import ldap

LDAP_SERVER = r"$CustomProperty.DCLDAPServer$" # i.e. 'mydomain.local' / '192.168.0.1'
LDAP_USERNAME = r"$EffectiveUsername$"
LDAP_PASSWORD = r"$EffectivePassword$"
BASE_DN = r"$CustomProperty.SearchBase$" # i.e. 'DC=mydomain,DC=local'

LDAP_CONNECTION_STRING = "ldap://" + LDAP_SERVER
SEARCH_FILTER = "objectCategory=computer"

ATTRIBUTE_CN = "cn"
ATTRIBUTE_DNS_HOSTNAME = "dNSHostName"
ATTRIBUTE_NETWORK_ADDRESS = "networkAddress"
ATTRIBUTE_OPERATING_SYSTEM = "operatingSystem"
ATTRIBUTES_TO_QUERY = [ ATTRIBUTE_CN, ATTRIBUTE_DNS_HOSTNAME, ATTRIBUTE_NETWORK_ADDRESS, ATTRIBUTE_OPERATING_SYSTEM ]

OS_WINDOWS = "windows"
OS_MACOS = "macos"
OS_LINUX = "linux"

OS_OBJECT_TYPE_MAPPING = {
	OS_WINDOWS: "RemoteDesktopConnection",
	OS_MACOS: "VNCConnection",
	OS_LINUX: "TerminalConnection"
}

def create_connection(object_type, terminal_connection_type, name, host, path):
	connection = {
		"Type": object_type,
		"Name": name,
		"ComputerName": host
	}

	if path is not None and path != "":
		connection["Path"] = path

	return connection


def get_object_type(os):
	object_type = OS_OBJECT_TYPE_MAPPING[os]

	return object_type


def get_os(operating_system):
	os = OS_WINDOWS

	if operating_system is not None:
		operating_system_lower = operating_system.lower()

		if operating_system_lower.startswith("windows"):
			os = OS_WINDOWS
		elif operating_system_lower.startswith("mac os"):
			os = OS_MACOS
		else:
			os = OS_LINUX

	return os


def get_entry_value(entry, attribute):
	val = None

	if attribute in entry:
		val_list = entry[attribute]
		
		if isinstance(val_list, list):
			if len(val_list) > 0:
				val_potential = val_list[0]
				
				if isinstance(val_potential, str):
					val = val_potential
				elif isinstance(val_potential, bytes):
					val = val_potential.decode()

	return val


def get_ldap_result(ldap_connection_string, ldap_username, ldap_password, base_dn):
	ad = ldap.initialize(ldap_connection_string)
	ad.set_option(ldap.OPT_REFERRALS, 0) # to search the object and all its descendants
	ad.simple_bind_s(ldap_username, ldap_password)

	result = ad.search_s(base_dn, ldap.SCOPE_SUBTREE, SEARCH_FILTER, ATTRIBUTES_TO_QUERY)

	return result


def get_path(dn, computer_cn):
	dn_arr = dn.split(",")
	
	path_arr = []

	for part in dn_arr:
		part_lower = part.lower()

		if part_lower.startswith("ou=") or part_lower.startswith("cn="):
			part_val_arr = part.split("=")

			if len(part_val_arr) > 1:
				part_val = part_val_arr[1]

				if computer_cn != part_val:
					path_arr.append(part_val)

	path_arr.reverse()

	path = "/".join(path_arr)

	return path


def ldap_entry_to_connection(dn, entry):
	computer_cn = get_entry_value(entry, ATTRIBUTE_CN)

	path = get_path(dn, computer_cn)

	dns_hostname = get_entry_value(entry, ATTRIBUTE_DNS_HOSTNAME)
	network_address = get_entry_value(entry, ATTRIBUTE_NETWORK_ADDRESS)
	
	os = get_os(get_entry_value(entry, ATTRIBUTE_OPERATING_SYSTEM))
	
	object_type = get_object_type(os)
	terminal_connection_type = "SSHConnection"

	computer_name = dns_hostname

	if dns_hostname is None or dns_hostname == "":
		computer_name = network_address

	connection = None

	if computer_name is not None and computer_name != "":
		connection = create_connection(object_type, terminal_connection_type, computer_cn, computer_name, path)

	return connection


def get_connections(ldap_connection_string, ldap_username, ldap_password, base_dn):
	result = get_ldap_result(ldap_connection_string, ldap_username, ldap_password, base_dn)

	connections = []

	if isinstance(result, list):
		for dn, entry in result:
			if isinstance(entry, dict):
				connection = ldap_entry_to_connection(dn, entry)

				if connection is None:
					continue

				connections.append(connection)

	return connections


connections = get_connections(LDAP_CONNECTION_STRING, LDAP_USERNAME, LDAP_PASSWORD, BASE_DN)

store = {
	"Objects": connections
}

jsonStr = json.dumps(store)

print(jsonStr)
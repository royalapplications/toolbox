import sys
import subprocess
import json
import re
import binascii

def print_to_stderr(text: str, should_exit: bool):
	print(text, file=sys.stderr)

	if should_exit:
		exit(1)

def hex_to_string(hex: str) -> str:
	unhexified_string = str(binascii.unhexlify(hex), 'utf-8')

	return unhexified_string

def run_subprocess(command: str):
	return subprocess.run(command, shell=True, check=True, capture_output=True)

def get_keychain_item(item_name: str, include_password: bool) -> tuple[str, str]:
	kc_output = None

	try:
		kc_command_generic = f"security find-generic-password -l '{item_name}'"

		if include_password:
			kc_command_generic += ' -g'

		kc_output = run_subprocess(kc_command_generic)
	except subprocess.CalledProcessError as e:
		try:
			kc_command_internet = f"security find-internet-password -l '{item_name}'"

			if include_password:
				kc_command_internet += ' -g'

			kc_output = run_subprocess(kc_command_internet)
		except subprocess.CalledProcessError as e:
			kc_error = e.stderr.decode().strip()

			wrapped_kc_error = f'An error occurred while retrieving an item named "{item_name}" from the keychain.\n\n{kc_error}'

			print_to_stderr(wrapped_kc_error, True)

	if kc_output is None:
		print_to_stderr("No output", True)
	
	kc_standard_output = kc_output.stdout.decode()
	kc_error_output = ''

	if kc_output.stderr is not None:
		kc_error_output = kc_output.stderr.decode()

	return (kc_standard_output, kc_error_output)

def get_keychain_detail(kc_details_output: str, key: str) -> str:
	kc_ascii_match = re.search(f'.*?\"{key}\".*?=\"(.*)\"', kc_details_output)

	if kc_ascii_match is not None:
		# Extract ASCII Value
		kc_value = kc_ascii_match.group(1)

		return kc_value
	
	kc_hex_match = re.search(f'.*?\"{key}\".*?=0x(.*?)\s', kc_details_output)

	if kc_hex_match is not None:
		# Extract Non-ASCII Value
		kc_value = hex_to_string(kc_hex_match.group(1))

		return kc_value
	
	return None

def get_keychain_comment(kc_details_output: str) -> str:
	kc_value = get_keychain_detail(kc_details_output, "icmt")

	if kc_value == "default":
		kc_value = None

	return kc_value

def get_keychain_protocol(kc_details_output: str) -> str:
	kc_value = get_keychain_detail(kc_details_output, "ptcl")

	return kc_value

def get_keychain_server(kc_details_output: str) -> str:
	kc_value = get_keychain_detail(kc_details_output, "srvr")

	return kc_value

def get_keychain_path(kc_details_output: str) -> str:
	kc_value = get_keychain_detail(kc_details_output, "path")

	return kc_value

def get_keychain_url(kc_details_output: str) -> str:
	kc_protocol = get_keychain_protocol(kc_details_output)
	kc_server = get_keychain_server(kc_details_output)
	kc_path = get_keychain_path(kc_details_output)

	kc_url = None

	if kc_protocol is not None:
		if kc_protocol == "htps":
			kc_url = "https://"
		elif kc_protocol == "http":
			kc_url = "http://"

	if kc_server is not None:
		if kc_url is None:
			kc_url = ""

		kc_url += kc_server

	if kc_url is None:
		return None

	if kc_path is not None:
		kc_url += kc_path

	return kc_url

def get_keychain_account(kc_details_output: str) -> str:
	kc_value = get_keychain_detail(kc_details_output, "acct")

	if kc_value == None:
		print_to_stderr("Username was not found in Keychain output.", True)
	
	return kc_value

def get_dynamic_credential(name: str, id: str, username: str, description: str, url: str) -> object:
	dynamic_credential = {
		"Type": "DynamicCredential",
		"ID": id,
		"Name": name
	}

	if username is not None:
		dynamic_credential["Username"] = username
	
	if description is not None:
		dynamic_credential["Description"] = description

	if url is not None:
		dynamic_credential["URL"] = url

	return dynamic_credential

def get_dynamic_credentials(names_string: str) -> list[object]:
	names = list(filter(None, names_string.split(';')))
	dynamic_credentials = [ ]

	for name in names:
		kc_output = get_keychain_item(name, False)

		if kc_output is None or kc_output[0] is None:
			print_to_stderr(f'The item "{name}" was not found in the Keychain.', True)

		username = get_keychain_account(kc_output[0])
		comment = get_keychain_comment(kc_output[0])

		if comment is not None:
			comment = comment.replace('\r\n', '\n').replace('\r', '\n').replace('\n', ' ')

		url = get_keychain_url(kc_output[0])
		
		dynamic_credential = get_dynamic_credential(name, name, username, comment, url)

		dynamic_credentials.append(dynamic_credential)
	
	return dynamic_credentials

def get_store(objects: list[object]) -> object:
	return {
		"Objects": objects
	}

kc_item_names=r'$CustomProperty.KeychainItemNames$'

dynamic_credentials = get_dynamic_credentials(kc_item_names)
store = get_store(dynamic_credentials)
print(json.dumps(store))
import sys
import struct
import json
import socket

import netifaces
from netifaces import *


ENABLE_LOGGING = False

SOCKET_TIMEOUT = $CustomProperty.Timeout$

PORT_MAPPINGS = {
	22: {
		"Type": "TerminalConnection",
		"NamePostfix": " - SSH"
	},
	80: {
		"Type": "WebConnection",
		"NamePostfix": " - HTTP"
	},
	443: {
		"Type": "WebConnection",
		"NamePostfix": " - HTTPS"
	},
	3389: {
		"Type": "RemoteDesktopConnection",
		"NamePostfix": " - RDP"
	},
	5900: {
		"Type": "VNCConnection",
		"NamePostfix": " - VNC"
	}
}


def get_prefix(subnet_mask):
    prefix = sum([bin(int(x)).count('1') for x in subnet_mask.split('.')])

    return prefix


def get_all_ips_in_subnet(ip, cidr):
    host_bits = 32 - cidr
    i = struct.unpack('>I', socket.inet_aton(ip))[0]  # note the endianness
    start = (i >> host_bits) << host_bits  # clear the host bits
    end = start | ((1 << host_bits) - 1)

    ips = []

    # excludes the first and last address in the subnet
    for i in range(start, end):
        ips.append(socket.inet_ntoa(struct.pack('>I', i)))

    return ips


def is_port_open(target, port):
	sock = socket.socket(AF_INET, socket.SOCK_STREAM)
	sock.settimeout(SOCKET_TIMEOUT)

	result = sock.connect_ex((target, port))

	sock.close()

	if (result == 0):
		return True

	return False


def create_connection(object_type, name_postfix, host, port):
	name = host

	if name_postfix:
		name += name_postfix

	connection = {
		"Type": object_type,
		"Name": name,
		"ComputerName": host,
		"Port": port,
		"Path": "/" + host
	}

	return connection


def parse_potential_string_bool(potential_bool):
	actual_bool = False
	
	if isinstance(potential_bool, bool):
		actual_bool = potential_bool
	elif isinstance(potential_bool, str):
		potential_bool = potential_bool.lower()
		if potential_bool == "true" or potential_bool == "yes":
			actual_bool = True

	return actual_bool


def get_connections(config):
	iface_name = netifaces.gateways()["default"][netifaces.AF_INET][1]

	addresses = [i['addr'] for i in ifaddresses(iface_name).setdefault(AF_INET, [{"addr": ""}] )]
	netmasks = [i['netmask'] for i in ifaddresses(iface_name).setdefault(AF_INET, [{"addr": ""}] )]

	ip = addresses[0]
	netmask = netmasks[0]
	cidr = get_prefix(netmask)

	ips = get_all_ips_in_subnet(ip, cidr)

	connections = [ ]

	for target_to_scan in ips:
		if ENABLE_LOGGING:
			print("Scanning " + target_to_scan + "...")

		for port_to_scan, props in PORT_MAPPINGS.items():
			if port_to_scan == 22 and not config["ssh"]:
				continue

			if port_to_scan == 3389 and not config["rdp"]:
				continue

			if port_to_scan == 5900 and not config["vnc"]:
				continue

			if port_to_scan == 80 and not config["http"]:
				continue

			if port_to_scan == 443 and not config["https"]:
				continue

			if is_port_open(target_to_scan, port_to_scan):
				object_type = props["Type"]
				name_postfix = props["NamePostfix"]

				connection = create_connection(object_type, name_postfix, target_to_scan, port_to_scan)

				if ENABLE_LOGGING:
					print("Found open port and created connection:")
					print(connection)

				connections.append(connection)

	store = {
		"Objects": connections
	}

	store_json = json.dumps(store)

	return store_json

config = {
	"ssh": parse_potential_string_bool("$CustomProperty.SSH$"),
	"rdp": parse_potential_string_bool("$CustomProperty.RDP$"),
	"vnc": parse_potential_string_bool("$CustomProperty.VNC$"),
	"http": parse_potential_string_bool("$CustomProperty.HTTP$"),
	"https": parse_potential_string_bool("$CustomProperty.HTTPS$")
}

print(get_connections(config))
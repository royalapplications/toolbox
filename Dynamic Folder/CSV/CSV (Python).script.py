import os
import csv
import json

def get_entries(csv_path):
    csvfile = open(os.path.expanduser(csv_path))
    reader = csv.DictReader(csvfile)

    connections = []

    for row in reader:
        name = row["Name"]
        computerName = row["ComputerName"]
        username = row["Username"]
        password = row["Password"]

        connection = {
            "Type": "TerminalConnection",
            "TerminalConnectionType": "SSH",
            "Name": name,
            "ComputerName": computerName,
            "Username": username,
            "Password": password
        }

        connections.append(connection)

    store = {
        "Objects": connections
    }

    store_json = json.dumps(store)

    return store_json

print(get_entries("$CustomProperty.CSVPath$"))
#!/usr/bin/env python3

import sys
import os
import json
import urllib.request as req

class Script:
	Name = ""
	ContentURL = ""
	Categories: list = [ ]
	Description = ""
	ScriptInterpreter = ""
	DynamicCredentialScriptInterpreter = ""
	Notes = ""

	def to_dict(self) -> dict:
		return self.__dict__

class ScriptIndex:
	Scripts: list = [ ]

	def to_dict(self) -> dict:
		scripts = [ ]

		for script in self.Scripts:
			scripts.append(script.to_dict())

		obj = {
			"Scripts": scripts
		}

		return obj
	
	def to_json(self) -> str:
		self_as_dict = self.to_dict()

		return json.dumps(self_as_dict, indent=4)

class Scraper:
	SCRIPT_FILE_EXTENSION = ".rdfe"
	CONTENT_URL_BASE = "https://raw.githubusercontent.com/royalapplications/toolbox/master/Dynamic%20Folder"

	working_dir = ""
	
	def __init__(self, working_dir) -> None:
		self.working_dir = working_dir

	def build_index(self) -> ScriptIndex:
		scripts: list = [ ]

		for file_name in os.listdir(self.working_dir):
			file_path = os.path.join(self.working_dir, file_name)

			if os.path.isdir(file_path):
				scripts_in_folder = self.get_scripts(file_path)

				for script in scripts_in_folder:
					scripts.append(script)

		scripts.sort(key=lambda s: s.Name)

		script_index = ScriptIndex()
		script_index.Scripts = scripts

		return script_index
	
	def get_scripts(self, path) -> list:
		scripts: list = [ ]

		if not os.path.isdir(path):
			return scripts
		
		for file_name in os.listdir(path):
			file_path = os.path.join(path, file_name)

			if os.path.isdir(file_path):
				for script in self.get_scripts(file_path):
					scripts.append(script)
			elif os.path.isfile(file_path):
				_, file_extension = os.path.splitext(file_path)

				if file_extension == self.SCRIPT_FILE_EXTENSION:
					name = file_name.removesuffix(file_extension)
					categories: list = []

					relative_file_path = file_path.removeprefix(self.working_dir)
					relative_path = relative_file_path.removesuffix(file_name)

					content_url_relative = req.pathname2url(relative_file_path)
					content_url = self.CONTENT_URL_BASE + content_url_relative

					categories = list(filter(None, relative_path.split(os.path.sep)))

					file = open(file_path)
					file_content: dict = json.load(file)
					file.close()

					dynamic_folder: dict = file_content.get("Objects", [dict])[0]

					script = Script()
					script.Name = name
					script.ContentURL = content_url
					script.Categories = categories
					script.Description = dynamic_folder.get("Description", "")
					script.Notes = dynamic_folder.get("Notes", "")
					script.ScriptInterpreter = dynamic_folder.get("ScriptInterpreter", "")
					script.DynamicCredentialScriptInterpreter = dynamic_folder.get("DynamicCredentialScriptInterpreter", "")

					scripts.append(script)

		return scripts

class Main:
	def exit_with_error(self, message):
		print(message, file=sys.stderr)
		sys.exit(1)

	def run(self):
		working_dir = os.getcwd()
		last_path_component = os.path.basename(os.path.normpath(working_dir))
		expected_last_path_component = "Dynamic Folder"
		index_file_name = "index.json"

		if last_path_component != expected_last_path_component:
			self.exit_with_error("Error: This script must be run from the \"" + expected_last_path_component + "\" directory.")

		index_file_path = os.path.join(working_dir, index_file_name)

		scraper = Scraper(working_dir)
		index = scraper.build_index()
		index_json = index.to_json()

		file = open(index_file_path, "w")
		file.write(index_json)
		file.close()

main = Main()
main.run()
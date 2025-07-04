# ----------------------
# <auto-generated>
#    WARNING: this file was generated by an automated tool; manual edits will be lost when it is re-generated.
#
#    The source code below was extracted from `./Pleasant Password (Python).rdfe`
#
#    Do not edit this file; instead update the scripts embedded in `./Pleasant Password (Python).rdfe`
# </auto-generated>
# ----------------------

from __future__ import print_function
import sys
from functools import partial
import json
import requests
import urllib3

try:
	# for Python2
	from Tkinter import * 
except ImportError:
	# for Python3
	from tkinter import *

class TakeInput(object):
	def __init__(self, request_message):
		self.root = Tk()

		title = ""

		if request_message:
			title = request_message
			
			if title.endswith(":"):
				title = title[:-1]

		self.root.title(title)

		# Do not allow the user to resize the window
		self.root.resizable(False, False)
		
		self.string = ""

		self.frame = Frame(self.root)

		self.acceptInput(request_message)
		self.frame.pack(padx=17, pady=17)

	def acceptInput(self, request_message):
		r = self.frame

		icon = Label(r, text="", image="::tk::icons::question")
		icon.grid(row=0, column=0, rowspan=2, sticky="w")

		label = Label(r, text=request_message)
		label.grid(row=0, column=1, padx=(9, 0), sticky="nw")
		
		self.e = Entry(r, text='Name')
		self.e.grid(row=1, column=1, padx=(13, 0), sticky="nw")
		self.e.configure(width=30)
		self.e.focus_set()

		b = Button(r, text='        OK        ', command=self.gettext)
		b.grid(row=2, column=1, sticky="ne", pady=(10, 0))
		
		self.root.bind('<Return>', self.gettext)

	def gettext(self, event=None):
		self.string = self.e.get()
		self.root.destroy()

	def getString(self):
		return self.string
	
	def configureWindowGeometry(self):
		# Get the window size
		window_width = self.root.winfo_width()
		window_height = self.root.winfo_height()

		# Get the screen size
		screen_width = self.root.winfo_screenwidth()
		screen_height = self.root.winfo_screenheight()

		# Get the window position from the top dynamically as well as position from left or right as follows
		position_top = int((screen_height / 2) - (window_height / 2))
		position_right = int((screen_width / 2) - (window_width / 2))

		# Shift up by a couple of pixels to account for the title bar
		position_top -= 30

		# This will center the window
		self.root.geometry(str(window_width) + "x" + str(window_height) + "+" + str(position_right) + "+" + str(position_top))

	def waitForInput(self):
		self.root.lift()

		self.root.attributes('-topmost', True)
		self.root.after_idle(self.root.attributes, '-topmost', False)

		# Ensure that layout is ready
		self.root.update_idletasks()

		self.configureWindowGeometry()

		self.root.mainloop()

def show_prompt(request_message):
	msg_box = TakeInput(request_message)

	# loop until the user makes a decision and the window is destroyed
	msg_box.waitForInput()

	return msg_box.getString()


def call_token_endpoint(url, body, otp_headers):
	printError = partial(print, file=sys.stderr) # python2 compatibility
	try:
		token_json = requests.post(url + "/OAuth2/Token", data=body, verify=False, headers=otp_headers)
		token_json.raise_for_status()
		return token_json
	except requests.exceptions.HTTPError as e:
		if "X-Pleasant-OTP" in token_json.headers and token_json.headers["X-Pleasant-OTP"] == "required":
			return token_json
		
		if token_json.status_code == 400:
			printError("HTTP Error 400: Bad Request - could be a redundant domain name, try to omit it. Details: ",e)
		else:
			printError("HTTP Error: ",e)
		sys.exit(1)
	except requests.exceptions.ConnectionError:
		printError("Connection failed.")
		sys.exit(1)
	except requests.exceptions.Timeout:
		printError("Connection timeout.")
		sys.exit(1)
	except requests.exceptions.RequestException as e:
		printError("An unknown connection error occurred. Details: ",e)
		sys.exit(1)

def get_api_string(version):
	api_string_list = {
		"4": "/api/v4/rest/credential/",
		"5": "/api/v5/rest/entries/"
	}
	api_string = api_string_list.get(version, "/api/v5/rest/entries")

	return api_string

def get_dynamic_credential(url, username, password, credential_id):
	printError = partial(print, file=sys.stderr) # python2 compatibility
	urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

	token_params = {
		"grant_type": "password",
		"username": username,
		"password": password
	}

	token_json = call_token_endpoint(url, token_params, None)

	if not token_json.ok:
		if "X-Pleasant-OTP" in token_json.headers and token_json.headers["X-Pleasant-OTP"] == "required":
			otp_provider = token_json.headers["X-Pleasant-OTP-Provider"]

			otp_token = show_prompt("Enter your OTP for MFA (" + otp_provider + "):")

			if not otp_token:
				printError("No token for MFA provided")
				return ""

			otp_headers = {
				"X-Pleasant-OTP-Provider": otp_provider,
				"X-Pleasant-OTP": otp_token
			}

			token_json = call_token_endpoint(url, token_params, otp_headers)
		else:
			printError("An unknown error occurred (could be redundant domain name, try to omit it).")
			return ""

	token = json.loads(token_json.content)["access_token"]

	headers = {
		"Accept": "application/json",
		"Authorization": token
	}

	api_string = get_api_string(r"$CustomProperty.APIVersion$")
	
	credential_password_json = requests.get(url + api_string + credential_id + "/password", headers=headers, verify=False)
	credential_password = json.loads(credential_password_json.content)

	credential = {
		"Password": credential_password
	}

	credential_json = json.dumps(credential)

	return credential_json

if r"$CustomProperty.OmitDomain$" == "Yes":
	print(get_dynamic_credential(r"$CustomProperty.ServerURL$", r"$EffectiveUsernameWithoutDomain$", r"$EffectivePassword$", r"$DynamicCredential.EffectiveID$"))
else:
	print(get_dynamic_credential(r"$CustomProperty.ServerURL$", r"$EffectiveUsername$", r"$EffectivePassword$", r"$DynamicCredential.EffectiveID$"))
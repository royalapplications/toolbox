# Dynamic Folder Samples

This folder contains Dynamic Folder sample scripts. These are distributed using a special file format (.rdfe) which makes it easy to import (and export) them in Royal TS/X.

Documentation for the rJSON format and Dynamic Folders in general is [available here](https://www.royalapps.com/go/rjson-documentation). This feature is available starting [Royal TS v5 (for Windows)](https://www.royalapps.com/ts/win) and [Royal TSX v4 (for macOS)](https://www.royalapps.com/ts/mac).

## Import

To import a Dynamic Folder, first download the `.rdfe` or `.rdfx` file (the latter requires Royal TS V7+ or Royal TSX V6+). To do so, navigate to the folder on Github where the desired Dynamic Folder export file (`.rdfe` or `.rdfx`) is located. Click the `.rdfe` or `.rdfx` file and on the next page, option/alt-click the "Raw" button. This will initiate the download of the file. Back in Royal TS/X, select a folder in the navigation panel and go to "Import - Dynamic Folder". Select the file you just downloaded. A new Dynamic Folder will be created as a child of the currently selected folder.

In addition to scripts, Dynamic Folder export files can also contain a description, custom properties and notes. Notes are often used to explain how the Dynamic Folder scripts work and what setup steps are required before initiating a reload for the first time. After importing a Dynamic Folder definition, please read the "Notes" section in the properties of the Dynamic Folder.

## Export

If you want to export one of your Dynamic Folders to share it with the world, control-click (right-click) it in the navigation panel and select "Export...". The export dialog allows you to specify what data you want to export (Description, Custom Properties, Notes). Custom Properties can also be anonymized, which, when enabled, replaces the values of your properties with "TODO".

When exporting Dynamic Folders, please double-check that your scripts don't contain any confidential data! Any such data should be stored in other fields (Custom Properties) and be referenced from scripts using replacement tokens (E.g. `$CustomProperty.Server$`)

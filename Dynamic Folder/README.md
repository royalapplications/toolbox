# Dynamic Folder Samples

This folder contains Dynamic Folder sample scripts. These are distributed using a special file format (.rdfe) which makes it easy to import (and export) them in Royal TS/X.

## Import

To import a Dynamic Folder, download the .rdfe file, select a folder in Royal TS/X and go to "Import - Dynamic Folder", then select the file. A new Dynamic Folder will be created as a child of the currently selected folder.

In addition to scripts, Dynamic Folder export files can also contain a description, custom properties and notes. Notes are often used to explain how the Dynamic Folder scripts work and what setup steps are required before initiating a reload for the first time. After importing a Dynamic Folder definition, please read the "Notes" section in the properties of the Dynamic Folder.

## Export

If you want to export one of your Dynamic Folders to share it with the world, control-click (right-click) it in the navigation panel and select "Export...". The export dialog allows you to specify what data you want to export (Description, Custom Properties, Notes). Custom Properties can also be anonymized, which, when enabled, replaces the values of your properties with "TODO".

When exporting Dynamic Folders, please double-check that your scripts don't contain any confidential data! Any such data should be stored in other fields (Custom Properties) and be referenced from scripts using replacement tokens (E.g. `$CustomProperty.Server$`)
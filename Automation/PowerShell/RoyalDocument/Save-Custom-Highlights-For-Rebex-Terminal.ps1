<#
    The example code below demonstrates how to define custom Rebex Highlighting
    Definitions for a Rebex Terminal Connection via PowerShell

    2025-07-28  Creation
#>
import-module royaldocument.powershell
import-Module newtonsoft.json

###############################################################################
# variables - adapt to your needs
$fileName = "source.rtsz"


# data structure to hold highlight definitions for Royal TS
Class HighlightItem
{
   [String]$RegexName
   [String]$Regex
   [String]$ForeColor
   [String]$BackColor
   #[int]$ForeColorIndex
   #[int]$BackColorIndex
}

###############################################################################
# 1. Load a document from Filesystem and find Connection
###############################################################################
$fileName = "source.rtsz"
$store = new-royalstore -UserName $env:USERNAME
$doc = Open-RoyalDocument -Store $store -FileName $fileName
$connection = Get-RoyalObject -Folder $doc -Name "Name Of Connction"

###############################################################################
# 2. Prepare example Highlight Definitions
###############################################################################
$rg = New-Object HighlightItem
$rg.RegexName = "royal-gold"
$rg.Regex = '(?<=.)\broyal\b(?=.)'
$rg.ForeColor = "#FFD700"
$rg.BackColor = "#555555"

$rg2 = New-Object HighlightItem
$rg2.RegexName = "royal-red"
$rg2.Regex = '(?<=.)\broyalred\b(?=.)'
$rg2.ForeColor = "#FF0000"
$rg2.BackColor = "#001122"

$highlightDefinitions = @($rg, $rg2)

$arr = @()
for ($i=0; $i -lt $highlightDefinitions.Count; $i++) {
    $arr += @($highlightDefinitions[$i]) | ConvertTo-JsonNewtonsoft
}

###############################################################################
# 3. Assign the new Highlights and save the Document
###############################################################################
$mac.RebexHighlighting = $arr

Out-RoyalDocument -Document $doc -FileName $fileName
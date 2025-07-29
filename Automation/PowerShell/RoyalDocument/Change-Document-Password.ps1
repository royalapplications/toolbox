<#
    Changing document and lockdown password via code for a Royal Document

    Steps: 
        1. Opens a local Royal TS document with a password
        2. Set the document password, a lockdown password and lockdown policies on it
        3. Saves it to a new file

    remark: Because of the way how the file content is encrypted it is adviced
            to always save a document with a changed password/lockdown password
            to a new file.

    2025-07-29  Creation
#>
Import-Module RoyalDocument.PowerShell

###############################################################################
# variables, set accordingly
$localDocPath =        "document-with-pwd.rtsz"
$localDocPathUpdated = "document-with-new-pwd_ld.rtsz"
$pwd = "oldPWD"                # original password of the document
$newPwd = "newPWD"              # new password of the document
$lockdowndPwd = "ldPWD"         # new lockdown password of the document


$pwdSec = convertto-securestring -string $pwd -asplaintext -force
$newPwdSec = convertto-securestring -string $newPwd -asplaintext -force
$lockdowndPwdSec = convertto-securestring -string $lockdowndPwd -asplaintext -force

$store = New-RoyalStore -UserName $Env:UserName

# for Lockdown Policies, use RoyalDocument.PowerShell.LockdownPolicy enum:
# HidePasswords, ReadOnly, AllowPasswordsInWebPage
$ld = [RoyalDocument.PowerShell.LockdownPolicy]'AllowPasswordsInWebPage, ReadOnly'

# open Document with original Password
$doc = Open-RoyalDocument -Store $store -FileName $localDocPath -Password $pwdSec

# set a new password and new lockdown password
Set-RoyalDocumentPassword -Document $doc -OldPassword $pwdSec -NewPassword $newPwdSec `
    -NewLockdownPassword $lockdowndPwdSec -LockdownPolicy $ld | Out-Null

# save it to another file
Out-RoyalDocument -Document $doc -FileName $localDocPathUpdated

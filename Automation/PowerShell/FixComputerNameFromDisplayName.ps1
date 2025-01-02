##
# Description: This simple script updates all URIs (hostnames) to match the current display name.
# In the past we had a customer accidentally messing up the hostnames when using the bulk-edit
# functionality, resulting that no connections were working anymore. Fixing this in a manual way
# might be a lot of work in larger documents. PowerShell script to the rescue.
##
# To see available object types and their names please take a look in the documentation at
# "References - Object Properties" (see navigation panel) on following site:
#  https://content.royalapplications.com/Help/RoyalTS/V5/index.html?scripting_gettingstarted.htm
##

# variables to configure.
$docPath = "Test.rtsz" # exact path to the document file
$types = @( "RoyalRDSConnection", "RoyalSSHConnection" ) # which object types should be changed.
$domain = "domain.tld" # which domain name should be appended to have a FQDN in the end

# magic happens here.
Import-Module Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'Royal TS V5\RoyalDocument.PowerShell.dll'

$store = New-RoyalStore -UserName ($env:USERDOMAIN + '\' + $env:USERNAME)
$doc = Open-RoyalDocument -FileName $docPath -Store $store

foreach($type in $types) {
    Get-RoyalObject -Folder $doc -Type $type | ForEach-Object {
        $uri = $_.Name + $domain
        Set-RoyalObjectValue -Object $_ -Property URI -Value $uri
    }
}

Out-RoyalDocument -Document $doc

# SIG # Begin signature block
# MIISdgYJKoZIhvcNAQcCoIISZzCCEmMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFHhIkjq+iDzbZ7YMXEuanw6J
# o2Wggg7TMIIG6DCCBNCgAwIBAgIQd70OBbdZC7YdR2FTHj917TANBgkqhkiG9w0B
# AQsFADBTMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEp
# MCcGA1UEAxMgR2xvYmFsU2lnbiBDb2RlIFNpZ25pbmcgUm9vdCBSNDUwHhcNMjAw
# NzI4MDAwMDAwWhcNMzAwNzI4MDAwMDAwWjBcMQswCQYDVQQGEwJCRTEZMBcGA1UE
# ChMQR2xvYmFsU2lnbiBudi1zYTEyMDAGA1UEAxMpR2xvYmFsU2lnbiBHQ0MgUjQ1
# IEVWIENvZGVTaWduaW5nIENBIDIwMjAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDLIO+XHrkBMkOgW6mKI/0gXq44EovKLNT/QdgaVdQZU7f9oxfnejlc
# wPfOEaP5pe0B+rW6k++vk9z44rMZTIOwSkRQBHiEEGqk1paQjoH4fKsvtaNXM9JY
# e5QObQ+lkSYqs4NPcrGKe2SS0PC0VV+WCxHlmrUsshHPJRt9USuYH0mjX/gTnjW4
# AwLapBMvhUrvxC9wDsHUzDMS7L1AldMRyubNswWcyFPrUtd4TFEBkoLeE/MHjnS6
# hICf0qQVDuiv6/eJ9t9x8NG+p7JBMyB1zLHV7R0HGcTrJnfyq20Xk0mpt+bDkJzG
# uOzMyXuaXsXFJJNjb34Qi2HPmFWjJKKINvL5n76TLrIGnybADAFWEuGyip8OHtyY
# iy7P2uKJNKYfJqCornht7KGIFTzC6u632K1hpa9wNqJ5jtwNc8Dx5CyrlOxYBjk2
# SNY7WugiznQOryzxFdrRtJXorNVJbeWv3ZtrYyBdjn47skPYYjqU5c20mLM3GSQS
# cnOrBLAJ3IXm1CIE70AqHS5tx2nTbrcBbA3gl6cW5iaLiPcDRIZfYmdMtac3qFXc
# AzaMbs9tNibxDo+wPXHA4TKnguS2MgIyMHy1k8gh/TyI5mlj+O51yYvCq++6Ov3p
# Xr+2EfG+8D3KMj5ufd4PfpuVxBKH5xq4Tu4swd+hZegkg8kqwv25UwIDAQABo4IB
# rTCCAakwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBIGA1Ud
# EwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFCWd0PxZCYZjxezzsRM7VxwDkjYRMB8G
# A1UdIwQYMBaAFB8Av0aACvx4ObeltEPZVlC7zpY7MIGTBggrBgEFBQcBAQSBhjCB
# gzA5BggrBgEFBQcwAYYtaHR0cDovL29jc3AuZ2xvYmFsc2lnbi5jb20vY29kZXNp
# Z25pbmdyb290cjQ1MEYGCCsGAQUFBzAChjpodHRwOi8vc2VjdXJlLmdsb2JhbHNp
# Z24uY29tL2NhY2VydC9jb2Rlc2lnbmluZ3Jvb3RyNDUuY3J0MEEGA1UdHwQ6MDgw
# NqA0oDKGMGh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vY29kZXNpZ25pbmdyb290
# cjQ1LmNybDBVBgNVHSAETjBMMEEGCSsGAQQBoDIBAjA0MDIGCCsGAQUFBwIBFiZo
# dHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAHBgVngQwBAzAN
# BgkqhkiG9w0BAQsFAAOCAgEAJXWgCck5urehOYkvGJ+r1usdS+iUfA0HaJscne9x
# thdqawJPsz+GRYfMZZtM41gGAiJm1WECxWOP1KLxtl4lC3eW6c1xQDOIKezu86Jt
# vE21PgZLyXMzyggULT1M6LC6daZ0LaRYOmwTSfilFQoUloWxamg0JUKvllb0EPok
# ffErcsEW4Wvr5qmYxz5a9NAYnf10l4Z3Rio9I30oc4qu7ysbmr9sU6cUnjyHccBe
# jsj70yqSM+pXTV4HXsrBGKyBLRoh+m7Pl2F733F6Ospj99UwRDcy/rtDhdy6/KbK
# Mxkrd23bywXwfl91LqK2vzWqNmPJzmTZvfy8LPNJVgDIEivGJ7s3r1fvxM8eKcT0
# 4i3OKmHPV+31CkDi9RjWHumQL8rTh1+TikgaER3lN4WfLmZiml6BTpWsVVdD3FOL
# JX48YQ+KC7r1P6bXjvcEVl4hu5/XanGAv5becgPY2CIr8ycWTzjoUUAMrpLvvj19
# 94DGTDZXhJWnhBVIMA5SJwiNjqK9IscZyabKDqh6NttqumFfESSVpOKOaO4ZqUmZ
# XtC0NL3W+UDHEJcxUjk1KRGHJNPE+6ljy3dI1fpi/CTgBHpO0ORu3s6eOFAm9CFx
# ZdcJJdTJBwB6uMfzd+jF1OJV0NMe9n9S4kmNuRFyDIhEJjNmAUTf5DMOId5iiUgH
# 2vUwggfjMIIFy6ADAgECAgw0pEY3n3SHs9/hQR0wDQYJKoZIhvcNAQELBQAwXDEL
# MAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExMjAwBgNVBAMT
# KUdsb2JhbFNpZ24gR0NDIFI0NSBFViBDb2RlU2lnbmluZyBDQSAyMDIwMB4XDTI0
# MDIyNzE1MTYyNFoXDTI3MDIyNzE1MTYyNFowggEgMR0wGwYDVQQPDBRQcml2YXRl
# IE9yZ2FuaXphdGlvbjEQMA4GA1UEBRMHNTMxMzY0djETMBEGCysGAQQBgjc8AgED
# EwJBVDEXMBUGCysGAQQBgjc8AgECEwZWaWVubmExFzAVBgsrBgEEAYI3PAIBARMG
# Vmllbm5hMQswCQYDVQQGEwJBVDEPMA0GA1UECBMGVmllbm5hMQ8wDQYDVQQHEwZW
# aWVubmExGDAWBgNVBAkTD0dyaW1tZ2Fzc2UgMzkvMzEYMBYGA1UEChMPUm95YWwg
# QXBwcyBHbWJIMRgwFgYDVQQDEw9Sb3lhbCBBcHBzIEdtYkgxKTAnBgkqhkiG9w0B
# CQEWGnN0ZWZhbi5rb2VsbEByb3lhbGFwcHMuY29tMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEA5+gaPFDuK28BayL0xvUfyhdNRhCd/G1qPxilMJco+tGO
# RWizRPovlODiWfsH6/Rcvl+Z9vhy1Ga5KzBqZOsJjOIlOgtiDBpx8V+4G0TbGGme
# Ie7Eyh2dIPUb2cdAPw58X/ceeGWdL0GLd3F/VcixDWXwIoDjVC4Wl8AKYmpeUl1N
# t+S18bbiHxHH9PBPVN5gOQZLxO6JudvYEanY2fTtS+C2bsCbEW3Z1ytiyN17a/TW
# pVCm0byLIdIT1+dHVnmnWBPiTtjN6r7cyKzgRtjB7d9cHfjZWHNdAlIh6dmpsB+i
# yW2pXUEGwDXU2YZtiGXmxxAUHSXeKqfHzDbpTYEEYNPFbU7Y8NBs8/frixrG3nuo
# oGnpNk2378T/7cV5m94VCz411qSw7tlCIVJdJKLa1i4rVgVhEpELmO6kqjM9JgAP
# TBHk2buVCeqhjpNFgQUfyJj5OG4kckHxeODnrXivzu/4xiVOv2b48v76xR/u6acr
# 2OLCJxZQNj5WyAjjftPo//pc2AkTQDQ8mQoK7Qaey0oXY5GZTVNlTkgpHfjEPAEO
# J7K3+jTuw/7m4WDOi7vbZYQKpLYimeNBp2KLbn/TvsdTWz6B3hUc1BExnVzdN+57
# XZNetd6RT9HzvdDqDkXT1w30yQXd0rFFe2J/pzw4h+9qo7Ip429cuICYaUqIst0C
# AwEAAaOCAd0wggHZMA4GA1UdDwEB/wQEAwIHgDCBnwYIKwYBBQUHAQEEgZIwgY8w
# TAYIKwYBBQUHMAKGQGh0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0
# L2dzZ2NjcjQ1ZXZjb2Rlc2lnbmNhMjAyMC5jcnQwPwYIKwYBBQUHMAGGM2h0dHA6
# Ly9vY3NwLmdsb2JhbHNpZ24uY29tL2dzZ2NjcjQ1ZXZjb2Rlc2lnbmNhMjAyMDBV
# BgNVHSAETjBMMEEGCSsGAQQBoDIBAjA0MDIGCCsGAQUFBwIBFiZodHRwczovL3d3
# dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAHBgVngQwBAzAJBgNVHRMEAjAA
# MEcGA1UdHwRAMD4wPKA6oDiGNmh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vZ3Nn
# Y2NyNDVldmNvZGVzaWduY2EyMDIwLmNybDAlBgNVHREEHjAcgRpzdGVmYW4ua29l
# bGxAcm95YWxhcHBzLmNvbTATBgNVHSUEDDAKBggrBgEFBQcDAzAfBgNVHSMEGDAW
# gBQlndD8WQmGY8Xs87ETO1ccA5I2ETAdBgNVHQ4EFgQUvmL3XL+0IhNyTwIbvE8k
# 6VZkVL4wDQYJKoZIhvcNAQELBQADggIBAE27Fdab5gR05j0zFXqgwct7afy9+wG/
# EIYEe7Oxvuwi3dBCak95gWyD8LIR2bS/qkpac7q7mN31AFjnFLIe7+1IP0Hs/3ng
# 3BHsqZL6QZ65AWQj0pBXfOJ3hEalo9mNQS0SGVpF1QAqYHP/ZymDW8FbpWioHfJc
# 3SoGh7UXbiC8BA56mbxY9H+7SsVfSBWU6l9UAI0oMWZYZXtVRlfosjfH5Aq4wRL3
# 1TenA7oNCy52DWhUAblLF69oi34msbuPobD22yKZZomK/g8Crzzlrhq9wW+61pBg
# qydlJfuXCjuBczdGosY8HStNdVnyOG1zDt0/eZBQSCLpB2QwhXeutvNOLR97bYtD
# ZqRAzRS0nV2idwRXNvZi4jBe0nZGY6azDy7b5BSdqUUOxSrlvIGcT7KbGn/qqCaa
# zBOwQdJYFBkjieXbGg6iDmv/JcmHJqcmDfKwPpXx6PEsjD1mWkB5INm3qnrj1pQv
# 3+XgUpeF9cDuqev4zy4UxNPt5m6U34rG72CRMsIDoNdXAlJCOdI5PEE+0VE4F/ss
# p2MyeoOm1iWLtWN0Jwx5EEijsSjrRUnoCa516HVe3e6Op+1gbvgykTLZ7ykrk9a+
# l7aaxS+Wj3ehBlLd9g1EQ73LkDjy/UGnce2rxdJGn2+qoZfL/CXAVGHP8S6mOmu9
# aZluxKCQphiyMYIDDTCCAwkCAQEwbDBcMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEyMDAGA1UEAxMpR2xvYmFsU2lnbiBHQ0MgUjQ1IEVW
# IENvZGVTaWduaW5nIENBIDIwMjACDDSkRjefdIez3+FBHTAJBgUrDgMCGgUAoHgw
# GAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGC
# NwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQx
# FgQUyQ1Wrwm2qeQKs5lYNcTyBi4B50gwDQYJKoZIhvcNAQEBBQAEggIA07OsYNw4
# 0BaeGgUApaxYbHKZsuqq9WO5pqXWSsUxRbOkU5iGKQAixIXYiQfQ4VqPpj/7UD8m
# N3J6iZMxP6iREQg7JIKzwQnBIqWxVHLYLhciM6RzE61WlMq5HvqQPAobL4ZgAt8Z
# XjvNpVqGaa9Ktg8fL7EYa6qIb4Pvu2UEbgO9ZPAgEq7S1ab0HvHsKpFLNrFhwwgg
# acjCHvvp1mWkgl6892kQepybFq6WELRtkFg2AaX9cW8DM7ZhlEL63hV5EYSWW0Vb
# m2WyPzGFbtzb7c2FyrulNFD08z0YLnlPCrWd/laNy0T1QJCerXyEtoJnG5gTLznY
# P0zbJzmdjxJMqx08EaEYD4Hs98nUPptISkFhAqhFZrDqcrAPu6i9o49c0SIDx1oF
# IlH+P+eE5s7cUmc8zLbeorynY+1GPxZfMYE6HIeMeViyZTf0nPYYmsxNIL1iTUK8
# 284NFMgIXI/9fvG6azjs5F8Nw7XJ3LCJoFxdIHqcg0yBJc1Zft6IjhuCacmpgx3w
# ld0sae6GYbuPICATqDZn1Jsm+BI0neBOXP98lw18JPSgGuC4PTDKCRg2tUECY06Q
# 2DNbBq84nP0g/d9yQs2/h8nczFei0m0CekDP/xlrqQMVVe7ABHdnVwv7zjL16hVS
# OD1t52mAk7u+8TagNoWs4l1jY2cX2dEe/aQ=
# SIG # End signature block

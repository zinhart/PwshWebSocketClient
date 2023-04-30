<#
Using stackprotector's approach, I hit a few snags that others will undoubtedly hit:

    The cert you target must be exportable. Yes, this should be obvious, but if you are using PowerShell to create the cert, you might miss it. If the key you are running this against is not exportable, you will get an error:

        The requested operation is not supported.

    If creating a cert, add -KeyExportPolicy Exportable to the end of the command.

    How you set the $cert variable is important. It's not just a string value. Using the get-item command, you set the object you want to work with. Then everything else works beautifully.
#>
# Create a self-signed exportable certificate
# https://stackoverflow.com/questions/65083411/creating-pem-file-through-powershell
$temp = New-SelfSignedCertificate -Subject "localhost" -TextExtension @("2.5.29.17={text}DNS=localhost&IPAddress=127.0.0.1&IPAddress=::1") -KeyExportPolicy Exportable  

# Identify the cert to export with the script
$cert = get-item "cert:\localmachine\my\$($temp.Thumbprint)"

# Public key to Base64
$CertBase64 = [System.Convert]::ToBase64String($cert.RawData, [System.Base64FormattingOptions]::InsertLineBreaks)

# Private key to Base64
$RSACng = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
$KeyBytes = $RSACng.Key.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
$KeyBase64 = [System.Convert]::ToBase64String($KeyBytes, [System.Base64FormattingOptions]::InsertLineBreaks)

# Put it all together
$Pem = @"
-----BEGIN PRIVATE KEY-----
$KeyBase64
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
$CertBase64
-----END CERTIFICATE-----
"@

# Output to file
$Pem | Out-File -FilePath .\tests\cert.pem -Encoding Ascii


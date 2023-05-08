$RootCertArgs = @{
  Type = 'Custom'
  KeySpec = 'Signature'
  Subject = 'CN=RootDonkey'
  HashAlgorithm = 'sha256'
  KeyLength = 2048
  KeyUsage = 'CertSign' 
  CertStoreLocation = 'Cert:\LocalMachine\My'
  KeyExportPolicy = 'Exportable'
  NotAfter = (Get-Date).AddYears(5)
  #TextExtension = @("2.5.29.37={text}1.3.6.1.4.1.311.10.3.9") #Root Signer oid
}
$RootCert = New-SelfSignedCertificate @RootCertArgs

$ServerCertArgs = @{
  Type = 'Custom'
  Subject = 'CN=ServerDonkey'
  HashAlgorithm = 'sha256'
  KeyLength = 2048
  DnsName = 'localhost','127.0.0.1','::1'
  CertStoreLocation = "Cert:\LocalMachine\My"
  KeyUsage = 'KeyEncipherment', 'DigitalSignature'
  KeyExportPolicy = 'Exportable'
  NotAfter = (Get-Date).AddMonths(24)
  Signer = $RootCert
  TextExtension = @("2.5.29.37={text}1.3.6.1.5.5.7.3.1")
}
$ServerCert = New-SelfSignedCertificate @ServerCertArgs

$ClientCertArgs = @{
  Type = 'Custom'
  Subject = 'CN=ClientDonkey'
  KeySpec = 'Signature'
  HashAlgorithm = 'sha256'
  KeyLength = 2048
  KeyExportPolicy = 'Exportable'
  NotAfter = (Get-Date).AddMonths(24)
  Signer = $RootCert
  TextExtension = @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
}
$ClientCert = New-SelfSignedCertificate @ClientCertArgs

$RootCert, $ServerCert, $ClientCert | % {

  # Identify the cert to export with the script
  $cert = get-item $_.PSPath

  # Public key to Base64
  $CertBase64 = [System.Convert]::ToBase64String($cert.RawData, [System.Base64FormattingOptions]::InsertLineBreaks)

  # Private key to Base64
  $RSACng = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
  $KeyBytes = $RSACng.Key.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
  $KeyBase64 = [System.Convert]::ToBase64String($KeyBytes, [System.Base64FormattingOptions]::InsertLineBreaks)

# Put it all together
$Cer  = @"
-----BEGIN CERTIFICATE-----
$CertBase64
-----END CERTIFICATE-----
"@
$Pem = @"
-----BEGIN PRIVATE KEY-----
$KeyBase64
-----END PRIVATE KEY-----
$Cer
"@


  # Output to file
  $OutFileName = $cert.Subject -split '='
  $OutFileName = $OutFileName[1] 
  $Pem | Out-File -FilePath ".\$OutFileName.pem" -Encoding Ascii
  $Cer | Out-File -FilePath ".\$OutFileName.cer" -Encoding Ascii
  #Move-Item $cert Cert:\LocalMachine\TrustedAppRoot
}

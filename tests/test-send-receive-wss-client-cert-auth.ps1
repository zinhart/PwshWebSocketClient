<#
  In order for this to work on windows, we must generate a self-signed cert with .\tests\New-Pem.ps1 and
  then move the cert into the trust root certificate store
#>
Import-Module -Name '.\PwshWebSocketClient'
Connect-Websocket -Uri 'wss://127.0.0.1:8002' -Certificate 'C:\Users\zinhart\Documents\code\PoshWebSocketClient\tests\working.pfx' -CertificatePass (ConvertTo-SecureString -String '1234' -AsPlainText -Force)
Send-Message -Message 'Applesauce'
Receive-Message 
Get-WebsocketState
Disconnect-Websocket
Remove-Module PwshWebSocketClient
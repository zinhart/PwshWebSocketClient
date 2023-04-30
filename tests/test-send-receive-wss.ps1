<#
  In order for this to work on windows, we must generate a self-signed cert with .\tests\New-Pem.ps1 and
  then move the cert into the trust root certificate store
#>
Import-Module -Name '.\PwshWebSocketClient'
Connect-Websocket -Uri 'wss://localhost:8001' -Certificate 'C:\Users\zinhart\Documents\code\PoshWebSocketClient\tests\localhost.cer'
Send-Message -Message 'Applesauce'
Receive-Message 
Get-WebsocketState
Disconnect-Websocket
Remove-Module PwshWebSocketClient
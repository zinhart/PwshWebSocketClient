Import-Module -Name '.\PwshWebSocketClient'
Connect-Websocket -Uri 'wss://localhost:8001' -Certificate 'C:\Users\zinhart\Documents\code\PoshWebSocketClient\tests\localhost.cer'
Send-Message -Message 'Applesauce'
Receive-Message 
Get-WebsocketState
Disconnect-Websocket
Remove-Module PwshWebSocketClient
Import-Module -Name '../PoshWebSocketClient'

Connect-Websocket -Uri ws://localhost:8000/
Send-Message -Message 'Applesauce'
Receive-Message 
Send-Message -Message 'Applesauce1'
Receive-Message
Get-WebsocketState

Remove-Module PoshWebSocketClient
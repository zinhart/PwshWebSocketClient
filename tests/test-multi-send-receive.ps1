Import-Module -Name '.\PwshWebSocketClient'

Connect-Websocket -Uri ws://localhost:8000/
Send-Message -Message 'Applesauce'
Receive-Message 
Send-Message -Message 'Applesauce1'
Receive-Message
Get-WebsocketState

Remove-Module PwshWebSocketClient
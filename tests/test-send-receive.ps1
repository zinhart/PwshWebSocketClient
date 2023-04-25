Import-Module -Name '.\PwshWebSocketClient'
Connect-Websocket -Uri ws://localhost:8000/
Send-Message -Message 'Applesauce'
Receive-Message 
Remove-Module PwshWebSocketClient
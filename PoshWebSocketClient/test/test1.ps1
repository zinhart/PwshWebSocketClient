Import-Module -Name '../PoshWebSocketClient'
Connect-Websocket -Uri ws://localhost:8000/
Send-Message -Message 'Applesauce'
Receive-Message 
Remove-Module PoshWebSocketClient
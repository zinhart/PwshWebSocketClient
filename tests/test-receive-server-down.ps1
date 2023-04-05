Import-Module -Name '../PoshWebSocketClient'
Connect-Websocket -Uri ws://localhost:8000/
Receive-Message
Remove-Module PoshWebSocketClient
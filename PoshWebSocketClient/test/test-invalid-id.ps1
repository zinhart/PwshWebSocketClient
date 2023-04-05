Import-Module -Name '../PoshWebSocketClient'
Get-WebSocketState
Connect-Websocket -Uri ws://localhost:8000/
Get-WebSocketState
Get-WebSocketState -Id 1
Remove-Module PoshWebSocketClient
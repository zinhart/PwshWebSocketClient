Import-Module -Name '.\PoshWebSocketClient'
Connect-Websocket -Uri 'ws://localhost:8000'
Get-WebsocketState
Disconnect-Websocket
Get-WebsocketState
Remove-Module PoshWebSocketClient
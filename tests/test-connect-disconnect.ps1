Import-Module -Name '.\PwshWebSocketClient'
Connect-Websocket -Uri 'ws://localhost:8000'
Get-WebsocketState
Disconnect-Websocket
Get-WebsocketState
Remove-Module PwshWebSocketClient
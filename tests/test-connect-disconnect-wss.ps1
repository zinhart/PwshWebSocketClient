Import-Module -Name '.\PwshWebSocketClient'
Connect-Websocket -Uri 'wss://localhost:8002'
Get-WebsocketState
Disconnect-Websocket
Remove-Module PwshWebSocketClient
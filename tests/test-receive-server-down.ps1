Import-Module -Name '.\PwshWebSocketClient'
Connect-Websocket -Uri ws://localhost:8000/
Receive-Message
Remove-Module PwshWebSocketClient
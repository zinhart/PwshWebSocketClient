Import-Module -Name '.\PwshWebSocketClient'
Connect-Websocket -Uri 'ws://localhost:8000/' -Proxy 'http://localhost:8080/'
Send-Message -Message 'Applesauce'
Receive-Message 
Get-WebsocketState
Remove-Module PwshWebSocketClient
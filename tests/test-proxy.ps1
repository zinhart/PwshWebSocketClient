#start proxy: python .\tests\proxy.py --port 8001 --remote_url ws://localhost:8000
#start intended receiver: python .\tests\echo-server.
Import-Module -Name '.\PwshWebSocketClient'
Connect-Websocket -Uri 'ws://localhost:8001/' -Proxy 'ws://localhost:8000/'
Send-Message -Message 'Applesauce'
Receive-Message 
Get-WebsocketState
Disconnect-Websocket
Remove-Module PwshWebSocketClient
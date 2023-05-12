#start proxy: python .\tests\proxy.py --port 8001 --remote_url ws://localhost:8000
#start intended receiver: python .\tests\echo-server.
Import-Module -Name '.\PwshWebSocketClient'
$NetworkCredential = [System.Net.NetworkCredential]::new("donkey", "donkey")
Connect-Websocket -Uri 'ws://localhost:8000/' -NetworkCredential $NetworkCredential
Send-Message -Message 'Applesauce'
#Receive-Message 
Get-WebsocketState
Disconnect-Websocket
Remove-Module PwshWebSocketClient
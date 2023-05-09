#start proxy: python .\tests\proxy.py --port 8001 --remote_url ws://localhost:8000
#start intended receiver: python .\tests\echo-server.
Import-Module -Name '.\PwshWebSocketClient'
$Uri = 'ws://localhost:8000/'
$Cookie = [System.Net.Cookie]::new("donkey", "Important value: heee haw")
$Cookie.Domain='localhost'
$Cookie.HttpOnly = $true
$CookieJar = New-Object System.Net.CookieContainer
$CookieJar.add($Cookie)
Connect-Websocket -Uri 'ws://localhost:8000/' -Cookies $CookieJar
Send-Message -Message 'Applesauce'
#Receive-Message 
Get-WebsocketState
Disconnect-Websocket
Remove-Module PwshWebSocketClient
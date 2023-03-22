<#
We can test with the following website: https://www.piesocket.com/websocket-tester
#>
#Import-Module -Name 'C:\Users\zinhart\Documents\code\posh-websocket\src\posh-websocket.psm1' -Force
Import-Module -Name '/home/vagrant/Desktop/awae/docedit/websocket_client/posh-websocket/src/posh-websocket/posh-websocket.psm1' -Force
Connect-Websocket -Endpoint 'ws://localhost:8000'
#Connect-Websocket -Endpoint 'wss://demo.piesocket.com/v3/channel_123?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV&notify_self'
#Connect-Websocket -Endpoint 'wss://socketsbay.com/wss/v2/1/demo/'
#Connect-Websocket -Endpoint 'wss://ws.postman-echo.com/raw'
Send-Message -Message 'testing'
Receive-Message #-Milliseconds 5000
Receive-Message
#Remove-Module -Name '/home/vagrant/Desktop/awae/docedit/websocket_client/posh-websocket/src/posh-websocket/posh-websocket.psm1' -Force
Disconnect-Websocket
Remove-Module -Name 'posh-websocket' -Force
#Remove-Module -Name 'C:\Users\zinhart\Documents\code\posh-websocket\src\posh-websocket.psm1' -Force
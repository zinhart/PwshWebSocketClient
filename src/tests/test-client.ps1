<#
We can test with the following website: https://www.piesocket.com/websocket-tester
#>
Import-Module -Name '/home/vagrant/Desktop/awae/docedit/websocket_client/posh-websocket/src/posh-websocket/posh-websocket.psm1' -Force
Connect-Websocket -Endpoint 'ws://localhost:8000'
Send-Message -Message 'testing'
Receive-Message #-Milliseconds 5000
# multiple receives after a send will not block!!!
Receive-Message
Disconnect-Websocket
Remove-Module -Name 'posh-websocket' -Force
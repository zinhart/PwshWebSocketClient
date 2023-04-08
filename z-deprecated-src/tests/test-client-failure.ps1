# basically check module behavior when receive is called with no message present, the script should fail gracefully
# the exception is propagated to wait-job
Import-Module -Name '/home/vagrant/Desktop/awae/docedit/websocket_client/posh-websocket/src/posh-websocket/posh-websocket.psm1' -Force
Connect-Websocket -Endpoint 'ws://localhost:8000'
Receive-Message 
Send-Message -Message 'testing'
Receive-Message
Disconnect-Websocket
Remove-Module -Name 'posh-websocket' -Force
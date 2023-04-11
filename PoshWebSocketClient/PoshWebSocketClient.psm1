#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach($import in @($Public + $Private))
{
  Try
  {
    . $import.fullname
  }
  Catch
  {
    Write-Error -Message "Failed to import function $($import.fullname): $_"
  }
}
# Typically we would: Export-ModuleMember -Function $Public.Basename
# But since there is a shared state: create instance of websocket client
$ws_client = New-WebSocketClient
# Other
Function Connect-Websocket {
  Param (
    [Parameter(Mandatory=$true)]
    [string]$Uri
  )
  return $ws_client.ConnectWebsocket($uri)
}

Function Send-Message {
  param(
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [int]$SocketId = 0
  )
  return $ws_client.SendMessage($message, $SocketId)
}

Function Receive-Message {
  param(
    [Parameter(Mandatory=$false)]
    [int]$Timeout = 10000, # milliseconds
    [Parameter(Mandatory=$false)]
    [int]$buffer_sz = 1024,
    [Parameter(Mandatory=$false)]
    [int]$SocketId = 0
  )
  return $ws_client.ReceiveMessage($SocketId, $buffer_sz)
}

Function Disconnect-Websocket {
  param(
    [Parameter(Mandatory=$false)]
    [int]$SocketId = 0
  )
  return $ws_client.DisconnectWebsocket($SocketId)
}
Function Get-WebsocketState {
  param(
    [Parameter(Mandatory=$false)]
    [int]$SocketId = 0
  )
  return $ws_client.GetWebsocketState($SocketId)
}
<# Redundant with get-websocketstate
Function Test-Websocket {
 param(
  [Parameter(Mandatory=$false)]
  [int]$SocketId = 0
  )
  return $ws_client.TestWebsocket($SocketId)
}
#>
Export-ModuleMember Connect-Websocket,Disconnect-Websocket,Send-Message,Receive-Message, Get-WebsocketState
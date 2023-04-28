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

<#
.SYNOPSIS
  Initiate a managed websocket connection.
.DESCRIPTION
  Initiate a managed websocket connection.
.PARAMETER Uri
  Open a Websocket Connection to the Uri specified in the parameter.
.EXAMPLE
  Connect-WebSocket -Uri 'ws://uri here'
.EXAMPLE
  Connect-WebSocket -Uri 'wss://uri here'
#>
Function Connect-Websocket {
  Param (
    [Parameter(Mandatory=$true)]
    [string]$Uri,
    # The Parameters below are taken from .net core 3 https://learn.microsoft.com/en-us/dotnet/api/system.net.websockets.clientwebsocketoptions?view=netcore-3.1
    [Parameter(Mandatory=$false)]
    [string]$Cookies='',
    [Parameter(Mandatory=$false)]
    [string]$Credentials='',
    [Parameter(Mandatory=$false)]
    $KeepAliveInterval=[System.TimeSpan]::zero, #https://stackoverflow.com/questions/40502921/net-websockets-forcibly-closed-despite-keep-alive-and-activity-on-the-connectio
    [Parameter(Mandatory=$false)]
    [string]$Proxy=''


  )
  if($Proxy -ne '') { return $ws_client.ConnectWebsocket($uri, $proxy)  }
  else { return $ws_client.ConnectWebsocket($uri) }
}
<#
.SYNOPSIS
  Send a message over a websocket.
.DESCRIPTION
  Send a message over a websocket.
.PARAMETER Message
  The message to be send over the websocket.
.PARAMETER SocketId
  The websocket that the message is to be sent on. This parameter defaults to 0, thus if no SocketId is specified all messages will be sent over the first websocket created.
.EXAMPLE
  Send-Message -Message datatobesent
.EXAMPLE
  Send-Message -Message 'Message_Here'
.EXAMPLE
  Send-Message -Message 'Message_Here' -SocketId 0
#>
Function Send-Message {
  param(
    [Parameter(Mandatory=$true)]
    [string]$Message,
    [Parameter(Mandatory=$false)]
    [int]$SocketId = 0
  )
  return $ws_client.SendMessage($Message, $SocketId)
}
<#
.SYNOPSIS
  Receive a message over a websocket.
.DESCRIPTION
  Receive a message over a websocket.
.PARAMETER BufferSize
  The maximum amount of data the websocket receive at once. The buffer size defaults to 1kb (1024 bytes).
.PARAMETER SocketId
  The socket that the message is to be received on. This parameter defaults to 0, thus if no SocketId is specified all messages will be received on the first websocket created.
.EXAMPLE
  Receive-Message
.EXAMPLE
  Receive-Message -SocketId 0
.EXAMPLE
  Receive-Message -SocketId 0 -BufferSize 4096
#>
Function Receive-Message {
  param(
    [Parameter(Mandatory=$false)]
    [int]$BufferSize = 1024,
    [Parameter(Mandatory=$false)]
    [int]$SocketId = 0
  )
  return $ws_client.ReceiveMessage($SocketId, $BufferSize)
}

<#
.SYNOPSIS
  Disconnect a websocket connection.
.DESCRIPTION
  Disconnect a websocket connection.
.PARAMETER SocketId
  The websocket to disconnect. This parameter defaults to 0, thus if no SocketId is specified the first websocket created will be disconnected.
.EXAMPLE
  Disconnect-WebSocket
.EXAMPLE
  Disconnect-WebSocket -SocketId 0
#>
Function Disconnect-Websocket {
  param(
    [Parameter(Mandatory=$false)]
    [int]$SocketId = 0
  )
  return $ws_client.DisconnectWebsocket($SocketId)
}

<#
.SYNOPSIS
  Get information about a websocket.
.DESCRIPTION
  Get information about a websocket.
.PARAMETER SocketId
  The websocket to disconnect. This parameter defaults to 0, thus if no SocketId is specified this commandlet will return the state of the first websocket created.
.EXAMPLE
  Get-WebSocketState
.EXAMPLE
  Get-WebSocketState -SocketId 0
#>
Function Get-WebsocketState {
  param(
    [Parameter(Mandatory=$false)]
    [int]$SocketId = 0
  )
  return $ws_client.GetWebsocketState($SocketId)
}

Export-ModuleMember Connect-Websocket,Disconnect-Websocket,Send-Message,Receive-Message, Get-WebsocketState
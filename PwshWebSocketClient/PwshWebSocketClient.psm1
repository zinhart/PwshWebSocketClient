<#
  Understanding standing the websocket protocol: https://stackoverflow.com/questions/26791107/ws-on-http-vs-wss-on-https
  In order to become a true engineer don't avoid reading rfc's: https://www.rfc-editor.org/rfc/rfc6455
#>

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
$WebSocketClient = New-WebSocketClient
# Other


<#
.SYNOPSIS
  Initiate a managed websocket connection.
.DESCRIPTION
  Initiate a managed websocket connection.
.PARAMETER Uri
  Open a Websocket Connection to the Uri specified in the parameter.
.PARAMETER Certificate
  The Filepath to a X.509 in pfx format. If this argument is present then the password must be supplied CertificatePass 
.PARAMETER CertificatePass
  The password to the X.509 certificate supplied in the Certificate argument, wrapped as a secure string.
.PARAMETER KeepAliveInterval
  Sets the frequency at which to send Ping/Pong keep-alive control frames.
  Dotnet sets the default is two minutes, the default behavior of this module is keep the websocket connect alive no matter what.
  This is accomplished by setting the default value of this parameter to [System.TimeSpan]::zero
.PARAMETER Proxy
  A Uri to a proxy websocket server.
.EXAMPLE
  Connect-WebSocket -Uri 'ws://uri here'
.EXAMPLE
  Connect-WebSocket -Uri 'wss://uri here'
.EXAMPLE
  Connect-WebSocket -Uri 'wss://uri here' -KeepAliveInterval [System.TimeSpan]::zero
.EXAMPLE
  Connect-WebSocket -Uri 'ws://uri here' -Proxy 'ws://proxy_uri'
.EXAMPLE
  Connect-WebSocket -Uri 'wss://uri here' -Proxy 'wss://proxy_uri'
.EXAMPLE
  Connect-WebSocket -Uri 'wss://uri here' --Certificate path-to-pfx-format-certificate --CertificatePass pfx-cert-pass
#>
Function Connect-Websocket {
 [CmdletBinding(DefaultParameterSetName='Default')]
  Param (
    [Parameter(Mandatory=$true)]
    [string]$Uri,
    [Parameter(Mandatory=$true, ParameterSetName="TLS Auth")]
    [string]$Certificate, #https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509certificate?view=netcore-3.1
    [Parameter(Mandatory=$true, ParameterSetName="TLS Auth")]
    [System.Security.SecureString]$CertificatePass,
    # The Parameters below are taken from .net core 3 https://learn.microsoft.com/en-us/dotnet/api/system.net.websockets.clientwebsocketoptions?view=netcore-3.1
    [Parameter(Mandatory=$false)]
    [string]$Cookies,
    [Parameter(Mandatory=$false)]
    [string]$Credentials,
    [Parameter(Mandatory=$false)]
    [System.TimeSpan]$KeepAliveInterval=[System.TimeSpan]::zero, #https://stackoverflow.com/questions/40502921/net-websockets-forcibly-closed-despite-keep-alive-and-activity-on-the-connectio
    [Parameter(Mandatory=$false)]
    [string]$Proxy
  )
  return $WebSocketClient.ConnectWebsocket($Uri, $Certificate, $CertificatePass, $Cookies, $Credentials, $KeepAliveInterval, $Proxy )
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
  return $WebSocketClient.SendMessage($Message, $SocketId)
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
  return $WebSocketClient.ReceiveMessage($SocketId, $BufferSize)
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
  return $WebSocketClient.DisconnectWebsocket($SocketId)
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
  return $WebSocketClient.GetWebsocketState($SocketId)
}

Export-ModuleMember Connect-Websocket,Disconnect-Websocket,Send-Message,Receive-Message, Get-WebsocketState
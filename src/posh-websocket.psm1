##
# PowerShell Module for a WebSocket connection. Meant to be commandline alternative to python's socket.io
##
$script:websocket = $null
$script:cancellation_token = New-Object System.Threading.CancellationToken
$script:connection = $null

# https://blog.ironmansoftware.com/powershell-async-method/#:~:text=PowerShell%20does%20not%20provide%20an,when%20calling%20async%20methods%20in%20.

function Wait-Task {
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [System.Threading.Tasks.Task[]]$Task,
    [Parameter(Mandatory=$false)]
    [int]$timeout = 200
  )

  Begin {
    $Tasks = @()
  }

  Process {
    $Tasks += $Task
  }

  End {
    While (-not [System.Threading.Tasks.Task]::WaitAll($Tasks, $timeout)) {}
    $Tasks.ForEach( { $_.GetAwaiter().GetResult() })
  }
}

Set-Alias -Name await -Value Wait-Task -Force
<#
class websocket_client {
  $websocket = $null
  $cancellation_token = $(New-Object System.Threading.CancellationToken)
  $connection = $null
  # connect
  # test connection
  # send message
  # receive message
  # disconnect
}
#>
<#
$websocket_status = [PSCustomObject]@{
    Content = ''
    Timeout = ''
    Connected = ''
}
#>
<#
 .Synopsis
  Connect to a websocket endpoint

 .Description
  Try to set up a connection to the provided endpoint

 .Parameter Endpoint
  The full uri to the websocket endpoint
#>
Function Connect-Websocket {
  param(
    [Parameter(Mandatory=$true)]
    [string]
    $Endpoint
  )
  
  # make sure we are not starting too many clients
  if( (Disconnect-Websocket) -eq $true ){
    $script:websocket = New-Object System.Net.WebSockets.ClientWebSocket
  }
  # possible await here, gets rid of the need for a while loop.
  $script:connection = $script:websocket.ConnectAsync($Endpoint, $script:cancellation_token)
  While (-not $script:connection.IsCompleted) {
    Start-Sleep -Milliseconds 100
  }
  return (Test-Websocket)
}

<#
 .Synopsis
  Get Websocket State

 .Description
  Find the current State of the Websocket connection

 .Example
  # perform stuff while the connection is available
  While (Test-Websocket) {
    Write-Host (Receive-Message)    
  }
#>
Function Test-Websocket {
    return ($script:websocket.State -eq 'Open')
}

<#
 .Synopsis
  Send a Message to a Websocket endpoint

 .Description
  Convert a Message String to a ByteArray and push it on the open Websocket

 .Parameter Message
  The Message to send
#>
Function Send-Message {
  param(
    [Parameter(Mandatory=$true)]
    [string]
    $message
  )
  $byte_stream = [system.Text.Encoding]::UTF8.GetBytes($message)
  $message_stream = New-Object System.ArraySegment[byte] -ArgumentList @(,$byte_stream)
  # possibly await here
  $send_connection = $script:websocket.SendAsync($message_stream, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $script:cancellation_token)

  return $send_connection.IsCompleted
}

<#
 .Synopsis
  Receive Messages from a Websocket connection

 .Description
  Wait for Messages to arrive and return that ByteArray to as a String

 .Example
  # wait for a message
  $msg = Receive-Message
#>
Function Receive-Message {
  param(
    [Parameter(Mandatory=$false)]
    [int]$timeout = 0,
    [Parameter(Mandatory=$false)]
    [int]$buffer_sz = 1024
  )
  $buffer = [byte[]] @(,0) * $buffer_sz
  $recv = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)

  $content = ""
  if ($timeout -le 0) { # stops only when message buffer is full
    do {
      $script:connection = $script:websocket.ReceiveAsync($recv, $script:cancellation_token)
      while (-not $script:connection.IsCompleted) { Start-Sleep -Milliseconds 100 }
      $recv.Array[0..($script:connection.Result.Count - 1)] |ForEach-Object { $content += [char]$_ }
    } until ($script:connection.Result.Count -lt $buffer_sz)
  }
  else {# stops when message buffer is full OR X seconds have passed
    $stop_watch = New-Object -TypeName System.Diagnostics.Stopwatch
    $time_span = New-TimeSpan -Seconds $timeout
    $stop_watch.Start()
    while($true) {
      $stop_watch.Elapsed.Milliseconds
      if ($stop_watch.Elapsed.Milliseconds -ge $timeout) {
        break;
      }
      
      $script:connection = $script:websocket.ReceiveAsync($recv, $script:cancellation_token)
      $recv.Array[0..($script:connection.Result.Count - 1)] | ForEach-Object { $content += [char]$_ }
    }
    <#do {
      $script:connection = $script:websocket.ReceiveAsync($recv, $script:cancellation_token)
      while (-not $script:connection.IsCompleted) { Start-Sleep -Milliseconds 100 }
      $recv.Array[0..($script:connection.Result.Count - 1)] | ForEach-Object { $content += [char]$_ }
    } until (($script:connection.Result.Count -gt $buffer_sz) -or ($stop_watch.Elapsed -ge $time_span))
    #>
  }
  return $content
}

<#
 .Synopsis
  Closes the Websocket connection

 .Description 
  Closes the Websocket connection

 .Example
  # close a websocket connection
  Disconnect-Websocket
#>
Function Disconnect-Websocket {
  if($script:websocket) {
    #cleanup
    $script:websocket.Dispose()
    # reset state
    $script:websocket = $null
    $script:cancellation_token = New-Object System.Threading.CancellationToken
    $script:connection = $null
  }
  return (-not $script:websocket)
}

Export-ModuleMember Connect-Websocket,Test-Websocket,Disconnect-Websocket,Send-Message,Receive-Message
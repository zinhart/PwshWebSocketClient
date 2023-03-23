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
    try {
      While (-not [System.Threading.Tasks.Task]::WaitAll($Tasks, $timeout)) {}
      $Tasks.ForEach( { $_.GetAwaiter().GetResult() })
    }
    catch {
      Write-Host $_.Exception.Message -ForegroundColor Red
      Write-Host "Stacktrace: " $_.ScriptStackTrace -ForegroundColor Red
    }
  }
}

Set-Alias -Name await -Value Wait-Task -Force
class websocket_client {
  $websockets = $null
  # the proper way to create a cancellation token: https://learn.microsoft.com/en-us/dotnet/api/system.threading.cancellationtokensource?view=net-7.0
  # with this method we can cancel receive after a period of time
  $cancellation_token_srcs = $null;#New-Object System.Threading.CancellationTokenSource;
  $cancellation_tokens = $null;#(New-Object System.Collections.ArrayList);#$script:cancellation_token_src.Token;#New-Object System.Threading.CancellationToken
  $connections = $null
  websocket_client() {
    $this.websockets = (New-Object System.Collections.ArrayList);
    $this.cancellation_token_srcs = (New-Object System.Collections.ArrayList);#New-Object System.Threading.CancellationTokenSource;
    $this.cancellation_tokens = (New-Object System.Collections.ArrayList);#$script:cancellation_token_src.Token;#New-Object System.Threading.CancellationToken
    $this.connections = (New-Object System.Collections.ArrayList);
  }

  [int]ConnectWebsocket([string] $uri) {
    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $cts = New-Object System.Threading.CancellationTokenSource;
    $ct = $cts.Token;
    $conn = await $ws.ConnectAsync($uri, $ct);
    $this.websockets.add($ws);
    $this.cancellation_token_srcs.add($cts);
    $this.cancellation_tokens.add($ct);
    $this.connections.add($conn); 
    return $this.websockets.Count - 1;
  }
  [bool]TestWebsocket([int] $id) {
    if ($id -lt $this.websockets.Count - 1) {
      return ($this.websockets[$id].State -eq 'Open')
    }
    return $false;
  }
  [bool]SendMessage([string]$message, [int] $id){
    if ($id -lt $this.websockets.Count - 1) {
      $byte_stream = [system.Text.Encoding]::UTF8.GetBytes($message)
      $message_stream = New-Object System.ArraySegment[byte] -ArgumentList @(,$byte_stream)
      # possibly await here
      $send_connection = await $script:websocket.SendAsync($message_stream, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $script:cancellation_token)
      return $send_connection.IsCompleted
    }
    return $false;
  }
  [string]ReceiveMessage([string]$message, [int] $id) {
    if ($id -lt $this.websockets.Count - 1) {
      [int]$timeout = 5;
      [int]$buffer_sz = 1024;
      $buffer = [byte[]] @(,0) * $buffer_sz
      $recv = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
      $content = "";
      $this.cancellation_token_srcs[$id].cancelafter([TimeSpan]::Fromseconds($timeout)) # forces an error receive is called while there is no message
      do {
        while (-not $this.connections[$id].IsCompleted) { 
          $this.connections[$id] = $this.websockets[$id].ReceiveAsync($recv, $this.cancellation_tokens[$id])
        }
        $recv.Array[0..($this.connections[$id].Result.Count - 1)] | ForEach-Object { $content += [char]$_ }
      } until ($this.connections[$id].Result.Count -lt $buffer_sz)
      return $content;
    }
    return '';
  }
  [void] DisconnectWebsocket($id) {
    if ($id -lt $this.websockets.Count - 1) {
      $this.websockets[$id].Dispose()
      # should probably also reset state
    }
  }
  <#
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
  $script:connection = await $script:websocket.ConnectAsync($Endpoint, $script:cancellation_token)
  return (Test-Websocket)
}
#>
}
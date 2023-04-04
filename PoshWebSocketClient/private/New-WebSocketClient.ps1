# Synctactic sugar see: https://blog.ironmansoftware.com/powershell-async-method/#:~:text=PowerShell%20does%20not%20provide%20an,when%20calling%20async%20methods%20in%20.
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

# https://stackoverflow.com/questions/11981208/creating-and-throwing-new-exception
class InvalidWebsocketIdException : Exception {
  [string] $additionalData
  InvalidWebsocketIdException($Message, $additionalData) : base($Message) {
    $this.additionalData = $additionalData
  }
}

class WebsocketClientConnection {
  $websocket = $null
  $cancellation_token_src = $null;
  $connection = $null
  WebSocketClientConnection([string] $uri) {
    [WebSocketClientConnection]::reset($this, $uri)
  }
  static [void] cleanup([WebSocketClientConnection] $conn) { if ($null -ne $conn.websocket) {$conn.websocket.Dispose()} }
  static [void] reset([WebSocketClientConnection] $conn, [string] $uri) {
    [WebsocketClientConnection]::cleanup($conn)
    $conn.websocket = New-Object System.Net.WebSockets.ClientWebSocket;
    # the proper way to create a cancellation token: https://learn.microsoft.com/en-us/dotnet/api/system.threading.cancellationtokensource?view=net-7.0
    $conn.cancellation_token_src = New-Object System.Threading.CancellationTokenSource;
    $conn.connection = await $conn.websocket.ConnectAsync($uri, $conn.cancellation_token_src.Token);
  }
  static [bool] isOpen([WebSocketClientConnection] $conn) { return ($conn.websocket.State -eq 'Open') }
  static [string] getState([WebSocketClientConnection] $conn) { return $conn.websocket.State }
  static [System.Threading.Tasks.Task] sendMessage([WebSocketClientConnection] $conn, [string] $message) {
    $byte_stream = [system.Text.Encoding]::UTF8.GetBytes($message);
    $message_stream = New-Object System.ArraySegment[byte] -ArgumentList @(,$byte_stream);
    return $conn.websocket.SendAsync($message_stream, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $conn.cancellation_token_src.Token);
  }
  static [string] receiveMessage([WebSocketClientConnection] $conn, [int]$buffer_sz) {
    $buffer = [byte[]] @(,1) * $buffer_sz
    $recv = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
    $content = "";
    while ($conn.websocket.State -eq 'Open') {
      [System.Net.WebSockets.WebSocketReceiveResult] $res = (await $conn.websocket.ReceiveAsync($recv, $conn.cancellation_token_src.Token))
      $recv.Array[0..($res.Count - 1)] | ForEach-Object { $content += [char]$_ }
      if($res.EndOfMessage) {
        Write-Host " $([System.Net.WebSockets.WebSocketMessageType]::Close)"
        break;
      }
      elseif ($res.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
        await $conn.websocket.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, [string]::Empty, $conn.cancellation_token_src.Token);
      }
    }
    return $content
  }
  # using a timeout in this way invalidates the entire websocket and introduces alot of cleanup so it's of limited value to use it right now. This overload of receiveMessage is here incase I find a usecase later.
  static [string] receiveMessage([WebSocketClientConnection] $conn, [int]$timeout, [int]$buffer_sz) {
    $buffer = [byte[]] @(,1) * $buffer_sz
    $recv = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
    $content = "";
    #forces an error receive is called while there is no message. It's important to note that cancelation sets the websocket state to aborted
    $conn.cancellation_token_src.cancelafter([TimeSpan]::Fromseconds($timeout)) 
    while ($conn.websocket.State -eq 'Open') {
      [System.Net.WebSockets.WebSocketReceiveResult] $res = (await $conn.websocket.ReceiveAsync($recv, $conn.cancellation_token_src.Token))
      $recv.Array[0..($res.Count - 1)] | ForEach-Object { $content += [char]$_ }
      if($res.EndOfMessage) {
        Write-Host " $([System.Net.WebSockets.WebSocketMessageType]::Close)"
        break;
      }
      elseif ($res.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
        await $conn.websocket.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, [string]::Empty, $conn.cancellation_token_src.Token);
      }
    }
    return $content
  }
}

[PSCustomObject]@{
  PSTypeName = "WebSocketClientStatus"
  First = $First
  Last = $Last
  Phone = $Phone
}
class WebSocketClient {

  $websockets = $null

  WebSocketClient() {
    $this.websockets = (New-Object System.Collections.ArrayList);
  }
  [bool]ValidateId([int] $id) {
    try {
      if ($id -le $this.websockets.Count - 1){
        return $true
      }
      else {
        throw [InvalidWebsocketIdException]::new("$id >= $($this.websockets.Count - 1)","$($_.StackTrace)")
      }
    }
    catch [InvalidWebsocketIdException] {
      <#Do this if a terminating exception happens#>
      Write-Output $_.Exception.additionalData
      # This will produce the error message: Didn't catch it the second time
      throw [InvalidWebsocketIdException]::new("Didn't catch it the second time", 'Extra data')
      return $false
    }
  }
  [int]ConnectWebsocket([string] $uri) {
    $websocket_connection = [WebSocketClientConnection]::new($uri)
    if([WebSocketClientConnection]::isOpen($websocket_connection)) {
      $this.websockets.add($websocket_connection)
      $id = $this.websockets.Count - 1;
      return $id
    }
    return -1;
  }

  [string]GetWebsocketState([int] $id = 0) {
    if ($this.ValidateId($id)) {return [WebSocketClientConnection]::getState($this.websockets[$id]) }
    return ''
  }
  [bool]TestWebsocket([int] $id = 0) {
    if ($this.ValidateId($id)) { return [WebSocketClientConnection]::isOpen($this.websockets[$id]) }
    return $false;
  }
  [bool]SendMessage([string]$message, [int] $id = 0){
    if ($this.ValidateId($id)) { return (await ([WebSocketClientConnection]::sendMessage($this.websockets[$id], $message))); }
    return $false;
  }
  [string]ReceiveMessage([int] $id = 0, [int]$buffer_sz) {
    if ($this.ValidateId($id)) {
      #return (await ([WebSocketClientConnection]::receiveMessage($this.websockets[$id], $timeout, $buffer_sz)))
      return ([WebSocketClientConnection]::receiveMessage($this.websockets[$id], $buffer_sz))
    }
    return ''
  }
  <#
  [string]ReceiveMessage([int] $id = 0,  [int]$timeout, [int]$buffer_sz) {
    if ($this.ValidateId($id)) {
      #return (await ([WebSocketClientConnection]::receiveMessage($this.websockets[$id], $timeout, $buffer_sz)))
      return ([WebSocketClientConnection]::receiveMessage($this.websockets[$id], $timeout, $buffer_sz))
    }
    return ''
  }
  #>
  [void] DisconnectWebsocket($id = 0) {
    if ($this.ValidateId($id)) {
    #if ($id -le $this.websockets.Count - 1) {
      $this.websockets[$id].websocket.Dispose()
      # reset state
      $this.websockets[$id] =  $null
      $this.cancellation_token_srcs[$id] = $null
      $this.cancellation_tokens[$id] = $null
      $this.connections[$id] = $null 
    }
  }
}
Function New-WebSocketClient {
  return [WebSocketClient]::new()
}

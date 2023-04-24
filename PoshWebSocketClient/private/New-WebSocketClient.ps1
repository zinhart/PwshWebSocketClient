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
class InvalidWebSocketIdException : Exception {
  [string] $additionalData
  InvalidWebSocketIdException($Message, $additionalData) : base($Message) {
    $this.additionalData = $additionalData
  }
}

class WebSocketClientConnectStatus
{
  [ValidateRange(-1, [int]::MaxValue)][string]$SocketId
  [ValidateNotNullOrEmpty()][string]$Uri
  [ValidateNotNullOrEmpty()][string]$Status
}
class WebSocketClientSendMsgStatus
{
  [ValidateRange(-1, [int]::MaxValue)][int]$SocketId
  [ValidateNotNullOrEmpty()][string]$Status
}
class WebSocketClientRecvMsgStatus
{
  [ValidateRange(-1, [int]::MaxValue)][int]$SocketId
  [ValidateNotNullOrEmpty()][string]$Status
  [ValidateNotNullOrEmpty()][string]$Msg
}

class WebSocketClientState {
  [ValidateRange(-1, [int]::MaxValue)][string]$SocketId 
  [ValidateNotNullOrEmpty()][string]$State
}

class WebsocketClientConnection {
  $websocket = $null
  $cancellation_token_src = $null;
  WebSocketClientConnection([string] $uri) {
    [WebSocketClientConnection]::reset($this, $uri)
  }
  static [void] cleanup([WebSocketClientConnection] $conn) { if ($null -ne $conn.websocket) {$conn.websocket.Dispose()} }
  static [void] reset([WebSocketClientConnection] $conn, [string] $uri) {
    #[WebsocketClientConnection]::cleanup($conn)
    if ($null -ne $conn.websocket) {
      if ($conn.websocket.State -eq 'Open') { return }
      else { $conn.websocket.Dispose() }
    }
    $conn.websocket = New-Object System.Net.WebSockets.ClientWebSocket;
    if ($null -ne $conn.cancellation_token_src) { $conn.cancellation_token_src.Dispose() }
    # the proper way to create a cancellation token: https://learn.microsoft.com/en-us/dotnet/api/system.threading.cancellationtokensource?view=net-7.0
    $conn.cancellation_token_src = New-Object System.Threading.CancellationTokenSource;
    await $conn.websocket.ConnectAsync($uri, $conn.cancellation_token_src.Token)
  }
  static [void] disconnect([WebSocketClientConnection] $conn) {
    if ($null -eq $conn.websocket) { return }
    if ($conn.websocket.State -eq 'Open') { 
      $conn.cancellation_token_src.cancelafter([TimeSpan]::Fromseconds(2))
      await $conn.websocket.CloseOutputAsync([System.Net.WebSockets.WebSocketCloseStatus]::Empty,"", [System.Threading.CancellationToken]::None)
      await $conn.websocket.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "", [System.Threading.CancellationToken]::None)
    }
    $conn.websocket.Dispose()
    $conn.websocket = $null
    $conn.cancellation_token_src.Dispose()
    $conn.cancellation_token_src = $null
  }
  static [bool] isOpen([WebSocketClientConnection] $conn) { return ($conn.websocket.State -eq 'Open') }
  static [string] getState([WebSocketClientConnection] $conn) { 
    if ($null -eq $conn.websocket) { 
      return 'Disconnected' 
    }  
    return $conn.websocket.State 
  }
  static [System.Threading.Tasks.Task] sendMessage([WebSocketClientConnection] $conn, [string] $message) {
    $byte_stream = [system.Text.Encoding]::UTF8.GetBytes($message);
    $message_stream = New-Object System.ArraySegment[byte] -ArgumentList @(,$byte_stream);
    return $conn.websocket.SendAsync($message_stream, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $conn.cancellation_token_src.Token);
  }
  # food for thought: https://stackoverflow.com/questions/30523478/connecting-to-websocket-using-c-sharp-i-can-connect-using-javascript-but-c-sha
  static [string] receiveMessage([WebSocketClientConnection] $conn, [int]$buffer_sz) {
    $buffer = [byte[]] @(,1) * $buffer_sz
    $recv = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
    $content = "";
    while (!$conn.cancellation_token_src.Token.IsCancellationRequested) {
      if ($conn.websocket.State -eq 'Closed') { break }
      <# Maybe allow for keyboard interrupts
      if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.key -eq "C" -and $key.modifiers -eq "Control") { break }
      }
      #>
      [System.Net.WebSockets.WebSocketReceiveResult] $res = ( await $conn.websocket.ReceiveAsync($recv, $conn.cancellation_token_src.Token))
      $recv.Array[0..($res.Count - 1)] | ForEach-Object { $content += [char]$_ }
      if($res.EndOfMessage) {
        break;
      }
      if ($res.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
        await $conn.websocket.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, [string]::Empty, $conn.cancellation_token_src.Token);
      }
    }
    return $content
  }
}

class WebSocketClient {

  $websockets = $null

  WebSocketClient() {
    $this.websockets = (New-Object System.Collections.ArrayList);
    $this.recvJobs = (New-Object System.Collections.ArrayList);
  }
  [bool] ValidateSocketId([int] $SocketId) {
    try {
      if ($SocketId -le $this.websockets.Count - 1){
        return $true
      }
      else {
        throw [InvalidWebSocketIdException]::new("$SocketId >= $($this.websockets.Count - 1)","$($_.StackTrace)")
      }
    }
    catch [InvalidWebSocketIdException] {
      <#Do this if a terminating exception happens#>
      Write-Output $_.Exception.additionalData
      # This will produce the error message: Didn't catch it the second time
      #throw [InvalidWebSocketIdException]::new("InvalidWebSocketIdException", "Invalid Id: $id")
      return $false
    }
  }
  [WebSocketClientConnectStatus] ConnectWebsocket([string] $uri) {
    $ret = [WebSocketClientConnectStatus]@{
      SocketId = -1
      Uri = $uri
      Status = 'Disconnected'
    }
    $websocket_connection = [WebSocketClientConnection]::new($uri)
    if([WebSocketClientConnection]::isOpen($websocket_connection)) {
      $this.websockets.add($websocket_connection)
      $ret.Uri = $uri
      $ret.SocketId = $this.websockets.Count - 1
      $ret.Status = "Connected"
    }
    return $ret
  }
  [WebSocketClientState] GetWebSocketState([int] $SocketId = 0) {
    $ret = [WebSocketClientState]@{
      SocketId = -1
      State = 'Invalid'
    }
    if ($this.ValidateSocketId($SocketId)) {
      $ret.SocketId = $SocketId
      $ret.State = [WebSocketClientConnection]::getState($this.websockets[$SocketId])
    }
    return $ret
  }
  [WebSocketClientSendMsgStatus] SendMessage([string]$message, [int] $SocketId = 0){
    $ret = [WebSocketClientSendMsgStatus]@{
      SocketId = -1
      Status = 'Failure'
    }
    if ($this.ValidateSocketId($SocketId)) {
      if (await ([WebSocketClientConnection]::sendMessage($this.websockets[$SocketId], $message))) {
        $ret.SocketId = $SocketId
        $ret.Status = 'Success'
      }
    }
    return $ret
  }
  [WebSocketClientRecvMsgStatus] ReceiveMessage([int] $SocketId = 0, [int]$buffer_sz) {
    $ret = [WebSocketClientRecvMsgStatus]@{
      SocketId = -1
      Status = 'Failure'
      Msg =  'Invalid'
    }
    if ($this.ValidateSocketId($SocketId)) {
      $ret.SocketId = $SocketId
      $ret.Status = 'Success'
      $ret.Msg = [WebSocketClientConnection]::receiveMessage($this.websockets[$SocketId], $buffer_sz)
    }
    return $ret
  }
  [void] DisconnectWebsocket($SocketId = 0) {
    if ($this.ValidateSocketId($SocketId)) {
      [WebsocketClientConnection]::disconnect($this.websockets[$SocketId])
    }
  }
}
Function New-WebSocketClient {
  return [WebSocketClient]::new()
}

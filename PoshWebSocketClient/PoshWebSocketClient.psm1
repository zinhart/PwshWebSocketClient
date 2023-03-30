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
    [string]$Uri,
    [Parameter(Mandatory=$false)]
    [int]$id = 0
  )
  if ($id -eq 0) { $ws_client.ConnectWebsocket($uri) }
  else { $ws_client.ConnectWebsocket($uri, $id) }
}

Function Send-Message {
  param(
    [Parameter(Mandatory=$true)]
    [string]$message,
    [Parameter(Mandatory=$false)]
    [int]$id = 0
  )
  if ($id -eq 0) { $ws_client.SendMessage($uri) }
  else { $ws_client.ReceiveMessage($uri, $id) }
}

Function Receive-Message {
  param(
    [Parameter(Mandatory=$false)]
    [int]$timeout = 5,
    [Parameter(Mandatory=$false)]
    [int]$buffer_sz = 1024,
    [Parameter(Mandatory=$false)]
    [int]$id = 0
  )
  return $ws_client.ReceiveMessage($id, $timeout, $buffer_sz)
}

Function Disconnect-Websocket {
  param(
    [Parameter(Mandatory=$false)]
    [int]$id = 0
  )
}

Function Test-Websocket {
 param(
  [Parameter(Mandatory=$false)]
  [int]$id = 0
  ) 
}
Export-ModuleMember Connect-Websocket,Test-Websocket,Disconnect-Websocket,Send-Message,Receive-Message
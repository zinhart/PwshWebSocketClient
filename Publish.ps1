# This assumes you are running PowerShell 5

# Parameters for publishing the module
$ModuleName='PwshWebSocketClient'
$Path = ".\$ModuleName"
$PublishParams = @{
    NuGetApiKey = Get-Content .env # Swap this out with your API key
    Path = $Path
    ProjectUri = "https://github.com/zinhart/$ModuleName"
    Tags = @('Websockets', 'API' )
}

# We install and run PSScriptAnalyzer against the module to make sure it's not failing any tests
#
Invoke-ScriptAnalyzer -Path $Path

# ScriptAnalyzer passed! Let's publish
Publish-Module @PublishParams

# The module is now listed on the PowerShell Gallery
Find-Module $ModuleName
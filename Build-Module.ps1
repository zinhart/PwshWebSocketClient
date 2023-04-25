param(
  [Parameter(Mandatory=$true)]
  [string]$ModuleName,
  [Parameter(Mandatory=$true)]
  [string]$Author,
  [Parameter(Mandatory=$false)]
  [string]$Path = '.\',
  [Parameter(Mandatory=$false)]
  [string]$Description = '',
  [Parameter(Mandatory=$false)]
  [double]$PowershellVersion = 5.0 
)
<#
$Path = 'C:\sc\PSStackExchange'
$ModuleName = 'PSStackExchange'
$Author = 'RamblingCookieMonster'
$Description = 'PowerShell module to query the StackExchange API'
#>
# Create the module and private function directories
mkdir $Path\$ModuleName
mkdir $Path\$ModuleName\Private
mkdir $Path\$ModuleName\Public
mkdir $Path\$ModuleName\en-US # For about_Help files
mkdir $Path\Tests

#Create the module and related files
New-Item "$Path\$ModuleName\$ModuleName.psm1" -ItemType File
New-Item "$Path\$ModuleName\$ModuleName.Format.ps1xml" -ItemType File
New-Item "$Path\$ModuleName\en-US\about_$ModuleName.help.txt" -ItemType File
New-Item "$Path\Tests\$ModuleName.Tests.ps1" -ItemType File
New-ModuleManifest -Path $Path\$ModuleName\$ModuleName.psd1 `
                   -RootModule $ModuleName.psm1 `
                   -Description $Description `
                   -PowerShellVersion $PSVersion `
                   -Author $Author `
                   -FormatsToProcess "$ModuleName.Format.ps1xml"

# Copy the public/exported functions into the public folder, private functions into private folder
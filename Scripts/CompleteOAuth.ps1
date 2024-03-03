[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $ClientId,

    [Parameter(Mandatory=$true)]
    [string]
    $ClientSecret,

    [Parameter(Mandatory=$true)]
    [string]
    $RedirectUri,

    [Parameter(Mandatory=$false)]
    [string]
    $scope = "openid profile offline_access email User.Read User.ReadBasic.All Mail.Read"
)

# Download the ZIP file to the current directory
Invoke-WebRequest -Uri "https://github.com/dafthack/GraphRunner/archive/refs/heads/main.zip" -OutFile ".\GraphRunner-main.zip"
Expand-Archive -Path ".\GraphRunner-main.zip" -DestinationPath "." -Force

Set-Location -Path ".\GraphRunner-main\GraphRunner-main"

# Dot-source the GraphRunner.ps1 script
. .\GraphRunner.ps1

Invoke-AutoOAuthFlow -ClientId $ClientId -ClientSecret $ClientSecret -RedirectUri $RedirectUri -scope "$scope"
[CmdletBinding()]
param (
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$targetUser,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$linkTemplate,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$templateLink,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$firstUser,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$messageContent,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$subject,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$Token,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$template,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$ReplyUrl,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$AppName,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$Scope,
    [Parameter()]
    [switch]$install,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$azureHound = $false,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$recon = $false,   
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$azureAd = $false,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$persistence = $false,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$GraphRecon = $false         
)

# Clean up previous runs tokens and output files
.\Clean.ps1

# Install and Import
if($install){
    Write-Output "Installing modules"
    .\Scripts\Install.ps1
}
Write-Output "Importing modules"
.\Scripts\Import.ps1

# Initialize an empty argument list
$argumentList = @()

if ($targetUser) {
    $argumentList += "-targetUser `"$targetUser`""
}

if ($subject) {
    $argumentList += "-subject `"$subject`""
}

if ($template) {
    $argumentList += "-template `"$linkTemplate`""
}

Start-Process -FilePath "powershell.exe" -ArgumentList "-File .\LinkPhish.ps1 $($argumentList -join ' ')" -RedirectStandardOutput "output.txt"


[CmdletBinding()]
param (
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$refreshToken,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$domain
)


# Assuming $response and $domain are already set
# $tok = $response.refresh_token
$tok = $refreshToken

# Azure hound bins
# Determine the operating system using the OS environment variable
$osType = $env:OS
$binaryName = ""
$exePath = ""

if ($osType -eq "Windows_NT") {
    $os = "windows"
    Write-Output "Detected Windows OS."
    $binaryName = "azurehound-windows-amd64.zip"
    $exePath = ".\azurehound.exe"
} else {
    $os = "linux"
    Write-Output "Detected Linux OS."
    $binaryName = "azurehound-linux-amd64.zip"
    $exePath = "./azurehound"
}

# Define the output path
$outputZipFile = $binaryName

# Check if the binary already exists and delete it if it does
if (Test-Path -Path $outputZipFile) {
    Remove-Item -Path $outputZipFile -Force
    Write-Output "Existing AzureHound binary deleted."
}

# Download the correct AzureHound binary for the detected OS
$downloadUrl = "https://github.com/BloodHoundAD/AzureHound/releases/latest/download/$binaryName"
Invoke-WebRequest -Uri $downloadUrl -OutFile $outputZipFile
Write-Output "Downloaded the AzureHound binary for $os."

# Expand the downloaded zip file
Expand-Archive -LiteralPath $outputZipFile -DestinationPath . -Force
Write-Output "Extracted the AzureHound binary."

# Clean up the zip file
Remove-Item -Path $outputZipFile -Force
Write-Output "Cleaned up the downloaded zip file."

# Run AzureHound with the specified parameters
Write-Output "Running Azurehound."
& $exePath -r $tok list --tenant $domain -o azurehound.json
Write-Output "AzureHound command executed for $os."
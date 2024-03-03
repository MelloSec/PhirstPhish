[CmdletBinding()]
param (
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$accessToken,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$refreshToken,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$graphRecon,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]$graphPersistence,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$firstUser,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$graphAppName
)

# Import GraphRunner Module
Import-Module .\GraphRunner.ps1 -Force

# Import Tokens
Invoke-ImportTokens -AccessToken $accessToken -RefreshToken $refreshToken

# Invoke-RefreshGraphTokens -refreshToken $response.refresh_token -tenatId 

Invoke-GraphRunner -Tokens $tokens

# Invoke-InjectOAuthApp  -AppName $graphAppName -ReplyUrl "http://localhost:10000" -scope "op backdoor" -Tokens $tokens

# Invoke-AutoOAuthFlow -ClientId "13483541-1337-4a13-1234-0123456789ABC" -ClientSecret "v-Q8Q~fEXAMPLEEXAMPLEDsmKpQw_Wwd57-albMZ" -RedirectUri "http://localhost:10000" -scope "openid profile offline_access email User.Read User.ReadBasic.All Mail.Read"

# .\GrapRunnerModule.ps1 -accessToken $response.access_token -refreshToken $response.refresh_token
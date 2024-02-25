# Import GraphRunner Module

# Invoke-ImportTokens
Maybe we use this one, maybe use the refresh

# Invoke-RefreshGraphTokens -refreshToken $response.refresh_token -tenatId 
Take the refresh token, refresh to whatever we need for graphrunner

# invoke-GraphRunner
 -graph-recon switch, runs the default GraphRunner enumeration

# Invoke-InjectOAuthApp 
-graph-persistence switch, injects an app registration


# Ivoke-ImportTokens
# function Invoke-ImportTokens {
#     [cmdletbinding()]
#     Param([Parameter(Mandatory=$false)]
#     [String]$AccessToken,
#     [Parameter(Mandatory=$false)]
#     [String]$RefreshToken
#     )
#     $global:tokens = $null
#     $global:tokens = @(
#         [pscustomobject]@{access_token=$AccessToken;refresh_token=$RefreshToken}
#     )
# }
function Import-TokenTacticsResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$response
    )

    try {
        Write-Host -ForegroundColor Yellow "[*] Trying to import tokens from TokenTactics response."

        if ($response) {
            $tokenPayload = $response.access_token.Split(".")[1].Replace('-', '+').Replace('_', '/')
            while ($tokenPayload.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenPayload += "=" }
            $tokenByteArray = [System.Convert]::FromBase64String($tokenPayload)
            $tokenArray = [System.Text.Encoding]::ASCII.GetString($tokenByteArray)
            $tokobj = $tokenArray | ConvertFrom-Json
            $global:tenantid = $tokobj.tid
            Write-Output "Decoded JWT payload:"
            $tokobj
            Write-Host -ForegroundColor Green '[*] Successful authentication. Access and refresh tokens have been written to the global $tokens variable. To use them with other GraphRunner modules use the Tokens flag (Example. Invoke-DumpApps -Tokens $tokens)'
            $baseDate = Get-Date -date "01-01-1970"
            $tokenExpire = $baseDate.AddSeconds($tokobj.exp).ToLocalTime()
            Write-Host -ForegroundColor Yellow "[!] Your access token is set to expire on: $tokenExpire"
        }
    } catch {
        $details = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Output $details.error
    }
    # Assign the extracted token object to the global variable
    $global:tokens = $tokobj
}

# Example of how to call this function:
# $response = <your_response_object_here>
Import-TokenTacticsResponse -response $response

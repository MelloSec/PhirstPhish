param (
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$code,

    [Parameter(ValueFromPipeline=$true)]
    [string]$template
)

# Define the source and destination file paths based on the template
if($template -eq "bluebeam"){
    $sourceFile = ".\Templates\BluebeamShareHTML.htm"
    $destinationFile = ".\Templates\bluebeam.htm"
}
elseif($template -eq "chatgpt"){
    $sourceFile = ".\Templates\chatGPTHTML.html"
    $destinationFile = ".\Templates\chatgpt.htm"
}
elseif($template -eq "blonde"){
    $sourceFile = ".\Templates\blondeHTML.html"
    $destinationFile = ".\Templates\blonde.htm"
}
elseif($template -eq "fondo"){
    $sourceFile = ".\Templates\fondoHTML.html"
    $destinationFile = ".\Templates\fondo.htm"
}
elseif($template -eq "bbb"){
    $sourceFile = ".\Templates\bbbHTML.htm"
    $destinationFile = ".\Templates\bbb.htm"
}
elseif($template -eq "adobe"){
    $sourceFile = ".\Templates\adobeHTML.htm"
    $destinationFile = ".\Templates\adobe.htm"
}
else{
    # Default to bluebeam if no template is specified
    $sourceFile = ".\Templates\BluebeamShareHTML.htm"
    $destinationFile = ".\Templates\bluebeam.htm"
}


Write-Output "$template selected."
Copy-Item -Path $sourceFile -Destination $destinationFile -Force

# Read in the file
$content = Get-Content -Path $destinationFile -Raw

# Replace the placeholder with the code
$updatedContent = $content -replace "\(\(\(VERIFICATION\)\)\)", $code

# Write the updated content back to the file
Set-Content -Path $destinationFile -Value $updatedContent




# param (
#     [string]$code
# )

# # Define the source and destination file paths
# $sourceFile = "BluebeamShareHTML.htm"
# $destinationFile = "bluebeam.htm"

# # Copy the source file to the destination
# Copy-Item -Path $sourceFile -Destination $destinationFile

# # Read the content of the copied file
# $content = Get-Content -Path $destinationFile -Raw

# # Replace the placeholder with the code
# $updatedContent = $content -replace "\(\(\(VERIFICATION\)\)\)", $code

# # Write the updated content back to the file
# Set-Content -Path $destinationFile -Value $updatedContent

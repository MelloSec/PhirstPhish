param (
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$code,

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$template
)

# arg parse and define the source and destination file paths
if($template = "bluebeam"){
    $sourceFile = ".\Templates\BluebeamShareHTML.htm"
    $destinationFile = ".\Templates\bluebeam.htm"
    }

if($template = "chatgpt"){
    $sourceFile = ".\Templates\chatGPTHTML.htm"
    $destinationFile = ".\Templates\chatgpt.htm"
    }

if($template = "blonde"){
    $sourceFile = ".\Templates\blondeHTML.html"
    $destinationFile = ".\Templates\blonde.html"
    }
    
if($template = "fondo"){
    $sourceFile = ".\Templates\fondoHTML.html"
    $destinationFile = ".\Templates\fondo.html"
    }
    
if(!($template)){
    $sourceFile = ".\Templates\BluebeamShareHTML.htm"
    $destinationFile = ".\Templates\bluebeam.htm"
    }       

Copy-Item -Path $sourceFile -Destination $destinationFile

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

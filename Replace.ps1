param (
    [string]$code
)

# Define the source and destination file paths
$sourceFile = "BluebeamShareHTML.htm"
$destinationFile = "bluebeam.htm"

# Copy the source file to the destination
Copy-Item -Path $sourceFile -Destination $destinationFile

# Read the content of the copied file
$content = Get-Content -Path $destinationFile -Raw

# Replace the placeholder with the code
$updatedContent = $content -replace "\(\(\(VERIFICATION\)\)\)", $code

# Write the updated content back to the file
Set-Content -Path $destinationFile -Value $updatedContent

# Check if AADInternals module is available
if (-not (Get-Module -Name AADInternals -ListAvailable)) {
    # Install the AADInternals module if it's not available
    Install-Module AADInternals -Force
    Write-Output "AADInternals module has been installed."
}

# Import the AADInternals module
Import-Module AADInternals -Force
Write-Output "AADInternals module has been imported."

# Check if TokenTactics module is available
if (!(Get-Module -ListAvailable -Name TokenTactics)) {
    # Download the latest TokenTactics zip if the module is not available
    Write-Output "TokenTactics not found, downloading latest version into current working directory."
    Invoke-WebRequest -Uri https://github.com/mellonaut/TokenTactics/archive/refs/heads/main.zip -OutFile tokentactics.zip

    if (Test-Path -Path .\tokentactics) {
        Remove-Item -Path .\tokentactics -Recurse -Force
    }

    Expand-Archive -LiteralPath .\tokentactics.zip -DestinationPath .\tokentactics -Force
    Get-ChildItem -Path .\tokentactics\tokentactics-main\* -Recurse | Move-Item -Destination .\tokentactics -Force
    Remove-Item -Path .\tokentactics\tokentactics-main -Recurse -Force
}

# Import or re-import the TokenTactics module
Import-Module .\tokentactics\TokenTactics.psd1 -Force
Write-Output "TokenTactics module has been imported."
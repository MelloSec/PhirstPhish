# Import the AADInternals module
Import-Module AADInternals -Force
Write-Output "AADInternals module has been imported."

# Import or re-import the TokenTactics module
Import-Module .\tokentactics\TokenTactics.psd1 -Force
Write-Output "TokenTactics module has been imported."
# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

Add-Type -AssemblyName System.Windows.Forms

# select PEM certificate
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Filter = "PEM files (*.pem)|*.pem"
$dialog.Title = "Select a PEM Certificate File"

$result = $dialog.ShowDialog()
if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "`r`nAborted.`r`n"
    exit
}

$cert = $dialog.FileName

# copy PEM certificate to appdata\roaming
$destination = Join-Path $env:APPDATA (Split-Path $cert -Leaf)

try {
    Copy-Item -Path $cert -Destination $destination -Force
} catch {
    Write-Host "`r`nError! Could not copy certificate. Exiting...`r`n" -ForegroundColor Red
    exit
}

# confirm if copy was successful
if (-Not (Test-Path $destination)) {
    Write-Host "`r`nError encountered during copy process. Exiting...`r`n" -ForegroundColor Red
    exit
}

# update $cert variable
$cert = $destination

# check if 'git' command exists
if (-Not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "`r`nError! The 'git' command not found. Please install Git and try again. Exiting..." -ForegroundColor Red
    exit
}

# configure git to use certificate
try {
    git config --global http.sslcainfo "$cert"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`r`nCertificate pinned successfully!`r`n" -ForegroundColor Green
    } else {
        Write-Host "`r`nFailed to configure Git. Exit code: $LASTEXITCODE`r`n" -ForegroundColor Red
        exit
    }
} catch {
    Write-Host "`r`nAn error occurred while configuring Git. Exiting script.`r`n" -ForegroundColor Red
    exit
}

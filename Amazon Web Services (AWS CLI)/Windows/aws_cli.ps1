# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`nScript requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

# check for 'aws' command
try {
    aws --version > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "`r`nAWS CLI not installed / not found in PATH environment. Exiting...`r`n"
    }
} catch {
    Write-Host "AWS CLI not installed / not found in PATH environment. Please install it and try again." -ForegroundColor Red
    exit 1
}

# select PEM certificate
Add-Type -AssemblyName System.Windows.Forms
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Filter = "PEM files (*.pem)|*.pem"
$OpenFileDialog.Title = "Select PEM Certificate File"

$dialogResult = $OpenFileDialog.ShowDialog()
if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "`r`nAborted.`r`n" -ForegroundColor Yellow
    exit 0
}

$cert = $OpenFileDialog.FileName

# set AWS config value
try {
    aws configure set default.ca_bundle "$cert"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to set AWS certificate bundle."
    } else {
        Write-Host "AWS certificate bundle set successfully." -ForegroundColor Green
    }
} catch {
    Write-Host "Error setting AWS CA bundle: $_" -ForegroundColor Red
    exit 1
}

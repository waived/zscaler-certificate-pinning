# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

# confirm npm command exists
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "`r`nCommand NPM was not found. Exiting...`r`n" -ForegroundColor Red
    exit 1
}

# select PEM certificate
Add-Type -AssemblyName System.Windows.Forms
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Filter = "PEM files (*.pem)|*.pem"
$openFileDialog.Title = "Select a PEM Certificate File"

$dialogResult = $openFileDialog.ShowDialog()

if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "`r`nAborted.`r`n"
    exit 0
}

$cert = $openFileDialog.FileName

# pin certificate
try {
    npm config set cafile "$cert" 2>&1 | Out-Null
} catch {
    Write-Host "`r`nUnable to pin certificate to NodeJS. Exiting...`r`n" -ForegroundColor Red
    exit 1
}

# verify/confirm pinning process
$npmConfig = npm config get cafile
if ($npmConfig -ne $cert) {
	$response = Read-Host "`r`nUnable to verify if pinning was successful. Continue? [y/n]: " -ForegroundColor Yellow
    
	if (-not $response -match '^[Yy]') {
	    exit 0
	}
}

# set environmental variable
try {
    [System.Environment]::SetEnvironmentVariable("NODE_EXTRA_CA_CERTS", $cert, "Machine")

    # validate
    $check = [System.Environment]::GetEnvironmentVariable("NODE_EXTRA_CA_CERTS", "Machine")
    if ($check -eq $cert) {
        Write-Host "Certificate pinned successfully. A reboot is required for the changes to take effect."
    } else {
        Write-Error "Failed to pin certificate."
        exit 1
    }
} catch {
    Write-Error "An error occurred: $_"
    exit 1
}

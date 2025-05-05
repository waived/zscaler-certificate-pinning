# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
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

# set environmental variable
try {
    [System.Environment]::SetEnvironmentVariable("SSL_CERT_FILE", $cert, "Machine")

    # validate
    $check = [System.Environment]::GetEnvironmentVariable("SSL_CERT_FILE", "Machine")
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

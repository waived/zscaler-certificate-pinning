# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

# select pem cert
Add-Type -AssemblyName System.Windows.Forms

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Filter = "Certificate files (*.pem)|*.pem"
$OpenFileDialog.Title = "Select a PEM file"

$dialogResult = $OpenFileDialog.ShowDialog()

if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "Operation cancelled by user."
    exit
}

$pem_file = $OpenFileDialog.FileName

# set environmental variable
try {
    [System.Environment]::SetEnvironmentVariable("REQUESTS_CA_BUNDLE", $pem_file, "Machine")

    # validate
    $check = [System.Environment]::GetEnvironmentVariable("REQUESTS_CA_BUNDLE", "Machine")
    if ($check -eq $pem_file) {
        Write-Host "Certificate pinned successfully. A reboot is required for the changes to take effect."
    } else {
        Write-Error "Failed to pin certificate."
        exit 1
    }
} catch {
    Write-Error "An error occurred: $_"
    exit 1
}

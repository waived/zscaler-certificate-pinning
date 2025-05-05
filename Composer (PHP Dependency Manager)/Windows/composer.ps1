# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

# select crt cert
Add-Type -AssemblyName System.Windows.Forms

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Filter = "Certificate files (*.crt)|*.crt"
$OpenFileDialog.Title = "Select a CRT file"

$dialogResult = $OpenFileDialog.ShowDialog()

if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "Operation cancelled by user."
    exit
}

$crt_file = $OpenFileDialog.FileName

# set environmental variable
try {
    [System.Environment]::SetEnvironmentVariable("openssl.cafile", $crt_file, "Machine")

    # validate
    $check = [System.Environment]::GetEnvironmentVariable("openssl.cafile", "Machine")
    if ($check -eq $crt_file) {
        Write-Host "Certificate pinned successfully. A reboot is required for the changes to take effect."
    } else {
        Write-Error "Failed to pin certificate."
        exit 1
    }
} catch {
    Write-Error "An error occurred: $_"
    exit 1
}

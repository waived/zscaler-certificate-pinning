# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

# check if gcloud is installed
if (-not (Get-Command "gcloud" -ErrorAction SilentlyContinue)) {
    Write-Host "`r`nError. The Google Cloud SDK appears not to be installed/missing. Exiting...`r`n" -ForegroundColor Red
    exit 1
}

# select PEM certificate
Add-Type -AssemblyName System.Windows.Forms
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Filter = "PEM Files (*.pem)|*.pem"
$dialog.Title = "Select a PEM Certificate File"

if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "`r`nNo certificate selected. Exiting.`r`n" -ForegroundColor Yellow
    exit 0
}

$cert = $dialog.FileName

# import certificate
try {
    & gcloud config set core/custom_ca_certs_file "$cert"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`r`nFailed to import certificate to the Google-Cloud configuration.`r`n." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "`r`nSuccessfully imported certificate to the Google-Cloud configuration.`r`n" -ForegroundColor Green
    }
} catch {
    Write-Host "`r`nUnexpected error occurred: $_`r`n" -ForegroundColor Red
    exit 1
}

# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

Add-Type -AssemblyName System.Windows.Forms

# select CRT certificate
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Filter = "Certificate files (*.crt)|*.crt"
$OpenFileDialog.Title = "Select a Certificate (.crt) File"

$DialogResult = $OpenFileDialog.ShowDialog()

if ($DialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "`r`nAborted.`r`n" -ForegroundColor Yellow
    exit
}

$cert = $OpenFileDialog.FileName

# import certificate
try {
    Import-Certificate -FilePath $cert -CertStoreLocation "Cert:\LocalMachine\Root" -ErrorAction Stop
    Write-Host "`r`nCertificate imported successfully.`r`n" -ForegroundColor Green
}
catch {
    Write-Error "`r`nCould not import certificate. $($_.Exception.Message)`r`n" -ForegroundColor Red
}



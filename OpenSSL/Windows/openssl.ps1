# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

$root = $env:HOMEDRIVE

# locate OpenSSL directory
$searchPaths = @("$root\Program Files\", "$root\Program Files (x86)\")
$openSSLDirs = @()

foreach ($path in $searchPaths) {
    $dirs = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "OpenSSL*" }
    $openSSLDirs += $dirs.FullName
}

if ($openSSLDirs.Count -eq 0) {
    Write-Host "`r`nOpenSSL installation directory not found. Exiting...`r`n" -ForegroundColor Red
    exit
}

# locate openssl.exe
$openssl = $null

foreach ($dir in $openSSLDirs) {
    $opensslPath = Get-ChildItem -Path $dir -Recurse -Filter "openssl.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($opensslPath) {
        $openssl = $opensslPath.FullName
        break
    }
}

if (-not $openssl) {
    Write-Host "`r`nThe command 'openssl' not found in OpenSSL directory.`r`n" -ForegroundColor Red
    exit
}

# locate sub-directory "certs" in the OpenSSL directory
$baseOpenSSLDir = Split-Path -Path $openssl -Parent
do {
    $cert_dir = Join-Path $baseOpenSSLDir "certs"
    if (Test-Path $cert_dir) { break }
    $baseOpenSSLDir = Split-Path $baseOpenSSLDir -Parent
} while ($baseOpenSSLDir -ne "")

if (-not (Test-Path $cert_dir)) {
    Write-Host "`r`nUnable to locate the 'certs' sub-directory.`r`n" -ForegroundColor Red
    exit
}

# select PEM certificate
Add-Type -AssemblyName System.Windows.Forms
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Filter = "PEM Files (*.pem)|*.pem"
$OpenFileDialog.Title = "Select a PEM Certificate File"

if ($OpenFileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "`r`nAborted.`r`n"
    exit
}

$cert = $OpenFileDialog.FileName

# copy PEM certificate to certs directory
try {
    $destCert = Join-Path $cert_dir (Split-Path $cert -Leaf)
    Copy-Item -Path $cert -Destination $destCert -Force
    $cert = $destCert
} catch {
    Write-Host "`r`nFailed to import the certificate.`r`n" -ForegroundColor Red
    exit
}

# calculate certificate hash and create matching hash-file
try {
    $hash = & $openssl x509 -noout -hash -in $cert
    $hashFileName = "$hash.0"
    $targetPath = Join-Path $cert_dir $hashFileName
    Copy-Item -Path $cert -Destination $targetPath -Force

    if (-not (Test-Path $targetPath)) {
        Write-Host "`r`nFailed to matching hash-file on behalf of the certificate`r`n." -ForegroundColor Red
    } else {
        Write-Host "`r`nCertificate pinned successfully!`r`n" -ForegroundColor Green
    }
} catch {
    Write-Host "Critical error: $_" -ForegroundColor Red
    exit
}

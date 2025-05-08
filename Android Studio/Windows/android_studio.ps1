# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

Add-Type -AssemblyName System.Windows.Forms

$root = $env:HOMEDRIVE

# check for for Android installation directory
$androidDirs = @("$root\Program Files\Android", "$root\Program Files (x86)\Android")
$AndroidStudio = $null

foreach ($dir in $androidDirs) {
    if (Test-Path $dir) {
        $AndroidStudio = $dir
        break
    }
}

if (-not $AndroidStudio) {
    Write-Error "`r`nAndroid directory does not appear to be installed.`r`n" -ForegroundColor Red
    exit 1
}

# locate 'cacerts' binary
$keystore = Get-ChildItem -Path $AndroidStudio -Recurse -Filter "cacerts" -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1

if (-not $keystore) {
    Write-Error "`r`nJava 'cacerts' keystore binary not found in Android Studio directory.`r`n" -ForegroundColor Red
    exit 1
}

$keystore = $keystore.FullName

# locate 'keytool' executable
$keytool = Get-ChildItem -Path $AndroidStudio -Recurse -Filter "keytool.exe" -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1

if (-not $keytool) {
    Write-Error "`r`nJava 'keytool' executable not found in Android Studio directory.`r`n" -ForegroundColor Red
    exit 1
}

$keytool = $keytool.FullName

# select Root CA certificate
[System.Windows.Forms.MessageBox]::Show("Press Enter to select the Root CA certificate")
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Filter = "Certificate files (*.*)|*.*"
$openFileDialog.Title = "Select Root CA Certificate"

if ($openFileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "`r`nAborted.`r`n" -ForegroundColor Yellow
    exit 1
}

$RootCert = $openFileDialog.FileName

# select Intermediate CA certificate
[System.Windows.Forms.MessageBox]::Show("Press Enter to select the Intermediate CA certificate")
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Filter = "Certificate files (*.*)|*.*"
$openFileDialog.Title = "Select Intermediate CA Certificate"

if ($openFileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "`r`nAborted.`r`n" -ForegroundColor Yellow
    exit 1
}

$InterCert = $openFileDialog.FileName

# import Root CA certificate
$importRoot = & "$keytool" -import -trustcacerts -file "$RootCert" -alias AndroidStudioRootCA -keystore "$keystore"

if ($LASTEXITCODE -ne 0) {
    Write-Error "`r`nFailed to import Root CA certificate.`r`n" -ForegroundColor Red
    exit 1
}

# import Intermediate CA certificate
$importInter = & "$keytool" -import -trustcacerts -file "$InterCert" -alias AndroidStudioIntermediateCA -keystore "$keystore"

if ($LASTEXITCODE -ne 0) {
    Write-Error "`r`nFailed to import Intermediate CA certificate.`r`n" -ForegroundColor Red
    exit 1
}

Write-Host "`r`nCertificates successfully imported into the keystore.`r`n" -ForegroundColor Green

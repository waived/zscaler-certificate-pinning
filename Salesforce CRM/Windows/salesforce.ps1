# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

Clear-Host
$root = $env:HOMEDRIVE

# check if Zulu JDK exists
$zuluPaths = @(
    "$root\Program Files\Zulu",
    "$root\Program Files (x86)\Zulu"
)

$Zulu = $zuluPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $Zulu) {
    Write-Host "`r`nSalesforce dependency Zulu JDK installation directory not found. Exiting...`r`n" -ForegroundColor Red
    exit 1
}

# locate 'cacerts' file recursively
$keystore = Get-ChildItem -Path $Zulu -Recurse -Filter "cacerts" -File -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $keystore) {
    Write-Host "`r`nSalesforce dependency 'cacerts' binary not found. Exiting...`r`n" -ForegroundColor Red
    exit 1
}

# locate 'keytool.exe' executable recursively
$keytool = Get-ChildItem -Path $Zulu -Recurse -Filter "keytool.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $keytool) {
    Write-Host "`r`nSalesforce dependency 'keytool.exe' executable not found. Exiting...`r`n" -ForegroundColor Red
    exit 1
}

# select PEM certificate
Add-Type -AssemblyName System.Windows.Forms
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Filter = "PEM Files (*.pem)|*.pem"
$OpenFileDialog.Title = "Select PEM Certificate File"

if ($OpenFileDialog.ShowDialog() -ne "OK") {
    Write-Host "`r`nNo certificate selected. Exiting...`r`n" -ForegroundColor Yellow
    exit 1
}

$cert = $OpenFileDialog.FileName

# prompt user for keystore password
$keystorePasswordPlain = Read-Host -Prompt "Enter the keystore password"
$escapedPassword = $keystorePasswordPlain -replace '"', '\"'

# build import command
$keytoolArgs = @(
    "-import",
    "-trustcacerts",
    "-alias", "Java_Generic_Root_CA",
    "-file", "`"$cert`"",
    "-keystore", "`"$($keystore.FullName)`"",
    "-storepass", "`"$escapedPassword`""
)

& $keytool.FullName @keytoolArgs
if ($LASTEXITCODE -eq 0) {
    Write-Host "`r`nCertificate successfully pinned to keystore." -ForegroundColor Green
} else {
    Write-Host "`r`nError. Certificate pinning failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

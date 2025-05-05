# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

Clear-Host
$root = $env:HOMEDRIVE
$home_eclipse = Join-Path $env:USERPROFILE ".eclipse"

# select DER certificate
Add-Type -AssemblyName System.Windows.Forms
$ofd = New-Object System.Windows.Forms.OpenFileDialog
$ofd.Filter = "DER files (*.der)|*.der"
$ofd.Title = "Select a .DER File"
$ofd.Multiselect = $false

$dialogResult = $ofd.ShowDialog()
if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
    [System.Windows.Forms.MessageBox]::Show("No file selected. Exiting...", "Cancelled", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    exit
}

$cert = $ofd.FileName

# locate cacerts keystore
$paths = @(
    $home_eclipse,
    "$root\Program Files\Eclipse Adoptum\",
    "$root\Program Files (x86)\Eclipse Adoptum\"
)

$keystore = $null
foreach ($path in $paths) {
    if (Test-Path $path) {
        $keystoreFile = Get-ChildItem -Path $path -Recurse -Filter "cacerts" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($keystoreFile) {
            $keystore = $keystoreFile.FullName
            break
        }
    }
}

if (-not $keystore) {
    Write-Host "`r`n    Java 'cacerts' binary not found/unavailable. Exiting...`r`n" -ForegroundColor Red
    exit 1
}

# locate keytool.exe
$possiblePaths = @(
    $home_eclipse,
    "$root\Program Files\Eclipse Adoptum\",
    "$root\Program Files (x86)\Eclipse Adoptum\"
)

$keytool = Get-ChildItem -Path $possiblePaths -Recurse -Filter "keytool.exe" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '\\bin\\keytool\.exe$' } |
    Select-Object -First 1

if (-not $keytool) {
    Write-Host "`r`n    Java 'keytool' command not found. Exiting...`r`n" -ForegroundColor Red
    exit 1
}

# prompt user for keystore password
$keystorePasswordPlain = Read-Host -Prompt "Enter the keystore password"
$escapedPassword = $keystorePasswordPlain -replace '"', '\"'

# build import command
$keytoolArgs = @(
    "-import",
    "-trustcacerts",
    "-alias", "Java_Generic_Root_CA",
    "-file", "`"$cert`"",
    "-keystore", "`"$keystore`"",
    "-storepass", "`"$escapedPassword`""
)

& $keytool.FullName @keytoolArgs
if ($LASTEXITCODE -eq 0) {
    Write-Host "`r`nCertificate successfully pinned to keystore." -ForegroundColor Green
} else {
    Write-Host "`r`nError. Certificate pinning failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

# build list command to verify
$listArgs = @(
    "-list",
    "-v",
    "-keystore", "`"$keystore`"",
    "-storepass", "`"$escapedPassword`""
)

Write-Host "`r`nVerifying keystore contents:`r`n"
& $keytool.FullName @listArgs
if ($LASTEXITCODE -eq 0) {
    Write-Host "`r`nKeystore contents listed successfully." -ForegroundColor Green
} else {
    Write-Host "`r`nError. Failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

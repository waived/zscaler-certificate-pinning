# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

Clear-Host
$root = $env:HOMEDRIVE

# Select PEM certificate
Add-Type -AssemblyName System.Windows.Forms
$ofd = New-Object System.Windows.Forms.OpenFileDialog
$ofd.Filter = "PEM files (*.pem)|*.pem"
$ofd.Title = "Select a .PEM File"
$ofd.Multiselect = $false

$dialogResult = $ofd.ShowDialog()
if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
    [System.Windows.Forms.MessageBox]::Show("No file selected. Exiting...", "Cancelled", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    exit
}

$pemFile = $ofd.FileName

# locate azure directory
$AzurePaths = @(
    "$root\Program Files\Microsoft SDKs\Azure\CLI2\Lib\site-packages\certifi",
    "$root\Program Files (x86)\Microsoft SDKs\Azure\CLI2\Lib\site-packages\certifi"
)

$Azure = $null
foreach ($path in $AzurePaths) {
    if (Test-Path $path) {
        $Azure = $path
        break
    }
}

if (-not $Azure) {
    Write-Host "`r`nAzure directory not found. Exiting...`r`n" -ForegroundColor Red
    exit
}

# delete existing .pem files
Get-ChildItem -Path $Azure -Filter *.pem -File -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item $_.FullName -Force
}

try {
    Copy-Item -Path $pemFile -Destination $Azure -Force -ErrorAction Stop
    Write-Host "`r`nCertificate successfully pinned.`r`n" -ForegroundColor Green
}
catch {
    Write-Host "`r`nError: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

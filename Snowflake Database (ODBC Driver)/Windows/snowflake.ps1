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

# locate Snowflake ODBC directory
$odbcPaths = @(
    "$root\Program Files\Snowflake ODBC Driver\etc",
    "$root\Program Files (x86)\Snowflake ODBC Driver\etc"
)

$ODBC = $null
foreach ($path in $odbcPaths) {
    if (Test-Path $path) {
        $ODBC = $path
        break
    }
}

if (-not $ODBC) {
    Write-Host "`r`n    Snowflake ODBC-Driver directory not found. Exiting...`r`n" -ForegroundColor Red
    exit
}

# delete existing .pem files
Get-ChildItem -Path $ODBC -Filter *.pem -File -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item $_.FullName -Force
}

try {
    Copy-Item -Path $pemFile -Destination $ODBC -Force -ErrorAction Stop
    Write-Host "`r`n    Certificate successfully pinned.`r`n" -ForegroundColor Green
}
catch {
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 1
}

# check for elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`r`n    Script requires admin elevation!`r`n" -ForegroundColor Red
    exit
}

Clear-Host

Add-Type -AssemblyName System.Windows.Forms

# function to select directory
function Select-FolderDialog {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq 'OK') {
        return $dialog.SelectedPath
    } else {
        Write-Host "Operation cancelled. Exiting..."
        exit
    }
}

# function to pull der file
function Select-FileDialog {
    param ($filter)
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = $filter
    if ($dialog.ShowDialog() -eq 'OK') {
        return $dialog.FileName
    } else {
        Write-Host "Operation cancelled. Exiting..."
        exit
    }
}

# select anypoint directory
Write-Host "Please select your Anypoint Studio working directory. Strike ENTER to select..."
Read-Host
$AnyPoint = Select-FolderDialog

# select der certificate
Write-Host "Please select your DER certificate. Strike ENTER to select..."
Read-Host
$cert = Select-FileDialog -filter "DER files (*.*)|*.*"

# search for keytool.exe command instance
$keytool = Get-ChildItem -Path $AnyPoint -Recurse -Filter "keytool.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $keytool) {
    Write-Host "keytool.exe not found in $AnyPoint. Exiting..."
    exit
}
$keytool = $keytool.FullName

# find any/all cacerts binary
$cacertList = Get-ChildItem -Path $AnyPoint -Recurse -Filter "cacerts" -File -ErrorAction SilentlyContinue

if ($cacertList.Count -eq 0) {
    Write-Host "No cacert files found in $AnyPoint. Exiting..."
    exit
}

# import certificate into each cacerts binary
for ($i = 0; $i -lt $cacertList.Count; $i++) {
    $cacertPath = $cacertList[$i].FullName
    $alias = "AnyPoint_$i"
    Write-Host "`nImporting certificate to $cacertPath with alias $alias..."
    
    $process = Start-Process -FilePath $keytool -ArgumentList "-import", "-trustcacerts", "-alias", $alias, "-file", "`"$cert`"", "-keystore", "`"$cacertPath`"", "-noprompt", "-storepass", "changeit" -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        Write-Host "Failed to import into $cacertPath (ExitCode: $($process.ExitCode))"
    } else {
        Write-Host "Successfully imported into $cacertPath"
    }
}

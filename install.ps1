# Installs the latest pitchside release (Windows, 64-bit).
$ErrorActionPreference = "Stop"

$repo = "josejmorales/pitchside-releases"
$asset = "pitchside-windows-x64.exe"
$dir = Join-Path $env:LOCALAPPDATA "pitchside"
$base = "https://github.com/$repo/releases/latest/download"
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("pitchside-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

try {
    Write-Host "Downloading pitchside..."
    Invoke-WebRequest "$base/$asset" -OutFile (Join-Path $tmp $asset) -UseBasicParsing
    Invoke-WebRequest "$base/SHA256SUMS" -OutFile (Join-Path $tmp "SHA256SUMS") -UseBasicParsing

    $line = Get-Content (Join-Path $tmp "SHA256SUMS") | Where-Object { $_ -match ([regex]::Escape($asset) + "\s*$") } | Select-Object -First 1
    $expected = if ($line) { ($line -split "\s+")[0].ToLower() } else { "" }
    $actual = (Get-FileHash (Join-Path $tmp $asset) -Algorithm SHA256).Hash.ToLower()
    if (-not $expected -or $expected -ne $actual) {
        throw "Checksum mismatch, not installing."
    }

    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Move-Item -Force (Join-Path $tmp $asset) (Join-Path $dir "pitchside.exe")
    Write-Host "Installed pitchside to $dir\pitchside.exe"

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (($userPath -split ";") -notcontains $dir) {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$dir", "User")
        Write-Host "Added $dir to your PATH. Open a new terminal window to use it."
    }
    Write-Host ""
    Write-Host "Run: pitchside   (then 'apikey set' to add your football-data.org key)"
}
finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

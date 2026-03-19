$excludeName = "node_modules"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Synology Drive - Exclude node_modules" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# ── Find Synology Drive ─────────────────────────────────────────────────────

Write-Host "[1/4] Searching for Synology Drive installation..." -ForegroundColor White

$dataDir = @(
    "$env:LOCALAPPDATA\SynologyDrive\data",
    "$env:APPDATA\SynologyDrive\data",
    "C:\Program Files\SynologyDrive\data",
    "C:\Program Files (x86)\SynologyDrive\data"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $dataDir) {
    Write-Host "  ERROR: Could not find Synology Drive data directory." -ForegroundColor Red
    Write-Host "  Make sure Synology Drive Client is installed." -ForegroundColor Red
    return
}
Write-Host "  Found: $dataDir" -ForegroundColor Green
Write-Host ""

# ── Check sync sessions ─────────────────────────────────────────────────────

Write-Host "[2/4] Checking sync sessions..." -ForegroundColor White

$sessionDir = Join-Path $dataDir "session"
$filters = Get-ChildItem -Path $sessionDir -Recurse -Filter "blacklist.filter" -ErrorAction SilentlyContinue

if ($filters.Count -eq 0) {
    Write-Host "  ERROR: No sync sessions found." -ForegroundColor Red
    Write-Host "  Set up a sync task in Synology Drive first." -ForegroundColor Red
    return
}
Write-Host "  Found $($filters.Count) sync session(s)." -ForegroundColor Green
Write-Host ""

# ── Confirm ──────────────────────────────────────────────────────────────────

Write-Host "  This will:" -ForegroundColor White
Write-Host "    - Stop Synology Drive" -ForegroundColor White
Write-Host "    - Add '$excludeName' to the sync exclusion list" -ForegroundColor White
Write-Host "    - Restart Synology Drive" -ForegroundColor White
Write-Host ""
$confirm = Read-Host "  Proceed? (Y/N)"
if ($confirm -notmatch '^[Yy]$') {
    Write-Host ""
    Write-Host "  Cancelled. No changes were made." -ForegroundColor Yellow
    return
}
Write-Host ""

# ── Stop Synology Drive ─────────────────────────────────────────────────────

Write-Host "[3/4] Stopping Synology Drive..." -ForegroundColor White

$stopped = @()
foreach ($name in @("cloud-drive-daemon","cloud-drive-connect","cloud-drive-ui")) {
    if (Get-Process -Name $name -ErrorAction SilentlyContinue) {
        Stop-Process -Name $name -Force -ErrorAction SilentlyContinue
        $stopped += $name
    }
}
if ($stopped.Count -gt 0) {
    Write-Host "  Stopped: $($stopped -join ', ')" -ForegroundColor Green
} else {
    Write-Host "  Synology Drive was not running." -ForegroundColor Yellow
}
Start-Sleep -Seconds 2
Write-Host ""

# ── Update blacklist filters ────────────────────────────────────────────────

Write-Host "[4/4] Updating blacklist filters..." -ForegroundColor White

$updated = 0; $skipped = 0
foreach ($f in $filters) {
    $content = Get-Content $f.FullName -Raw
    $sid = Split-Path (Split-Path $f.FullName -Parent) -Leaf

    if ($content -match [regex]::Escape("`"$excludeName`"")) {
        Write-Host "  Session $sid : Already excluded" -ForegroundColor DarkGreen
        Write-Host "    -> $($f.FullName)" -ForegroundColor Gray
        $skipped++
        continue
    }

    if ($content -match '\[Directory\]') {
        $newContent = $content -replace '(\[Directory\]\r?\n)', "`$1black_name = `"$excludeName`"`n"
    } else {
        $newContent = $content.TrimEnd() + "`n`n[Directory]`nblack_name = `"$excludeName`"`n"
    }

    Set-Content -Path $f.FullName -Value $newContent -NoNewline
    Write-Host "  Session $sid : Added '$excludeName'" -ForegroundColor Green
    Write-Host "    -> $($f.FullName)" -ForegroundColor Gray
    $updated++
}
Write-Host ""

# ── Restart Synology Drive ──────────────────────────────────────────────────

Write-Host "Restarting Synology Drive..." -ForegroundColor White

$installDir = Split-Path $dataDir -Parent
$uiExe = Get-ChildItem -Path $installDir -Recurse -Filter "cloud-drive-ui.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($uiExe) {
    Start-Process $uiExe.FullName
    Write-Host "  Synology Drive started." -ForegroundColor Green
} else {
    Write-Host "  Could not find cloud-drive-ui.exe - please start Synology Drive manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Done. Updated $updated, skipped $skipped session(s)." -ForegroundColor Cyan
Write-Host ""

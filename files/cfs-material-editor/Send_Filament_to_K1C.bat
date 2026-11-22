@echo off
chcp 65001 >nul
set "PRINTER_IP=__IP__"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ip = '%PRINTER_IP%';" ^
  "$base = Join-Path $env:APPDATA 'OrcaSlicer\user';" ^
  "$files = Get-ChildItem -Path $base -Filter '*.json' -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -eq 'filament' } | Sort-Object Name;" ^
  "if (-not $files) { Write-Host 'No OrcaSlicer filament JSON files found!' -ForegroundColor Red; exit 1 }" ^
  "Write-Host '=== Your OrcaSlicer Filaments ===' -ForegroundColor Cyan;" ^
  "Write-Host ' [0] Exit' -ForegroundColor DarkGray;" ^
  "for ($i=0; $i -lt $files.Count; $i++) { Write-Host (' [{0}] {1}' -f ($i+1), $files[$i].BaseName) }" ^
  "$sel = Read-Host '`nEnter number(s) to send (e.g. 1 or 1,3) or 0 to exit';" ^
  "if ([string]::IsNullOrWhiteSpace($sel) -or $sel.Trim() -match '^(0|q|exit)$') { exit 2 }" ^
  "$chosen = @();" ^
  "foreach ($s in ($sel -split ',')) { $n = 0; if ([int]::TryParse($s.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $files.Count) { $chosen += (Get-Content -Raw -Encoding UTF8 $files[$n-1].FullName) } }" ^
  "if (-not $chosen) { Write-Host 'No valid selection.' -ForegroundColor Yellow; exit 0 }" ^
  "$body = @{ files = $chosen; allow_cf = $false } | ConvertTo-Json -Depth 10;" ^
  "$res = Invoke-RestMethod -Uri ('http://' + $ip + ':8088/api/import_orca') -Method Post -ContentType 'application/json; charset=utf-8' -Body ([System.Text.Encoding]::UTF8.GetBytes($body));" ^
  "if ($res.skipped_cf -and $res.skipped_cf.Count -gt 0) {" ^
  "  $ans = Read-Host ('WARNING: Abrasive CF/GF detected (' + ($res.skipped_cf -join ', ') + '). Do NOT use in CFS-C! Send anyway? (y/n)');" ^
  "  if ($ans -match '^[yY]') {" ^
  "    $body = @{ files = $chosen; allow_cf = $true } | ConvertTo-Json -Depth 10;" ^
  "    $res = Invoke-RestMethod -Uri ('http://' + $ip + ':8088/api/import_orca') -Method Post -ContentType 'application/json; charset=utf-8' -Body ([System.Text.Encoding]::UTF8.GetBytes($body));" ^
  "  }" ^
  "}" ^
  "Write-Host ('Done! Added: ' + $res.added + ', Updated: ' + $res.updated) -ForegroundColor Green;"
if errorlevel 2 exit /b 0
pause

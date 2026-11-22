@echo off
chcp 65001 >nul
set "PRINTER_IP=__IP__"
set "ALLOW_CF=__ALLOW_CF__"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ip = '%PRINTER_IP%';" ^
  "$allowCf = ('%ALLOW_CF%' -eq '1');" ^
  "$base = Join-Path $env:APPDATA 'OrcaSlicer\user';" ^
  "$files = Get-ChildItem -Path $base -Filter '*.json' -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -eq 'filament' } | Sort-Object Name;" ^
  "if (-not $allowCf) { $files = $files | Where-Object { $_.BaseName -notmatch '(-CF|-GF)' } }" ^
  "if (-not $files) { Write-Host 'No eligible OrcaSlicer filament JSON files found!' -ForegroundColor Red; exit 1 }" ^
  "Write-Host '=== Your OrcaSlicer Filaments ===' -ForegroundColor Cyan;" ^
  "Write-Host ' [q] Exit' -ForegroundColor DarkGray;" ^
  "for ($i=0; $i -lt $files.Count; $i++) { Write-Host (' [{0}] {1}' -f ($i+1), $files[$i].BaseName) }" ^
  "$sel = Read-Host '`nEnter number(s) to send (e.g. 1 or 1,3) or q to exit';" ^
  "if ($sel.Trim() -match '^[qQ]$') { exit 2 }" ^
  "$chosen = @();" ^
  "foreach ($s in ($sel -split ',')) { $n = 0; if ([int]::TryParse($s.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $files.Count) { $chosen += (Get-Content -Raw -Encoding UTF8 $files[$n-1].FullName) } }" ^
  "if (-not $chosen) { Write-Host 'No valid selection.' -ForegroundColor Yellow; exit 0 }" ^
  "$body = @{ files = $chosen; allow_cf = $false } | ConvertTo-Json -Depth 10;" ^
  "$res = Invoke-RestMethod -Uri ('http://' + $ip + ':8088/api/import_orca') -Method Post -ContentType 'application/json; charset=utf-8' -Body ([System.Text.Encoding]::UTF8.GetBytes($body));" ^
  "if ($res.skipped_cf -and $res.skipped_cf.Count -gt 0) {" ^
  "  if ($allowCf) {" ^
  "    $ans = Read-Host ('WARNING: Abrasive CF/GF detected (' + ($res.skipped_cf -join ', ') + '). Do NOT use in CFS-C! Send anyway? (y/n)');" ^
  "    if ($ans -match '^[yY]') {" ^
  "      $body = @{ files = $chosen; allow_cf = $true } | ConvertTo-Json -Depth 10;" ^
  "      $res = Invoke-RestMethod -Uri ('http://' + $ip + ':8088/api/import_orca') -Method Post -ContentType 'application/json; charset=utf-8' -Body ([System.Text.Encoding]::UTF8.GetBytes($body));" ^
  "    }" ^
  "  } else {" ^
  "    Write-Host ('Skipped CF/GF (disabled in Editor Settings): ' + ($res.skipped_cf -join ', ')) -ForegroundColor Yellow;" ^
  "  }" ^
  "}" ^
  "Write-Host ('Done! Added: ' + $res.added + ', Updated: ' + $res.updated) -ForegroundColor Green;"
if errorlevel 2 exit /b 0
pause

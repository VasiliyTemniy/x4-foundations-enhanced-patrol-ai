$mod = "vas_enhanced_patrol_ai"
$pkg = Join-Path $PSScriptRoot "packages\$mod"
$ts  = Get-Date -Format "dd-MM-yyyy_HHmmss"
$zip = Join-Path $PSScriptRoot "packages\${mod}_${ts}.zip"

if (Test-Path $pkg) { Remove-Item -Recurse -Force $pkg }
New-Item -ItemType Directory -Force $pkg | Out-Null

Get-ChildItem -LiteralPath "$PSScriptRoot\src" -Force |
    Copy-Item -Destination $pkg -Recurse -Force

# This is the only mod in my collection that has to have license included
# because it's based on HappyStation mod which is MIT-licensed
Copy-Item -Force "$PSScriptRoot\LICENSE"       "$pkg\LICENSE"

Compress-Archive -Path "$pkg" -DestinationPath $zip -CompressionLevel Optimal

Write-Host "Packed: $zip"

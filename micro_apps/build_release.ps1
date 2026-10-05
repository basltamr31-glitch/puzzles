# Builds a release APK or AAB for one puzzle app WITH its real AdMob ad
# unit IDs, then proves they made it into the compiled code.
#
# Why this exists: release builds read the ad unit IDs only from
# --dart-define. A plain `flutter build apk --release` silently produces an
# app with NO ads at all - no banners, no hint video, no extra-life video -
# because every unit ID resolves to empty. That is exactly what happened to
# the 2026-09-22 APKs. This script makes that mistake impossible.
#
# Usage (from anywhere):
#   .\micro_apps\build_release.ps1 crossword_app apk
#   .\micro_apps\build_release.ps1 sudoku_app appbundle
#   .\micro_apps\build_release.ps1 all appbundle

param(
    [Parameter(Mandatory = $true)][string]$App,
    [ValidateSet('apk', 'appbundle')][string]$Target = 'appbundle'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$apps = if ($App -eq 'all') {
    @('crossword_app', 'sudoku_app', 'word_search_app', 'memory_app')
} else {
    @($App)
}

foreach ($name in $apps) {
    $dir = Join-Path $PSScriptRoot $name
    $config = Join-Path $dir 'ad_config.json'
    if (-not (Test-Path $config)) {
        throw "${name}: ad_config.json is missing - the build would ship with no ads."
    }
    $bannerId = (Get-Content $config -Raw | ConvertFrom-Json).BANNER_AD_UNIT_ID
    if (-not $bannerId) { throw "${name}: ad_config.json has no BANNER_AD_UNIT_ID." }

    Write-Host "=== Building $name ($Target) with real ad unit IDs"
    Push-Location $dir
    try {
        flutter build $Target --release --dart-define-from-file=ad_config.json
        if ($LASTEXITCODE -ne 0) { throw "${name}: flutter build failed." }
    } finally {
        Pop-Location
    }

    # Open the package and look for the banner ID inside the compiled Dart.
    if ($Target -eq 'apk') {
        $package = Join-Path $dir 'build\app\outputs\flutter-apk\app-release.apk'
        $entryName = 'lib/arm64-v8a/libapp.so'
    } else {
        $package = Join-Path $dir 'build\app\outputs\bundle\release\app-release.aab'
        $entryName = 'base/lib/arm64-v8a/libapp.so'
    }
    $zip = [System.IO.Compression.ZipFile]::OpenRead($package)
    try {
        $entry = $zip.GetEntry($entryName)
        if ($null -eq $entry) { throw "${name}: $entryName not found in the package." }
        $reader = New-Object System.IO.StreamReader($entry.Open(), [System.Text.Encoding]::ASCII)
        $content = $reader.ReadToEnd()
        $reader.Close()
    } finally {
        $zip.Dispose()
    }
    if (-not $content.Contains($bannerId)) {
        throw "${name}: the real ad unit IDs are NOT in $package. Do not install or upload it."
    }
    Write-Host "OK  ${name}: real ad unit IDs verified in $package" -ForegroundColor Green
}

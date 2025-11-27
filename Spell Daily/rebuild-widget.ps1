# Rebuild Widget Script
# This script cleans, rebuilds, and reinstalls the app to ensure widget changes are applied

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Widget Rebuild Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean Flutter build
Write-Host "[1/5] Cleaning Flutter build..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Flutter clean failed!" -ForegroundColor Red
    exit 1
}

# Step 2: Get dependencies
Write-Host "[2/5] Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Flutter pub get failed!" -ForegroundColor Red
    exit 1
}

# Step 3: Uninstall old app (optional, skip if ADB not available)
Write-Host "[3/5] Uninstalling old app..." -ForegroundColor Yellow
$adbPath = Get-Command adb -ErrorAction SilentlyContinue
if ($adbPath) {
    adb uninstall com.spelldaily.spell_daily 2>$null
    Write-Host "  (Skipped if app not installed)" -ForegroundColor Gray
} else {
    Write-Host "  (ADB not found in PATH, skipping uninstall)" -ForegroundColor Gray
    Write-Host "  You may need to manually uninstall the app from your device" -ForegroundColor Yellow
}

# Step 4: Build APK
Write-Host "[4/5] Building APK..." -ForegroundColor Yellow
flutter build apk --debug
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Build failed!" -ForegroundColor Red
    exit 1
}

# Step 5: Install app
Write-Host "[5/5] Installing app..." -ForegroundColor Yellow
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $apkPath) {
    # Try flutter install first
    flutter install --debug
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Flutter install failed, trying ADB..." -ForegroundColor Yellow
        if ($adbPath) {
            adb install -r $apkPath
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Error: Installation failed!" -ForegroundColor Red
                Write-Host "Please install manually: $apkPath" -ForegroundColor Yellow
                exit 1
            }
        } else {
            Write-Host "Error: Cannot install - ADB not found!" -ForegroundColor Red
            Write-Host "Please install manually from: $apkPath" -ForegroundColor Yellow
            Write-Host "Or use Android Studio to run the app" -ForegroundColor Yellow
            exit 1
        }
    }
} else {
    Write-Host "Error: APK not found at $apkPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: To see widget changes:" -ForegroundColor Yellow
Write-Host "  1. Remove the old widget from your home screen" -ForegroundColor White
Write-Host "  2. Long-press home screen → Widgets → Spell Daily" -ForegroundColor White
Write-Host "  3. Add the widget back to your home screen" -ForegroundColor White
Write-Host ""
Write-Host "The widget should now show your changes!" -ForegroundColor Green


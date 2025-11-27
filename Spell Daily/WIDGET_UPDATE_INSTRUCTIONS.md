# Widget Update Instructions

If you've modified the widget code and changes aren't showing up, follow these steps:

## Why Widgets Don't Update Immediately

Android widgets are cached by the system. When you modify native Android code (Kotlin files, XML layouts, or resources), you need to:
1. Clean and rebuild the app completely
2. Uninstall the old app
3. Reinstall the new app
4. Remove and re-add the widget to your home screen

## Step-by-Step Instructions

### 1. Clean the Build

**Option A: Using Flutter CLI**
```bash
flutter clean
flutter pub get
```

**Option B: Using Android Studio**
- Go to `Build` → `Clean Project`
- Then `Build` → `Rebuild Project`

### 2. Uninstall the Old App

**On your device/emulator:**
- Go to Settings → Apps → Spell Daily → Uninstall
- OR long-press the app icon → Uninstall

**Using ADB (if connected):**
```bash
adb uninstall com.spelldaily.spell_daily
```

### 3. Rebuild and Install

**Using Flutter CLI:**
```bash
flutter build apk --debug
flutter install
```

**OR for release build:**
```bash
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Using Android Studio:**
- Click the Run button (green play icon)
- This will build and install automatically

### 4. Remove and Re-add the Widget

1. **Remove the old widget:**
   - Long-press the widget on your home screen
   - Drag it to "Remove" or "Delete"

2. **Add the new widget:**
   - Long-press on an empty area of your home screen
   - Select "Widgets"
   - Find "Spell Daily" widget
   - Drag it to your home screen

### 5. Force Widget Update (Optional)

If the widget still doesn't update after re-adding:

**Method 1: Restart your device**
- This clears all widget caches

**Method 2: Clear app data**
- Go to Settings → Apps → Spell Daily → Storage → Clear Data
- Re-add the widget

**Method 3: Trigger update from app**
- Open the app
- Complete a game or trigger any action that calls `HomeWidgetService.updateWidget()`

## Quick Rebuild Script (Windows PowerShell)

Save this as `rebuild-widget.ps1` in your project root:

```powershell
Write-Host "Cleaning Flutter build..." -ForegroundColor Yellow
flutter clean

Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "Uninstalling old app..." -ForegroundColor Yellow
adb uninstall com.spelldaily.spell_daily

Write-Host "Building and installing new app..." -ForegroundColor Yellow
flutter build apk --debug
flutter install

Write-Host "Done! Now remove and re-add the widget from your home screen." -ForegroundColor Green
```

Run it with:
```powershell
.\rebuild-widget.ps1
```

## Troubleshooting

### Widget still shows old data
- Make sure you've removed the old widget completely
- Check that the app was actually uninstalled (Settings → Apps)
- Try restarting your device

### Widget doesn't appear in widget list
- Make sure the app is installed
- Check `AndroidManifest.xml` has the widget receiver configured
- Verify `streak_widget_info.xml` exists in `android/app/src/main/res/xml/`

### Widget crashes or shows errors
- Check Logcat for errors: `adb logcat | grep -i widget`
- Verify all drawable resources exist (logo.png, arrow_icon, etc.)
- Check that all IDs in `widget_layout.xml` match the Kotlin code

## Testing Widget Updates

After rebuilding, test that the widget updates correctly:

1. **Test State 1 (No streak):**
   - Clear app data or use a fresh install
   - Add widget → Should show "START CHALLENGE" with BEGIN button

2. **Test State 4 (With streak):**
   - Complete a game in the app
   - Widget should update to show streak count and week progress

3. **Test Manual Update:**
   - Open the app
   - Complete a game
   - Widget should update within a few seconds

## Notes

- Widget updates are triggered by `HomeWidgetService.updateWidget()` in Flutter
- The widget reads data from `HomeWidgetPreferences` SharedPreferences
- Widget state is determined by `widget_state` key or calculated from streak data
- Changes to native code (Kotlin/XML) require a full rebuild
- Changes to Flutter code only require a hot reload, but widget updates still need the app to call `updateWidget()`


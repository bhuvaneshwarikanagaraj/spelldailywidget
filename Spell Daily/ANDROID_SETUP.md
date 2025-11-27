# Android Setup Guide

## AndroidManifest.xml Changes

Add the following to `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

```xml
<application
    ...>
    
    <!-- Existing activity declaration -->
    <activity
        android:name=".MainActivity"
        ...>
        ...
    </activity>
    
    <!-- Add Widget Provider -->
    <receiver
        android:name=".StreakWidgetProvider"
        android:exported="true">
        <intent-filter>
            <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        </intent-filter>
        <meta-data
            android:name="android.appwidget.provider"
            android:resource="@xml/streak_widget_info" />
    </receiver>
    
</application>
```

## Required Permissions

Ensure these permissions are in AndroidManifest.xml (usually already present):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

## Build Configuration

### build.gradle (app level)

Ensure minimum SDK is 21+:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
        ...
    }
}
```

### build.gradle (project level)

Ensure Kotlin is configured:

```gradle
buildscript {
    ext.kotlin_version = '1.9.0'
    ...
    dependencies {
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

## Widget Installation

1. Build the app:
   ```bash
   flutter build apk
   ```

2. Install on device:
   ```bash
   flutter install
   ```

3. Add widget to home screen:
   - Long-press on home screen
   - Select "Widgets"
   - Find "Spell Daily"
   - Drag to home screen

## Testing Widget

1. Complete a game in the app
2. Widget should update automatically
3. Tap widget to open app
4. Widget should show correct streak count

## Troubleshooting

### Widget not showing
- Check AndroidManifest.xml has widget provider
- Verify widget_layout.xml exists
- Check streak_widget_info.xml configuration
- Rebuild app

### Widget not updating
- Check SharedPreferences keys match
- Verify HomeWidgetService.updateWidget() is called
- Check widget permissions
- Restart device

### Widget tap not working
- Check MainActivity handles intents
- Verify pending intent flags
- Check app is installed correctly

## Files Location

- Kotlin: `android/app/src/main/kotlin/com/spelldaily/app/`
- Layouts: `android/app/src/main/res/layout/`
- XML config: `android/app/src/main/res/xml/`
- Drawables: `android/app/src/main/res/drawable/`
- Strings: `android/app/src/main/res/values/strings.xml`

## Notes

- Widget uses RemoteViews (Android limitation)
- Colors match Flutter app design
- Widget updates via SharedPreferences
- Tap opens app and navigates to login






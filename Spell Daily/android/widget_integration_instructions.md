# Android Home Widget Integration Instructions

## Overview
This document explains how to integrate the Android home screen widget into your Flutter app.

## Files Created
1. `StreakWidgetProvider.kt` - Widget provider that updates the widget
2. `widget_layout.xml` - Layout for the widget UI
3. `streak_widget_info.xml` - Widget configuration
4. Drawable resources for widget styling

## AndroidManifest.xml Changes

Add the following to your `AndroidManifest.xml` inside the `<application>` tag:

```xml
<!-- Widget Provider -->
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
```

## MainActivity.kt Updates

Ensure your `MainActivity.kt` can handle widget intents:

```kotlin
package com.spelldaily.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Handle widget navigation
        val intent = intent
        if (intent != null && intent.hasExtra("route")) {
            val route = intent.getStringExtra("route")
            // Route will be handled by Flutter navigation
        }
    }
}
```

## SharedPreferences Keys

The widget reads data from SharedPreferences with these keys:
- `flutter.streak_count` (int)
- `flutter.has_completed_first_game` (bool)
- `flutter.week_progress` (String, comma-separated: "1,0,1,0,0,0")
- `flutter.last_played_date` (String, ISO-8601 format)

## Testing the Widget

1. Build and install the app
2. Long-press on home screen
3. Select "Widgets"
4. Find "Spell Daily" widget
5. Add to home screen
6. Widget should display based on current streak data

## Updating the Widget

The widget updates when:
- App calls `HomeWidgetService.updateWidget()`
- System triggers periodic update (daily)
- Widget is added to home screen

## Notes

- The widget uses RemoteViews, which has limitations compared to Flutter widgets
- Colors and layout should match the Flutter app design as closely as possible
- Widget tap opens the app and navigates to the appropriate screen






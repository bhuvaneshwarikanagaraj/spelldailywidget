# How to Run Spell Daily App

## Prerequisites

1. **Flutter SDK** (version 3.0.0 or higher)
   - Download from: https://docs.flutter.dev/get-started/install
   - Verify installation: `flutter doctor`

2. **Android Studio** (recommended)
   - Download from: https://developer.android.com/studio
   - Install Android SDK (API 24 or higher)
   - Set up an Android Emulator or connect a physical device

3. **Firebase Configuration** ✅
   - The `google-services.json` file is already in the project
   - Firebase project: `spell-daily-85ef0`

## Setup Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Verify Flutter Setup

```bash
flutter doctor
```

Make sure all required components are installed and configured.

### 3. Check Connected Devices

```bash
flutter devices
```

You should see either:
- An Android emulator (if running)
- A physical device (if connected via USB with USB debugging enabled)

### 4. Run the App

#### Option A: Run on Android Device/Emulator
```bash
flutter run
```

#### Option B: Run with specific device
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

#### Option C: Build and Install APK
```bash
flutter build apk --debug
# APK will be at: build/app/outputs/flutter-apk/app-debug.apk
```

## Important Notes

⚠️ **Firebase Setup**: The app uses Firebase Firestore. Make sure:
- The `google-services.json` file is in `app/` directory (already present)
- Your Firebase project has Firestore database enabled
- Firestore rules allow read/write access (for testing, you may need to temporarily allow all)

⚠️ **Internet Connection Required**: 
- The app loads a game from `https://app.spelldaily.com/?code=<loginCode>`
- Firebase requires internet connectivity

⚠️ **Login Code**: 
- You'll need a login code to access the app
- The app will prompt for this on first launch

## Troubleshooting

### If Firebase initialization fails:
- Verify `google-services.json` is in the correct location (`app/google-services.json`)
- Check that Firebase Firestore is enabled in your Firebase Console
- Ensure internet connection is active

### If build fails:
```bash
flutter clean
flutter pub get
flutter run
```

### If no devices found:
- Start an Android emulator from Android Studio
- Or enable USB debugging on your physical device

## App Flow

1. **Splash Screen** → Shows logo for 2 seconds
2. **Login Screen** → Enter your login code
3. **Start Game Screen** → View streak and start game
4. **WebView Game** → Loads game from web
5. **Result Screen** → Shows success/failure based on completion

## Development Commands

```bash
# Run in debug mode (hot reload enabled)
flutter run

# Run in release mode
flutter run --release

# Build APK for release
flutter build apk --release

# Analyze code
flutter analyze

# Run tests
flutter test
```



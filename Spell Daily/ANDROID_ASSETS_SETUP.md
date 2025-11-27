# Android Assets Setup Instructions

## Logo Setup for Widget

To display the logo in the Android home widget, you need to copy the logo image to the Android drawable folder:

1. Copy `assets/images/logo.png` to `android/app/src/main/res/drawable/logo.png`

## App Icon Setup

To update the app icon with the logo, you need to copy the logo to all mipmap folders with appropriate sizes:

1. **mipmap-mdpi** (48x48): Copy and resize logo to 48x48 pixels → `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
2. **mipmap-hdpi** (72x72): Copy and resize logo to 72x72 pixels → `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
3. **mipmap-xhdpi** (96x96): Copy and resize logo to 96x96 pixels → `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
4. **mipmap-xxhdpi** (144x144): Copy and resize logo to 144x144 pixels → `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
5. **mipmap-xxxhdpi** (192x192): Copy and resize logo to 192x192 pixels → `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

### Quick Setup (Manual)

You can use an image editing tool or online resizer to create the different sizes, then copy them to the respective mipmap folders.

### Alternative: Use Android Studio

1. Open Android Studio
2. Right-click on `android/app/src/main/res`
3. Select "New" → "Image Asset"
4. Choose "Launcher Icons"
5. Select the logo.png file as the source
6. Android Studio will automatically generate all sizes

## Arrow Icon

The arrow icon for the widget is already created as a vector drawable at `android/app/src/main/res/drawable/arrow_icon.xml`. If you want to use the actual arrow.jpeg image instead, you can:

1. Copy `assets/images/arrow.jpeg` to `android/app/src/main/res/drawable/arrow_icon.png` (convert JPEG to PNG if needed)
2. Update `android/app/src/main/res/layout/widget_layout.xml` to reference the PNG instead of the XML drawable

## Notes

- The widget will gracefully handle missing logo images (they just won't display)
- Make sure logo.png is a PNG file with transparency if needed
- The app icon should be square and work well at small sizes


















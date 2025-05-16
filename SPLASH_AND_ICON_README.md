# Splash Screen and App Icon Setup

This document explains how to use the splash screen and app icon features in the Malaebna app.

## Logo Files

The app uses two logo files:

- `assets/images/logo/malaebna_logo_light.png` - For light theme (green logo)
- `assets/images/logo/malaebna_logo_dark.png` - For dark theme (dark green logo)

These files should be placed in the `assets/images/logo` directory.

## Splash Screen

The app uses the `flutter_native_splash` package to generate a native splash screen that appears when the app is launching. After the native splash screen, a custom Flutter splash screen is shown that provides a smooth transition to the main app.

### Configuration

The splash screen is configured in the `flutter_native_splash.yaml` file with the following settings:

```yaml
flutter_native_splash:
  # Light mode splash screen
  color: "#FFFFFF"
  image: assets/images/logo/malaebna_logo_light.png
  branding: assets/images/logo/malaebna_logo_light.png
  color_dark: "#121212"
  image_dark: assets/images/logo/malaebna_logo_dark.png
  branding_dark: assets/images/logo/malaebna_logo_dark.png

  android_12:
    # Light mode Android 12+ splash screen
    image: assets/images/logo/malaebna_logo_light.png
    color: "#FFFFFF"
    icon_background_color: "#FFFFFF"
    image_dark: assets/images/logo/malaebna_logo_dark.png
    color_dark: "#121212"
    icon_background_color_dark: "#121212"

  web: false # We're not using web splash screen for now
```

### Regenerating the Splash Screen

After making changes to the logo files or configuration, run the following command to regenerate the splash screen:

```bash
flutter pub run flutter_native_splash:create
```

Or use the provided script:

```bash
scripts/generate_splash.bat
```

## App Icon

The app uses the `flutter_launcher_icons` package to generate app icons for various platforms.

### Configuration

The app icon is configured in the `flutter_launcher_icons.yaml` file with the following settings:

```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/logo/malaebna_logo_light.png"
  min_sdk_android: 21 # android min sdk min:16, default 21
  adaptive_icon_background: "#FFFFFF" # only available for Android 8.0 devices and above
  adaptive_icon_foreground: "assets/images/logo/malaebna_logo_light.png"
  # The following adds support for dark mode icon
  image_path_ios: "assets/images/logo/malaebna_logo_light.png"
  remove_alpha_ios: true
  web:
    generate: false
  windows:
    generate: true
    icon_size: 48 # min:48, max:256, default: 48
    icon_name: "malaebna_icon"
```

### Regenerating the App Icon

After making changes to the logo files or configuration, run the following command to regenerate the app icons:

```bash
flutter pub run flutter_launcher_icons
```

Or use the provided script:

```bash
scripts/generate_icons.bat
```

## Custom Splash Screen

In addition to the native splash screen, the app includes a custom Flutter splash screen (`SplashScreen`) that provides a smooth transition to the main app. This screen:

1. Shows an animated logo that scales up
2. Displays the app name and tagline with a fade-in animation
3. Shows a loading indicator
4. Automatically navigates to the appropriate screen (onboarding, login, or main) after a 3-second delay

The custom splash screen is implemented in `lib/presentation/screens/splash/splash_screen.dart`.

## Building the App with Splash Screen and App Icon

To simplify the process of building the app with the splash screen and app icon, a script has been provided:

```bash
scripts/build_and_install.bat
```

This script will:

1. Generate the splash screen
2. Generate the app icons
3. Clean existing build artifacts
4. Build the debug APK
5. Offer to install the APK on a connected device

### Troubleshooting Build Issues

If you encounter build issues, particularly with messages like "BUILD FAILED" even though an APK is created, try the following:

1. **Clean the project**:

   ```bash
   flutter clean
   ```

2. **Delete build directories**:
   Remove the `build` directory and the `.dart_tool` directory.

3. **Check APK locations**:
   The APK may be built successfully but not copied to where Flutter expects it. Look for the APK in:

   - `build/app/outputs/apk/debug/app-arm64-v8a-debug.apk` (actual build location)
   - `build/app/outputs/flutter-apk/app-debug.apk` (where Flutter expects it)

4. **Manual APK copy**:
   If the APK exists but is not being recognized by Flutter, copy it manually:

   ```bash
   mkdir -p build/app/outputs/flutter-apk
   cp build/app/outputs/apk/debug/app-arm64-v8a-debug.apk build/app/outputs/flutter-apk/app-debug.apk
   ```

5. **Rebuild with verbose output**:

   ```bash
   flutter build apk --debug --verbose
   ```

6. **Check Gradle logs**:
   Look at the Gradle output in the terminal for more detailed error messages.

7. **Use the automated build script**:
   The provided `build_and_install.bat` script includes fixes for common APK copying issues.

### Common Build Errors

1. **"BUILD FAILED but APK exists"**:
   This often means the build actually succeeded but the APK wasn't copied to where Flutter expected it. The build script should fix this automatically.

2. **Missing resources or assets**:
   Ensure all logo files are in the correct directories before generating the splash screen and app icons.

3. **Version conflicts**:
   If you get errors about plugin compatibility, check the versions in `pubspec.yaml` and make sure they're compatible with your Flutter version.

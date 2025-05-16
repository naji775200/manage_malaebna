# Android Build Tips

## Resolving AAPT2 Errors

If you encounter AAPT2 errors like:

```
AAPT2 aapt2-8.2.0-10154469-windows Daemon #0: Unexpected error during link, attempting to stop daemon.
```

Try these solutions:

### Solution 1: Clean Build

```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
```

### Solution 2: Disable AAPT2 Daemon

In `android/gradle.properties`:

```
android.enableAapt2=true
android.enableAapt2Daemon=false
```

### Solution 3: Manually Download AAPT2

If the above solutions don't work:

1. Find your Android SDK build-tools directory (typically in Android Studio)
2. Copy the aapt2.exe (Windows) or aapt2 (Mac/Linux) file from the latest build-tools folder
3. Paste it into `android/aapt2-bundle/aapt2-windows/` (or appropriate platform folder)
4. Make sure your gradle.properties includes:
   ```
   android.aapt2FromMavenOverride=../aapt2-bundle/aapt2-windows/aapt2.exe
   ```

### Solution 4: Increase Memory for Gradle

In `android/gradle.properties`, increase memory:

```
org.gradle.jvmargs=-Xmx4G -XX:+UseParallelGC
```

### Solution 5: Use Older Android Gradle Plugin

In `android/build.gradle`, try an older version:

```
classpath 'com.android.tools.build:gradle:7.3.0'
```

## Fixing Resource Issues

If you encounter issues with the splash screen or other resources:

1. Make sure all image files are properly formatted (PNG, JPG, or WebP)
2. Verify you're not using any special characters in resource names
3. Try adding `android.enableResourceOptimizations=false` to `gradle.properties`

## Debugging Build Issues

Run a verbose build to see more details:

```bash
flutter build apk --verbose
```

Or for Gradle directly:

```bash
cd android
./gradlew assembleDebug --info
```

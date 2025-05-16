# Android Build Fixes

This document outlines the issues encountered during the Android build process and the solutions implemented.

## Issues and Solutions

### 1. AAPT2 Processing Resource Errors

**Error Message:**

```
Execution failed for task ':app:processDebugResources'.
> A failure occurred while executing com.android.build.gradle.internal.res.LinkApplicationAndroidResourcesTask$TaskAction
   > AAPT2 aapt2-8.2.0-10154469-windows Daemon #0: Unexpected error during link, attempting to stop daemon.
```

**Solutions:**

1. Disabled PNG crunching to reduce resource processing load:

   ```gradle
   buildTypes {
       debug {
           crunchPngs false
       }
       release {
           crunchPngs false
       }
   }
   ```

2. Removed deprecated Gradle properties:
   - Removed `android.buildCacheDir` which is no longer supported
   - Removed other deprecated properties like `android.enableAapt2Daemon`

### 2. Duplicate Permissions in AndroidManifest.xml

**Error Message:**

```
Element uses-permission#android.permission.READ_EXTERNAL_STORAGE duplicated with element declared at AndroidManifest.xml
```

**Solution:**

- Removed duplicate permission declarations in AndroidManifest.xml

### 3. Plugin SDK Version Compatibility

**Error Message:**

```
Your project is configured to compile against Android SDK 34, but the following plugin(s) require to be compiled against a higher Android SDK version:
- flutter_plugin_android_lifecycle compiles against Android SDK 35
```

**Solution:**

- Updated both compileSdk and targetSdk to 35 in the app's build.gradle file

### 4. Package Attribute in AndroidManifest.xml Deprecation

**Warning Message:**

```
Setting the namespace via the package attribute in the source AndroidManifest.xml is no longer supported, and the value is ignored.
```

**Solution:**

- Removed the package attribute from the AndroidManifest.xml
- Ensured namespace is defined in build.gradle instead

## Additional Recommendations

1. **Clean Build Process:**

   - Always run `flutter clean` and then `flutter pub get` before building
   - Use `./gradlew clean` in the android directory to clear Gradle caches

2. **Resource Optimization:**

   - Consider optimizing large PNG assets before adding them to the project
   - Use vector drawables (SVG) when possible instead of raster images

3. **Gradle Configuration:**

   - Keep only necessary performance properties in gradle.properties
   - Use the Gradle build cache for faster builds

   ```
   org.gradle.caching=true
   ```

4. **Managing Android SDK Versions:**
   - Check plugin compatibility with different SDK versions
   - Use the highest required SDK version to avoid conflicts

```

```

# AAPT2 Bundle Directory

This directory is used to store a custom version of the Android Asset Packaging Tool 2 (AAPT2) to work around build issues.

If you experience AAPT2-related errors during builds, you may need to:

1. Download the appropriate AAPT2 binary for your platform from Android SDK's build-tools directory
2. Place it in the appropriate platform directory (aapt2-windows, aapt2-linux, or aapt2-darwin)
3. Make sure your gradle.properties file includes:
   ```
   android.aapt2FromMavenOverride=../aapt2-bundle/aapt2-[your-platform]/aapt2[.exe]
   ```

This helps bypass AAPT2 daemon issues by providing a direct path to the executable.

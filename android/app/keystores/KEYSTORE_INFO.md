# Android Keystore Information

## Keystore Details

- **File Location**: `android/app/keystores/upload-keystore.jks`
- **Alias**: `malaebna`
- **Password**: `alameri123` (for both keystore and key)
- **Validity**: 10,000 days (approximately 27 years)
- **Key Properties File**: `android/key.properties`

## Using the Keystore

The keystore has been configured in the project's Gradle build files.

### Keystore Configuration

The keystore configuration is read from the `key.properties` file:

```
storePassword=alameri123
keyPassword=alameri123
keyAlias=malaebna
storeFile=app/keystores/upload-keystore.jks
```

### Build a Signed APK

To build a signed APK using this keystore, run:

```
cd android
./gradlew assembleRelease
```

The signed APK will be located at:
`android/app/build/outputs/flutter-apk/app-release.apk`

### Google Play Store Submission

For Google Play Store submission, you can use:

```
flutter build appbundle
```

The AAB file will be located at:
`build/app/outputs/bundle/release/app-release.aab`

## Important Security Notes

- **Keep your keystore secure**: If you lose it, you won't be able to update your app on the Play Store
- **Keep your passwords secure**: Don't share the passwords with unauthorized individuals
- **Backup your keystore**: Store a backup copy in a secure location

## Regenerating the Keystore

If needed, you can regenerate the keystore using:

```
keytool -genkey -v -keystore android/app/keystores/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias malaebna
```

Just make sure to update the `key.properties` file with the new passwords if you change them.

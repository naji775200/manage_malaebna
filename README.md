# Manage Malaebna

An app for managing football pitches.

## Setup Instructions

### Prerequisites

- Flutter (latest stable version)
- Android Studio / Xcode
- A Google Maps API key

### Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure platform-specific settings as described below

### Google Maps Configuration

#### Android

The Google Maps API key is already configured in the AndroidManifest.xml file. If you need to use your own key, replace the value in:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY" />
```

#### iOS

For iOS, you need to:

1. Set the API key in the AppDelegate.swift file:

```swift
GMSServices.provideAPIKey("YOUR_API_KEY")
```

### Permissions

This app requires the following permissions:

- **Location**: To show the user's location on maps and find nearby stadiums
- **Camera**: To take photos of stadiums
- **Storage/Photos**: To access and save images

#### Testing Permissions

The app includes a permissions helper utility that can be used to request permissions:

```dart
import 'package:manage_malaebna/core/utils/permissions_helper.dart';

// Request single permission
final hasLocationPermission = await PermissionsHelper.requestLocationPermission();

// Request all permissions
final permissions = await PermissionsHelper.requestAllPermissions();
```

### Troubleshooting

#### Common Issues

1. **Gradle Build Issues**: Make sure you're using the correct Flutter version and have updated the Gradle configuration.

2. **Permission Denied**: Ensure you've properly configured the permissions in both AndroidManifest.xml and Info.plist.

3. **Maps not showing**: Verify your API key is correct and has the appropriate restrictions and API enablement in the Google Cloud Console.

## Contributing

[Contribution guidelines for this project]

## License

[License information]

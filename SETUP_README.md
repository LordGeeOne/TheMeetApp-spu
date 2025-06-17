# MeetApp Setup Guide

This guide will help you set up the MeetApp project with your own API keys and Firebase configuration.

## Prerequisites

- Flutter SDK (>=3.0.0)
- Firebase account
- Google Cloud Platform account (for Maps API)
- Android Studio or VS Code
- Git

## 🔧 API Keys Setup

### 1. Google Maps API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
4. Create credentials (API Key)
5. Restrict the API key to your app (recommended for production)

### 2. Firebase Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable the following services:
   - Authentication (Google Sign-In)
   - Cloud Firestore
   - Cloud Storage
   - Cloud Functions (if using)

## 📝 Configuration Steps

### Step 1: Configure API Keys

1. Copy the template file:
   ```bash
   cp lib/config/api_config.dart.template lib/config/api_config.dart
   ```

2. Edit `lib/config/api_config.dart` and replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual Google Maps API key.

### Step 2: Configure Firebase

1. Copy the template file:
   ```bash
   cp lib/services/firebase_options.dart.template lib/services/firebase_options.dart
   ```

2. In the Firebase Console, go to Project Settings > General tab
3. Copy the configuration values and replace the placeholders in `firebase_options.dart`:
   - `YOUR_WEB_API_KEY` → Web API Key
   - `YOUR_ANDROID_API_KEY` → Android API Key  
   - `YOUR_IOS_API_KEY` → iOS API Key
   - `YOUR_PROJECT_ID` → Project ID
   - And so on...

### Step 3: Configure Android

1. Copy the template files:
   ```bash
   cp android/app/google-services.json.template android/app/google-services.json
   cp android/app/src/main/AndroidManifest.xml.template android/app/src/main/AndroidManifest.xml
   ```

2. Download the `google-services.json` file from Firebase Console (Project Settings > Your Apps > Android app)
3. Replace `android/app/google-services.json` with the downloaded file

4. Edit `android/app/src/main/AndroidManifest.xml` and replace `YOUR_GOOGLE_MAPS_API_KEY` with your Google Maps API key.

### Step 4: Configure iOS (if targeting iOS)

1. Download the `GoogleService-Info.plist` file from Firebase Console
2. Add it to the `ios/Runner/` directory
3. Update iOS configuration as needed

## 🚀 Running the App

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## 🛡️ Security Notes

- **Never commit API keys to version control**
- The following files are ignored by git and contain sensitive information:
  - `lib/config/api_config.dart`
  - `lib/services/firebase_options.dart`
  - `android/app/google-services.json`
  - `android/app/src/main/AndroidManifest.xml`
  - `ios/Runner/GoogleService-Info.plist`

- Template files (`.template` extension) are kept in version control for reference

## 📁 Project Structure

```
lib/
├── config/
│   ├── api_config.dart.template     # Template for API keys
│   └── api_config.dart             # Your actual API keys (gitignored)
├── services/
│   ├── firebase_options.dart.template  # Template for Firebase config
│   └── firebase_options.dart          # Your actual Firebase config (gitignored)
└── ...

android/app/
├── google-services.json.template   # Template for Google Services
├── google-services.json           # Your actual Google Services (gitignored)
└── src/main/
    ├── AndroidManifest.xml.template # Template for Android manifest
    └── AndroidManifest.xml         # Your actual Android manifest (gitignored)
```

## 🔍 Troubleshooting

### Common Issues

1. **"API key not found" errors**
   - Ensure you've copied and configured all template files
   - Check that your API keys are correctly set in `api_config.dart`

2. **Firebase connection issues**
   - Verify `firebase_options.dart` has the correct values
   - Ensure `google-services.json` is properly configured

3. **Maps not loading**
   - Check that your Google Maps API key is valid
   - Ensure you've enabled the required APIs in Google Cloud Console
   - Verify the API key is correctly set in `AndroidManifest.xml`

4. **Build errors**
   - Run `flutter clean` and `flutter pub get`
   - Check that all template files have been copied and configured

### Getting Help

If you encounter issues:
1. Check the console output for specific error messages
2. Verify all configuration files are properly set up
3. Ensure your Firebase project has the necessary services enabled
4. Check that your Google Cloud project has the required APIs enabled

## 🤝 Contributing

When contributing to this project:
1. Never commit actual API keys or sensitive configuration
2. Only commit template files
3. Update this README if you add new configuration requirements
4. Test your changes with fresh configuration files

## 📄 License

[Add your license information here]

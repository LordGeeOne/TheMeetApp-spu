#!/bin/bash

# MeetApp Setup Script
# This script helps set up the project by copying template files

echo "🚀 Setting up MeetApp project..."
echo

# Change to the Flutter project directory
cd the_meet_app

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Not in Flutter project directory. Please run this script from the MeetApp SPU root directory."
    exit 1
fi

echo "📝 Copying template files..."

# Copy API config template
if [ ! -f "lib/config/api_config.dart" ]; then
    cp lib/config/api_config.dart.template lib/config/api_config.dart
    echo "✅ Created lib/config/api_config.dart"
else
    echo "⚠️  lib/config/api_config.dart already exists, skipping..."
fi

# Copy Firebase options template
if [ ! -f "lib/services/firebase_options.dart" ]; then
    cp lib/services/firebase_options.dart.template lib/services/firebase_options.dart
    echo "✅ Created lib/services/firebase_options.dart"
else
    echo "⚠️  lib/services/firebase_options.dart already exists, skipping..."
fi

# Copy Android google-services.json template
if [ ! -f "android/app/google-services.json" ]; then
    cp android/app/google-services.json.template android/app/google-services.json
    echo "✅ Created android/app/google-services.json"
else
    echo "⚠️  android/app/google-services.json already exists, skipping..."
fi

# Copy Android manifest template
if [ ! -f "android/app/src/main/AndroidManifest.xml" ]; then
    cp android/app/src/main/AndroidManifest.xml.template android/app/src/main/AndroidManifest.xml
    echo "✅ Created android/app/src/main/AndroidManifest.xml"
else
    echo "⚠️  android/app/src/main/AndroidManifest.xml already exists, skipping..."
fi

echo
echo "📋 Next steps:"
echo "1. Edit lib/config/api_config.dart with your Google Maps API key"
echo "2. Edit lib/services/firebase_options.dart with your Firebase configuration"
echo "3. Replace android/app/google-services.json with your Firebase google-services.json"
echo "4. Edit android/app/src/main/AndroidManifest.xml with your Google Maps API key"
echo "5. Run 'flutter pub get' to install dependencies"
echo "6. Run 'flutter run' to start the app"
echo
echo "📖 For detailed instructions, see the_meet_app/README.md"
echo
echo "✨ Setup complete! Happy coding!"

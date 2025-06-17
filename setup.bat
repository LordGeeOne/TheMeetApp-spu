@echo off
REM MeetApp Setup Script for Windows
REM This script helps set up the project by copying template files

echo 🚀 Setting up MeetApp project...
echo.

REM Change to the Flutter project directory
cd the_meet_app

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ❌ Error: Not in Flutter project directory. Please run this script from the MeetApp SPU root directory.
    exit /b 1
)

echo 📝 Copying template files...

REM Copy API config template
if not exist "lib\config\api_config.dart" (
    copy "lib\config\api_config.dart.template" "lib\config\api_config.dart" >nul
    echo ✅ Created lib\config\api_config.dart
) else (
    echo ⚠️  lib\config\api_config.dart already exists, skipping...
)

REM Copy Firebase options template
if not exist "lib\services\firebase_options.dart" (
    copy "lib\services\firebase_options.dart.template" "lib\services\firebase_options.dart" >nul
    echo ✅ Created lib\services\firebase_options.dart
) else (
    echo ⚠️  lib\services\firebase_options.dart already exists, skipping...
)

REM Copy Android google-services.json template
if not exist "android\app\google-services.json" (
    copy "android\app\google-services.json.template" "android\app\google-services.json" >nul
    echo ✅ Created android\app\google-services.json
) else (
    echo ⚠️  android\app\google-services.json already exists, skipping...
)

REM Copy Android manifest template
if not exist "android\app\src\main\AndroidManifest.xml" (
    copy "android\app\src\main\AndroidManifest.xml.template" "android\app\src\main\AndroidManifest.xml" >nul
    echo ✅ Created android\app\src\main\AndroidManifest.xml
) else (
    echo ⚠️  android\app\src\main\AndroidManifest.xml already exists, skipping...
)

echo.
echo 📋 Next steps:
echo 1. Edit lib\config\api_config.dart with your Google Maps API key
echo 2. Edit lib\services\firebase_options.dart with your Firebase configuration
echo 3. Replace android\app\google-services.json with your Firebase google-services.json
echo 4. Edit android\app\src\main\AndroidManifest.xml with your Google Maps API key
echo 5. Run 'flutter pub get' to install dependencies
echo 6. Run 'flutter run' to start the app
echo.
echo 📖 For detailed instructions, see the_meet_app\README.md
echo.
echo ✨ Setup complete! Happy coding!
pause

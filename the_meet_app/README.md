# 🛡️ MeetApp SPU - Student Safety & Security Platform

A Flutter-based mobile safety application designed specifically for Sol Plaatje University (SPU) students. This app prioritizes student safety while facilitating secure social meetups and group coordination on and around campus.

## 📱 For Students

### What is MeetApp SPU?

MeetApp SPU is Sol Plaatje University's official student safety and security platform. Designed with student welfare as the top priority, this app helps SPU students organize safe meetups, coordinate group activities, and maintain security through real-time location sharing and emergency features.

### 🛡️ Safety-First Features

**🚨 Emergency & Security**
- **Panic Button** - Instant emergency alert to campus security and emergency contacts
- **Safe Walk Feature** - Real-time location sharing with trusted contacts during campus walks
- **Emergency Contacts** - Quick access to campus security, SAPS, and personal emergency contacts
- **Safety Check-ins** - Automated safety status updates for group activities
- **Campus Security Integration** - Direct communication with SPU security personnel

**� Secure Location Management**
- **Campus-Safe Zones** - Pre-approved safe meeting locations on campus
- **Real-time Location Tracking** - Share location only with verified SPU students
- **Route Safety Assessment** - Suggested safe routes around campus
- **Group Location Monitoring** - Track group members during activities for safety

**👥 Verified Student Network**
- **SPU Student Verification** - Only verified SPU students can join
- **Academic Integration** - Link with student ID for verification
- **Peer Safety Network** - Connect with classmates and study groups securely
- **Mentor-Mentee Connections** - Safe coordination between senior and junior students

**� Academic & Campus Integration**
- **Study Group Coordination** - Organize secure study sessions and academic meetups
- **Campus Event Management** - Coordinate university events with safety protocols
- **Library & Facility Booking** - Integration with campus facility reservations
- **Academic Calendar Sync** - Align meetups with class schedules and exam periods
- **Department-based Groups** - Connect with students from your faculty/department

**💬 Secure Communication**
- **Encrypted Group Chat** - Secure messaging for study groups and social activities
- **Anonymous Reporting** - Report safety concerns or suspicious activities
- **Campus Updates** - Receive important safety and security announcements
- **Peer Support Network** - Connect with counselors and peer support volunteers

### 🎓 Getting Started (SPU Students)

1. **Verify Your Student Status** - Use your SPU student ID for verification
2. **Complete Safety Profile** - Set up emergency contacts and safety preferences
3. **Join Study Groups** - Connect with classmates and academic groups
4. **Explore Campus Events** - Discover safe, university-approved activities
5. **Enable Safety Features** - Activate location sharing and emergency alerts

### 📞 Campus Support & Security

**Emergency Contacts:**
- **SPU Campus Security**: [Campus Security Number]
- **SAPS Kimberley**: 10111
- **Campus Health Services**: [Health Services Number]
- **Student Counseling**: [Counseling Services Number]

**Reporting & Support:**
- Use in-app anonymous reporting for safety concerns
- Contact Student Affairs through the app
- Access mental health and academic support resources
- Report technical issues to IT Support

---

## 👨‍💻 For Developers

### 🏫 About This Project

MeetApp SPU is developed as a comprehensive student safety and security solution for Sol Plaatje University. The application addresses the unique safety challenges faced by university students, particularly in South Africa, by providing a platform that combines social coordination with robust security features.

### 🎯 Project Goals

- **Student Safety First**: Prioritize the physical and digital safety of SPU students
- **Campus Integration**: Seamlessly integrate with university systems and protocols
- **Community Building**: Foster a safe and supportive student community
- **Emergency Response**: Provide rapid emergency response capabilities
- **Academic Support**: Enhance academic collaboration through secure platforms

### 🛠️ Tech Stack

- **Framework**: Flutter (Dart) - Cross-platform mobile development
- **Backend**: Firebase (Firestore, Authentication, Storage, Cloud Functions)
- **Maps & Location**: Google Maps API with custom safety overlays
- **Real-time Communication**: WebSocket connections via Firebase
- **Security**: End-to-end encryption for sensitive communications
- **State Management**: Provider pattern with security-focused architecture
- **University Integration**: APIs for student verification and campus systems

### 🏗️ Project Structure

```
lib/
├── config/           # API keys and security configuration
├── models/           # Data models (Student, SafetyEvent, EmergencyContact)
├── pages/            # UI pages (Emergency, SafetyMap, StudentVerification)
├── providers/        # State management (AuthProvider, SafetyProvider)
├── screens/          # Main app screens (Dashboard, SafetyCenter)
├── services/         # Business logic (EmergencyService, CampusSecurityAPI)
├── utils/            # Security utilities and safety helpers
└── widgets/          # Reusable safety-focused UI components
```

### 🔒 Security Requirements

- **Student Verification**: Integration with SPU student database
- **Data Encryption**: All sensitive data encrypted in transit and at rest
- **Privacy Protection**: Minimal data collection with explicit consent
- **Emergency Protocols**: Compliance with university emergency procedures
- **POPIA Compliance**: Adherence to South African data protection laws

### 🔧 Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Firebase account
- Google Cloud Platform account (for Maps API)
- Android Studio or VS Code
- Git

### ⚡ Quick Setup

1. **Clone the repository**
   ```bash
   git clone [your-repo-url]
   cd MeetApp\ SPU/the_meet_app
   ```

2. **Run the setup script**
   ```bash
   # Windows
   ../setup.bat
   
   # Linux/Mac
   chmod +x ../setup.sh
   ../setup.sh
   ```

3. **Configure API keys** (see detailed setup below)

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### 🔐 Detailed Configuration Setup

#### 1. Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create/select a project
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS  
   - Places API
   - Geocoding API
4. Create an API key
5. Edit `lib/config/api_config.dart`:
   ```dart
   static const String googleMapsApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

#### 2. Firebase Configuration

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable services:
   - Authentication (Google Sign-In)
   - Cloud Firestore
   - Cloud Storage
   - Cloud Functions
3. Download configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`
4. Update `lib/services/firebase_options.dart` with your project values

#### 3. Android Configuration

Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

### 🚀 Development Workflow

#### Running the App
```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific device
flutter run -d <device-id>
```

#### Building
```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios
```

#### Testing
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

### 📁 Key Files & Directories

| Path | Description |
|------|-------------|
| `lib/main.dart` | App entry point with security initialization |
| `lib/config/api_config.dart` | API keys and security configuration |
| `lib/services/emergency_service.dart` | Emergency response and campus security integration |
| `lib/services/student_verification_service.dart` | SPU student ID verification |
| `lib/models/student.dart` | Student data model with verification status |
| `lib/models/safety_event.dart` | Safety incidents and emergency events |
| `lib/providers/safety_provider.dart` | Safety state management |
| `android/app/google-services.json` | Firebase Android config |
| `ios/Runner/GoogleService-Info.plist` | Firebase iOS config |

### 🔒 Security Notes

- **Never commit API keys** to version control
- Template files (`.template`) are for reference only
- Actual config files are gitignored for security
- Use environment-specific configurations for production

### 🐛 Debugging

#### Common Issues

**Maps not loading:**
- Verify Google Maps API key is correct
- Check API quotas in Google Cloud Console
- Ensure required APIs are enabled

**Firebase connection failed:**
- Verify `firebase_options.dart` configuration
- Check Firebase project settings
- Ensure google-services.json is up to date

**Build failures:**
```bash
flutter clean
flutter pub get
flutter run
```

### 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

#### Contribution Guidelines

- Follow Flutter/Dart style guidelines
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting
- Never commit API keys or sensitive data

### 📝 API Documentation

#### Core Services

**MeetService** - Handle meetup CRUD operations
```dart
// Create a new meetup
await MeetService.createMeet(meetData);

// Join a meetup
await MeetService.joinMeet(meetId, userId);
```

**ChatService** - Real-time messaging
```dart
// Send message
await ChatService.sendMessage(meetId, message);

// Listen to messages
ChatService.listenToMessages(meetId);
```

**LocationService** - Location tracking
```dart
// Get current location
Position position = await LocationService.getCurrentLocation();

// Start location sharing
await LocationService.startLocationSharing(meetId);
```

### 🧪 Testing Strategy

- **Unit Tests**: Core business logic
- **Widget Tests**: UI components
- **Integration Tests**: End-to-end user flows
- **Manual Testing**: Device-specific features

### 📊 Performance Considerations

- **Location Updates**: Optimized for battery efficiency
- **Image Compression**: Automatic compression for uploads
- **Offline Support**: Basic functionality without internet
- **Memory Management**: Proper disposal of streams and controllers

### 🔄 State Management

The app uses Provider pattern for state management:

```dart
// Auth state
Provider.of<AuthProvider>(context)

// Meet data
Provider.of<MeetProvider>(context)

// Location state
Provider.of<LocationProvider>(context)
```

### 🌍 Internationalization

To add new languages:
1. Add translation files in `lib/l10n/`
2. Update `lib/l10n.yaml`
3. Run `flutter gen-l10n`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Maps for location services
- Open source community for inspiration and tools

## 📞 Contact

- **Project Maintainer**: [Kwanele , LordGeeOne]
- **Email**: [202326493@spu.ac.za]
- **Website**: [your-website.com]


---

**Made with ❤️ using Flutter**

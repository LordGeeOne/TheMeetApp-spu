# TheMeetApp 🛡️

**Open Source Student Safety Platform**

A 100% open source Flutter-based mobile safety application, originally designed for Sol Plaatje University (SPU) students and now available for all educational institutions. Built entirely with open source technologies, prioritizing student safety while facilitating secure social meetups and group coordination.

## 🌟 Features

### Core Safety Features
- **Real-time Location Sharing**: Share your location with trusted contacts during meetups
- **Emergency Alert System**: Quick access to emergency services and safety contacts
- **Group Safety Coordination**: Coordinate safe meetups with multiple participants
- **Safe Route Planning**: Get the safest routes around campus and city areas
- **Check-in System**: Regular safety check-ins with friends and family

### Communication Features
- **Secure Messaging**: Encrypted communication between users
- **Group Chats**: Create and manage group conversations for events
- **Event Planning**: Plan and coordinate safe social gatherings
- **User Verification**: SPU student verification system

### Privacy & Security
- **Data Encryption**: All personal data is encrypted and secure
- **Privacy Controls**: Granular control over what you share and with whom
- **Anonymous Reporting**: Report safety concerns anonymously
- **GDPR Compliant**: Full compliance with data protection regulations

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Firebase account (for backend services)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/LordGeeOne/TheMeetApp-spu.git
   cd TheMeetApp-spu
   ```

2. **Navigate to the Flutter project**
   ```bash
   cd the_meet_app
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure Firebase**
   - Copy `android/app/google-services.json.template` to `android/app/google-services.json`
   - Add your Firebase configuration
   - Update Firebase settings in the project

5. **Run the application**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
meetapp-spu/
├── docs/                          # GitHub Pages documentation
│   ├── index.html                 # Project website
│   ├── styles.css                 # Website styling
│   └── script.js                  # Website interactions
├── the_meet_app/                  # Flutter application
│   ├── lib/
│   │   ├── main.dart             # App entry point
│   │   ├── config/               # App configuration
│   │   ├── models/               # Data models
│   │   ├── pages/                # App pages/screens
│   │   ├── providers/            # State management
│   │   ├── services/             # API and backend services
│   │   ├── utils/                # Utility functions
│   │   └── widgets/              # Reusable UI components
│   ├── android/                  # Android-specific configuration
│   ├── ios/                      # iOS-specific configuration
│   └── test/                     # Test files
├── firebase.json                 # Firebase configuration
├── firestore.indexes.json        # Firestore database indexes
└── storage.rules                 # Firebase Storage rules
```

## 🔧 Development Setup

### Environment Setup
Run the setup script for your platform:
- **Windows**: `setup.bat`
- **Unix/Linux/macOS**: `setup.sh`

### Firebase Configuration
1. Create a new Firebase project
2. Enable the following services:
   - Authentication
   - Firestore Database
   - Cloud Storage
   - Cloud Messaging (for notifications)
3. Download and configure your `google-services.json` file

### Running Tests
```bash
cd the_meet_app
flutter test
```

### Building for Production
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (requires macOS and Xcode)
flutter build ios --release
```

## 🌐 GitHub Pages

The project documentation is hosted on GitHub Pages at: `https://lordgeeone.github.io/TheMeetApp-spu/`

The documentation website showcases:
- Project overview and features
- Safety information and guidelines
- Developer information
- Contact and support details

## 🤝 Contributing

We welcome contributions from the community! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### Development Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🌍 Contributing Back to Open Source

TheMeetApp not only uses open source technologies but also contributes valuable data back to the community:

### Map & Location Data
- **Safe Route Mapping**: Contributing to OpenStreetMap's pedestrian routing
- **Safety POI Database**: Enhancement of location safety information
- **Accessibility Data**: Infrastructure accessibility information

### Safety Analytics
- **Incident Heat Maps**: Anonymous safety incident data for research
- **Temporal Patterns**: Time-based safety analysis
- **Emergency Response**: Response time and effectiveness metrics

### Infrastructure Data
- **Street Lighting**: Real-time infrastructure status
- **Emergency Resources**: Location and status of safety resources
- **Public Transport**: Safety ratings for transit stops

### Community Insights
- **Safety Patterns**: Documented safety strategies
- **Urban Planning**: Anonymous movement pattern data
- **Initiative Impact**: Community safety program effectiveness

### Data Ethics & Privacy
- All shared data is anonymized and aggregated
- Opt-in data sharing policy
- No personal information sharing
- Regular transparency reports
- Research API with privacy controls

## 📊 Data Collection & Usage

TheMeetApp collects and processes the following types of data to enhance community safety:

1. **Location Data**
   - Anonymous route information
   - Safety-related Points of Interest
   - Infrastructure status updates

2. **Safety Metrics**
   - Incident reports (anonymized)
   - Emergency response times
   - Community alert patterns

3. **Infrastructure Data**
   - Street lighting status
   - Emergency resource locations
   - Public transport safety ratings

4. **Usage Patterns**
   - Aggregate movement flows
   - Peak safety hours
   - Common safe routes

### Data Processing
- All data is anonymized at collection
- Regular aggregation of statistics
- Removal of identifying information
- Secure storage and transmission

### Research Contributions
- Urban safety pattern analysis
- Emergency response optimization
- Infrastructure improvement recommendations
- Community safety best practices

## 📱 Platform Support

- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 11.0+ (iPhone 6s and newer)

## 🔒 Privacy & Security

MeetApp SPU takes user privacy and security seriously:
- All personal data is encrypted
- Location data is only shared with explicit consent
- No data is sold to third parties
- Users have full control over their privacy settings
- Regular security audits and updates

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- **Issues**: [GitHub Issues](https://github.com/LordGeeOne/TheMeetApp-spu/issues)
- **Documentation**: [Project Wiki](https://github.com/LordGeeOne/TheMeetApp-spu/wiki)
- **Email**: support@meetapp-spu.com

## 🎯 Roadmap

- [ ] Enhanced emergency response features
- [ ] Integration with campus security systems
- [ ] Multi-language support
- [ ] Web application version
- [ ] Advanced analytics dashboard
- [ ] IoT device integration (smart watches, etc.)

## 🏫 About Sol Plaatje University

Sol Plaatje University (SPU) is a public university in Kimberley, Northern Cape, South Africa. This application is designed specifically to enhance student safety and security on and around the SPU campus.

## 🙏 Acknowledgments

- Sol Plaatje University for inspiration and support
- Flutter and Firebase teams for excellent frameworks
- The open-source community for valuable libraries and tools
- SPU students for feedback and testing

---

**Made with ❤️ for SPU students**

*For a safer, more connected campus experience.*

## 🔧 Open Source Stack

### Core Technologies
- **Flutter & Dart** - UI framework and programming language
- **VS Code** - Primary development environment
- **Git** - Version control system

### Backend & Database
- **Supabase** - Open source Firebase alternative
  - Real-time database with PostgreSQL
  - Authentication and user management
  - File storage solution
- **Redis** - In-memory data structure store
- **Matrix** - Decentralized communication protocol

### Maps & Location
- **OpenStreetMap** - Free world map data
- **Maplibre GL** - Map rendering
- **Nominatim** - Geocoding service

### Security & Authentication
- **Keycloak** - Identity and access management
- **OpenSSL** - Cryptography toolkit
- **Signal Protocol** - End-to-end encryption

### Development Tools
- **Docker** - Containerization
- **GitLab CI** - Continuous Integration/Deployment
- **Prometheus & Grafana** - Monitoring

### Testing & Quality
- **Jest** - Testing framework
- **Selenium** - Automated testing
- **SonarQube** - Code quality analysis

### Benefits of Our Open Source Stack
- Complete transparency and auditability
- No vendor lock-in
- Community-driven security
- Freedom to modify and adapt
- Long-term sustainability

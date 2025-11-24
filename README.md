# MCS App

A modern Flutter mobile application built with clean architecture principles, featuring Firebase backend integration and Provider state management.

## Tech Stack

- **Framework**: Flutter 3.35.7
- **Language**: Dart ^3.9.2
- **Architecture**: MVC (Model-View-Controller)
- **State Management**: Provider
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
- **UI**: Material Design 3

## Setup Instructions

### Prerequisites

- Flutter SDK (3.35.7 or higher)
- Dart SDK (3.9.2 or higher)
- Android Studio (for Android development)
- Xcode (for iOS development - macOS only)
- Firebase project
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Sergetec/mcs-app.git
   cd mcs-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup

This project uses Firebase (`mcs-app-f1e37`) with the following services:

1. **Authentication**
   - Email/Password sign-in method
   - Custom claims for role-based access (admin, patient, doctor)

2. **Firestore Database**
   - Users collection (`users/`)
   - Doctors collection (`doctors/`)
   - Security rules defined in `firestore.rules`

3. **Firebase Storage**
   - For medical documents and images (future implementation)

## Running the App

### Development

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device_id>

# Run in debug mode with hot reload
flutter run --debug
```

### Build

```bash
# Build APK for Android
flutter build apk

# Build App Bundle for Google Play Store
flutter build appbundle

# Build for iOS
flutter build ios
```

## Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## Dependencies

### Core Dependencies
- `provider: ^6.1.2` - State management
- `firebase_core: ^4.2.1` - Firebase core functionality
- `firebase_auth: ^6.1.2` - Firebase authentication
- `cloud_firestore: ^6.1.0` - Cloud Firestore database
- `firebase_storage: ^13.0.4` - Firebase storage
- `google_fonts: ^6.2.1` - Google Fonts
- `intl: ^0.20.2` - Internationalization and date formatting
- `shared_preferences: ^2.3.3` - Local storage for app preferences
- `easy_localization: ^3.0.7` - Multi-language support (RO/EN)

### Dev Dependencies
- `flutter_lints: ^5.0.0` - Linting rules
- `flutter_test` - Testing framework

## Security

### Firebase Configuration
- Firebase config files are **auto-generated** and **not committed to Git**:
  - `lib/firebase_options.dart`
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
- Run `flutterfire configure` to regenerate these files locally

### Firestore Security Rules
Security rules are defined in `firestore.rules`:
- `users/` - Users can only read/write their own data
- `doctors/` - Read: all authenticated users, Write: admins only
- Custom claim `isAdmin: true` required for admin operations

Deploy rules:
```bash
firebase deploy --only firestore:rules
```

---

**Note**: This project is configured for mobile platforms (Android & iOS).

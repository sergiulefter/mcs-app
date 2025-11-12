# MCS App

A modern Flutter mobile application built with clean architecture principles, featuring Firebase backend integration and Provider state management.

## 🚀 Tech Stack

- **Framework**: Flutter 3.35.7
- **Language**: Dart ^3.9.2
- **Architecture**: MVC (Model-View-Controller)
- **State Management**: Provider
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
- **UI**: Material Design 3

## 📱 Features

- ✅ User Authentication (Email/Password)
  - Sign Up
  - Sign In
  - Sign Out
  - Password Reset (UI ready)
- ✅ Form Validation
- ✅ Error Handling
- ✅ Loading States
- ✅ Persistent Authentication

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration (auto-generated)
├── models/                      # Data models
│   └── user_model.dart
├── views/                       # UI layer
│   └── screens/
│       ├── login_screen.dart
│       ├── signup_screen.dart
│       └── home_screen.dart
├── controllers/                 # State management (Provider)
│   └── auth_controller.dart
├── services/                    # Business logic & Firebase services
│   ├── auth_service.dart
│   └── firebase_service.dart
└── utils/                       # Utilities & helpers
    ├── constants.dart
    └── validators.dart
```

## 🛠️ Setup Instructions

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

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Configure Firebase**
   - Ensure Firebase CLI is installed: `npm install -g firebase-tools`
   - Login to Firebase: `firebase login`
   - Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
   - Configure your Firebase project: `flutterfire configure`

5. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup

This project requires a Firebase project with the following services enabled:

1. **Authentication**
   - Enable Email/Password sign-in method in Firebase Console

2. **Firestore Database**
   - Create a Firestore database (start in test mode for development)

3. **Firebase Storage** (optional, for future features)
   - Enable Firebase Storage if needed

## 🏃 Running the App

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

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## 📦 Dependencies

### Core Dependencies
- `provider: ^6.1.2` - State management
- `firebase_core: ^3.8.1` - Firebase core functionality
- `firebase_auth: ^5.3.3` - Firebase authentication
- `cloud_firestore: ^5.5.2` - Cloud Firestore database
- `firebase_storage: ^12.3.6` - Firebase storage
- `google_fonts: ^6.2.1` - Google Fonts
- `intl: ^0.19.0` - Internationalization
- `flutter_dotenv: ^5.1.0` - Environment variables

### Dev Dependencies
- `flutter_lints: ^5.0.0` - Linting rules

## 🔐 Security

- Firebase configuration is managed through `firebase_options.dart` (auto-generated)
- Sensitive keys should be stored in `.env` file (not committed to git)
- `.gitignore` is configured to exclude sensitive files

---

**Note**: This project is configured for mobile platforms (Android & iOS).

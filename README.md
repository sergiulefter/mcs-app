# Medical Correct Solution

A Flutter mobile application for medical second opinion consultations, featuring Firebase backend integration with Cloud Functions for secure admin operations.

## Tech Stack

- **Framework**: Flutter 3.35.7
- **Language**: Dart ^3.9.2
- **Architecture**: MVC (Model-View-Controller)
- **State Management**: Provider
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Cloud Functions (Node.js 20, TypeScript)
  - Firebase Storage
- **UI**: Material Design 3
- **Localization**: Romanian (RO) / English (EN)

## Setup Instructions

### Prerequisites

- Flutter SDK (3.35.7 or higher)
- Dart SDK (3.9.2 or higher)
- Node.js 20 (for Cloud Functions)
- Android Studio (for Android development)
- Xcode (for iOS development - macOS only)
- Firebase CLI (`npm install -g firebase-tools`)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Sergetec/mcs-app.git
   cd mcs-app
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Cloud Functions dependencies**
   ```bash
   cd functions
   npm install
   cd ..
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup

This project uses Firebase (`mcs-app-f1e37`) with the following services:

1. **Authentication**
   - Email/Password sign-in method
   - Custom claims for role-based access (`isAdmin: true`)

2. **Firestore Database**
   - `users/` - Patient profiles
   - `doctors/` - Doctor profiles
   - `consultations/` - Consultation requests
   - Security rules defined in `firestore.rules`

3. **Cloud Functions** (europe-west1)
   - `createDoctor` - Create doctor accounts (admin only)
   - `deleteDoctor` - Delete doctor with Auth cleanup (admin only)
   - `deleteUser` - Delete patient with Auth cleanup (admin only)
   - `setAdminClaim` - Set admin custom claims (admin only)

4. **Firebase Storage**
   - For medical documents and images

## Cloud Functions

Admin operations are handled securely via Cloud Functions using Firebase Admin SDK.

### Deploy Functions

```bash
cd functions
npm run build
firebase deploy --only functions --project mcs-app-f1e37
```

### Available Functions

| Function | Purpose | Auth Required |
|----------|---------|---------------|
| `createDoctor` | Create doctor Firebase Auth + Firestore profile | Admin |
| `deleteDoctor` | Delete doctor Auth account + Firestore document | Admin |
| `deleteUser` | Delete patient Auth account + Firestore document | Admin |
| `setAdminClaim` | Set `isAdmin: true` custom claim on user | Admin |

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
- `cloud_functions: ^6.0.4` - Cloud Functions client
- `firebase_storage: ^13.0.4` - Firebase storage
- `google_fonts: ^6.2.1` - Google Fonts
- `intl: ^0.20.2` - Internationalization and date formatting
- `shared_preferences: ^2.3.3` - Local storage for app preferences
- `easy_localization: ^3.0.7` - Multi-language support (RO/EN)
- `table_calendar: ^3.0.9` - Calendar widget

### Dev Dependencies
- `flutter_lints: ^5.0.0` - Linting rules
- `flutter_test` - Testing framework

## Security

### Firestore Security Rules
Security rules are defined in `firestore.rules`:
- `users/` - Users can only read/write their own data
- `doctors/` - Read: all authenticated users, Write: admins only
- `consultations/` - Role-based access for patients and doctors
- Custom claim `isAdmin: true` required for admin operations

Deploy rules:
```bash
firebase deploy --only firestore:rules --project mcs-app-f1e37
```

### Admin Operations
All privileged operations (creating/deleting users, setting admin claims) are handled server-side via Cloud Functions, ensuring:
- Admin passwords never sent to client
- Firebase Auth accounts properly deleted (not just Firestore docs)
- Server-side validation of all inputs

## Project Structure

```
mcs-app/
├── lib/
│   ├── controllers/     # Provider controllers
│   ├── models/          # Data models
│   ├── services/        # Firebase services
│   ├── utils/           # Utilities and constants
│   └── views/           # UI screens and widgets
├── functions/           # Cloud Functions (TypeScript)
│   ├── src/
│   │   ├── admin/       # Admin operation functions
│   │   └── index.ts     # Function exports
│   └── package.json
├── assets/
│   └── translations/    # Localization files (en.json, ro.json)
├── firestore.rules      # Firestore security rules
└── firebase.json        # Firebase configuration
```

---

**Note**: This project is configured for mobile platforms (Android & iOS).

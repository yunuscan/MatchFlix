# 🔥 Firebase Setup Instructions

## Quick Setup Guide

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name it "MatchFlix"
4. Follow the setup wizard

### 2. Enable Firebase Services

#### Authentication:
1. Go to **Authentication** → **Sign-in method**
2. Click **Anonymous** → Enable → Save

#### Firestore Database:
1. Go to **Firestore Database** → Create database
2. Select **Start in test mode** (for development)
3. Choose a location close to your users

### 3. Add Firebase to Flutter App

#### For Android:

1. In Firebase Console, click the Android icon
2. Register app with package name: `com.example.matchflix`
3. Download `google-services.json`
4. Place file here: `android/app/google-services.json`

#### For iOS:

1. In Firebase Console, click the iOS icon
2. Register app with bundle ID: `com.example.matchflix`
3. Download `GoogleService-Info.plist`
4. Place file here: `ios/Runner/GoogleService-Info.plist`

### 4. Configure Firestore Security Rules

Go to **Firestore Database** → **Rules** and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /rooms/{roomId} {
      // Anyone authenticated can read rooms
      allow read: if request.auth != null;
      
      // Anyone authenticated can create rooms
      allow create: if request.auth != null;
      
      // Only participants can update room
      allow update: if request.auth != null && 
                      request.auth.uid in resource.data.participants;
      
      // Swipes subcollection
      match /swipes/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Matches subcollection
      match /matches/{document=**} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
      }
    }
  }
}
```

Click **Publish**

### 5. Test Your Setup

Run the app:
```bash
flutter pub get
flutter run
```

If you see any Firebase errors, check:
- ✅ `google-services.json` is in `android/app/`
- ✅ `GoogleService-Info.plist` is in `ios/Runner/`
- ✅ Anonymous auth is enabled
- ✅ Firestore is created

---

## Alternative: Using FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase automatically
flutterfire configure --project=matchflix

# This will:
# - Create Firebase project (if needed)
# - Generate firebase_options.dart
# - Configure Android & iOS automatically
```

Then update `main.dart`:
```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

**You're all set! 🎉**

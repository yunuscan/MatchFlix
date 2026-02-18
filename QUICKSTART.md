# 🚀 Quick Start Guide

## Get MatchFlix Running in 5 Minutes!

### Step 1: Install Dependencies (1 min)

```bash
cd MatchFlix
flutter pub get
```

### Step 2: Firebase Setup (3 mins)

**Option A: FlutterFire CLI (Easiest)**
```bash
# Install CLI
dart pub global activate flutterfire_cli

# Auto-configure
flutterfire configure --project=matchflix

# Update main.dart to use firebase_options.dart
```

**Option B: Manual Setup**
1. Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Anonymous Authentication**
3. Create **Firestore Database** (test mode)
4. Download config files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed instructions.

### Step 3: Run the App (1 min)

```bash
# For Android
flutter run

# For iOS (Mac only)
flutter run -d ios
```

### Step 4: Test It Out!

1. Click **"CREATE ROOM"**
2. Copy the 6-digit room code
3. On another device (or emulator), click **"JOIN ROOM"**
4. Enter the code
5. Start swiping! 🎬

---

## ⚡ Quick Commands

```bash
# Clean build
flutter clean && flutter pub get

# Run on specific device
flutter devices
flutter run -d <device-id>

# Build APK
flutter build apk --release

# Build iOS (Mac only)
flutter build ios --release
```

---

## 🔍 Troubleshooting

### "Firebase not configured"
- Check that config files are in the correct locations
- Run `flutter clean && flutter pub get`

### "Movies not loading"
- Check internet connection
- TMDB API key is already configured

### "No matches detected"
- Ensure both users are in the same room
- Both users must swipe right on the same movie

---

## 📱 Test Without Firebase (For Demo)

If you just want to see the UI without Firebase setup:

1. Comment out Firebase initialization in `main.dart`
2. Use mock data in services
3. UI will work, but no real-time sync

---

## ✅ Checklist

- [ ] Flutter SDK installed (>=3.0.0)
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Firebase project created
- [ ] Anonymous auth enabled
- [ ] Firestore database created
- [ ] Config files placed (Android/iOS)
- [ ] App runs successfully
- [ ] Can create and join rooms
- [ ] Swiping works
- [ ] Matches appear

---

**Ready to match some movies! 🍿**

For issues, check the detailed [README.md](README.md) or [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

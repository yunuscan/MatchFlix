# MatchFlix 🎬

**Tinder for Movies** - A Flutter mobile app where two users join a shared room, swipe through movie cards, and get instant matches when both like the same movie!

## 🚀 Features

- **Room System**: Create or join rooms with 6-digit codes
- **Real-time Swiping**: Tinder-like card interface using `flutter_card_swiper`
- **Instant Matches**: Real-time Firestore listeners detect when both users swipe right
- **Match Notifications**: Beautiful match dialog with movie details
- **TMDB Integration**: High-quality movie data with posters and ratings
- **Netflix-style UI**: Dark mode with sleek, modern design
- **Card Flip**: Long-press to see detailed movie information
- **Matches Gallery**: View all your matched movies

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart)
- **State Management**: Provider (MVVM pattern)
- **Backend**: Firebase (Firestore + Firebase Auth)
- **API**: The Movie Database (TMDB)
- **UI Components**: `flutter_card_swiper`, `cached_network_image`

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point with Firebase & Provider setup
├── core/
│   ├── constants/
│   │   └── api_constants.dart         # API keys and configuration
│   ├── theme/
│   │   └── app_theme.dart             # Netflix-style dark theme
│   └── utils/
│       └── helpers.dart               # Utility functions
├── data/
│   ├── models/
│   │   ├── movie_model.dart           # Movie data model
│   │   ├── room_model.dart            # Room data model
│   │   ├── swipe_model.dart           # Swipe tracking model
│   │   └── match_model.dart           # Match tracking model
│   └── services/
│       ├── tmdb_service.dart          # TMDB API service
│       └── firestore_service.dart     # Firestore operations
└── presentation/
    ├── viewmodels/
    │   ├── room_viewmodel.dart        # Room state management
    │   ├── swipe_viewmodel.dart       # Swipe state management
    │   └── match_viewmodel.dart       # Match state management
    ├── screens/
    │   ├── home_screen.dart           # Landing page
    │   ├── room_screen.dart           # Create/Join room
    │   ├── swipe_screen.dart          # Main swiping interface
    │   └── matches_screen.dart        # View all matches
    └── widgets/
        ├── movie_card.dart            # Movie card with flip animation
        ├── match_dialog.dart          # Match notification dialog
        └── loading_indicator.dart     # Custom loading widgets
```

## 🔥 Firestore Database Schema

### `/rooms/{roomId}`
```json
{
  "roomCode": "ABC123",
  "participants": ["userId1", "userId2"],
  "createdAt": Timestamp,
  "isActive": true,
  "filters": {
    "genres": [],
    "minRating": 0.0,
    "providers": []
  }
}
```

### `/rooms/{roomId}/swipes/{userId}`
```json
{
  "likes": [12345, 67890],
  "dislikes": [11111, 22222],
  "lastUpdated": Timestamp
}
```

### `/rooms/{roomId}/matches/data`
```json
{
  "matchedMovieIds": [12345, 67890],
  "lastMatchedAt": Timestamp
}
```

## 🔧 Setup Instructions

### Prerequisites

- Flutter SDK (>=3.0.0)
- Firebase account
- TMDB API key (already included: `cc15a581c49a1dc3085c92b91760c1cb`)

### Step 1: Clone and Install Dependencies

```bash
cd MatchFlix
flutter pub get
```

### Step 2: Firebase Setup

1. **Create a Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project named "MatchFlix"
   - Enable Firebase Authentication (Anonymous sign-in)
   - Enable Cloud Firestore in test mode

2. **Android Configuration**:
   ```bash
   # Download google-services.json from Firebase Console
   # Place it in: android/app/google-services.json
   ```

3. **iOS Configuration**:
   ```bash
   # Download GoogleService-Info.plist from Firebase Console
   # Place it in: ios/Runner/GoogleService-Info.plist
   ```

### Step 3: Firestore Security Rules

In your Firebase Console, set these Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Rooms collection
    match /rooms/{roomId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
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

### Step 4: Enable Firebase Authentication

1. Go to Firebase Console → Authentication
2. Click "Get Started"
3. Enable "Anonymous" sign-in method

### Step 5: Run the App

```bash
# For Android
flutter run

# For iOS
cd ios && pod install && cd ..
flutter run
```

## 🎮 How to Use

1. **Launch the app** and choose "Create Room" or "Join Room"
2. **Share the room code** with a friend (6-digit code)
3. **Wait for both users** to join the room
4. **Start swiping**:
   - Swipe right (or tap ❤️) to like a movie
   - Swipe left (or tap ✕) to pass
   - Long-press a card to see movie details
5. **Get instant matches** when you both like the same movie!
6. **View your matches** by tapping the ❤️ icon

## 🎨 UI Features

- **Netflix-style dark theme** with red accents
- **Smooth card animations** with swipe gestures
- **Card flip animation** (long-press) to reveal movie details
- **Match celebration dialog** with movie poster
- **Real-time stats** showing likes/dislikes count
- **Undo button** to go back to previous card

## 📱 Screenshots

(Add screenshots here after running the app)

## 🔑 TMDB API Key

The app uses the TMDB API to fetch movie data. The API key is already configured in the code:
- **API Key**: `cc15a581c49a1dc3085c92b91760c1cb`
- Located in: `lib/core/constants/api_constants.dart`

## 🐛 Troubleshooting

### Firebase Connection Issues
- Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are correctly placed
- Check that Firebase project has Firestore and Authentication enabled

### Movies Not Loading
- Verify TMDB API key is valid
- Check internet connection
- Review console logs for API errors

### Match Not Detected
- Ensure both users are in the same room
- Check Firestore security rules
- Verify real-time listeners are active

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  http: ^1.1.2
  dio: ^5.4.0
  flutter_card_swiper: ^7.0.0
  cached_network_image: ^3.3.1
  uuid: ^4.3.3
  intl: ^0.19.0
```

## 🚀 Future Enhancements

- [ ] Add genre filtering
- [ ] Implement watch providers (Netflix, Prime, etc.)
- [ ] Add movie trailers
- [ ] Group rooms (3+ users)
- [ ] Chat feature
- [ ] Save favorite movies
- [ ] Share matches on social media

## 📄 License

MIT License - Feel free to use this project for learning and personal use.

## 👨‍💻 Developer

Built with ❤️ using Flutter and Firebase

---

**Happy Matching! 🎬🍿**

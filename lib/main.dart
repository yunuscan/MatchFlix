import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/services/tmdb_service.dart';
import 'data/services/firestore_service.dart';
import 'presentation/viewmodels/room_viewmodel.dart';
import 'presentation/viewmodels/swipe_viewmodel.dart';
import 'presentation/viewmodels/match_viewmodel.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Sign in anonymously for authentication
  await _signInAnonymously();

  runApp(const MatchFlixApp());
}

/// Sign in user anonymously for Firebase authentication
Future<void> _signInAnonymously() async {
  try {
    final auth = FirebaseAuth.instance;

    // Check if already signed in
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      print('✅ Signed in anonymously: ${auth.currentUser?.uid}');
    } else {
      print('✅ Already signed in: ${auth.currentUser?.uid}');
    }
  } catch (e) {
    print('❌ Failed to sign in anonymously: $e');
    // Continue anyway - the app will show errors if auth is required
  }
}

class MatchFlixApp extends StatelessWidget {
  const MatchFlixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<TmdbService>(
          create: (_) => TmdbService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),

        // ViewModels
        ChangeNotifierProvider<RoomViewModel>(
          create: (context) => RoomViewModel(
            context.read<FirestoreService>(),
          ),
        ),
        ChangeNotifierProvider<SwipeViewModel>(
          create: (context) => SwipeViewModel(
            context.read<TmdbService>(),
            context.read<FirestoreService>(),
          ),
        ),
        ChangeNotifierProvider<MatchViewModel>(
          create: (context) => MatchViewModel(
            context.read<FirestoreService>(),
            context.read<TmdbService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'MatchFlix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import '../../data/models/match_model.dart';
import '../../data/models/movie_model.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/tmdb_service.dart';

/// ViewModel for managing matches
class MatchViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final TmdbService _tmdbService;

  MatchViewModel(this._firestoreService, this._tmdbService);

  // State variables
  MatchModel? _matches;
  List<MovieModel> _matchedMovies = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _latestMatchId; // Track the latest match for notifications

  // Getters
  MatchModel? get matches => _matches;
  List<MovieModel> get matchedMovies => _matchedMovies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalMatches => _matches?.totalMatches ?? 0;
  bool get hasMatches => totalMatches > 0;
  int? get latestMatchId => _latestMatchId;

  /// Initialize match listening
  Future<void> initialize(String roomId) async {
    _setLoading(true);
    _clearError();

    try {
      // Listen to matches in real-time
      _listenToMatches(roomId);

      // Load existing matches
      await loadMatches(roomId);

      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize matches: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Listen to matches in real-time
  void _listenToMatches(String roomId) {
    _firestoreService.listenToMatches(roomId).listen(
      (matchModel) {
        final previousMatchCount = _matches?.totalMatches ?? 0;
        _matches = matchModel;

        // Check if there's a new match
        if (matchModel.totalMatches > previousMatchCount) {
          // New match detected!
          _latestMatchId = matchModel.matchedMovieIds.last;
          _loadMatchedMovies(); // Reload matched movies
        }

        notifyListeners();
      },
      onError: (error) {
        _setError('Error listening to matches: $error');
      },
    );
  }

  /// Load matches from Firestore
  Future<void> loadMatches(String roomId) async {
    try {
      final matchModel = await _firestoreService.getMatches(roomId);
      if (matchModel != null) {
        _matches = matchModel;
        await _loadMatchedMovies();
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load matches: $e');
    }
  }

  /// Load full movie details for matched movie IDs
  Future<void> _loadMatchedMovies() async {
    if (_matches == null || _matches!.matchedMovieIds.isEmpty) {
      _matchedMovies = [];
      return;
    }

    try {
      _matchedMovies.clear();

      // Fetch movie details for each matched movie ID
      // Note: TMDB doesn't have a batch endpoint, so we need to search
      // In production, you might want to cache movie details or use a different approach
      for (final movieId in _matches!.matchedMovieIds) {
        try {
          // Try to find the movie in popular movies
          // This is a workaround since we need the full movie details
          final movies = await _tmdbService.fetchPopularMovies(page: 1);
          final movie = movies.firstWhere(
            (m) => m.id == movieId,
            orElse: () => MovieModel(
              id: movieId,
              title: 'Movie #$movieId',
              overview: 'Movie details not available',
              voteAverage: 0,
              voteCount: 0,
              genreIds: [],
              originalLanguage: 'en',
              popularity: 0,
            ),
          );
          _matchedMovies.add(movie);
        } catch (e) {
          print('Failed to load movie $movieId: $e');
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error loading matched movies: $e');
    }
  }

  /// Check if a movie ID is matched
  bool isMatched(int movieId) {
    return _matches?.isMatched(movieId) ?? false;
  }

  /// Clear latest match notification
  void clearLatestMatch() {
    _latestMatchId = null;
    notifyListeners();
  }

  /// Get movie by ID from matched movies
  MovieModel? getMatchedMovie(int movieId) {
    try {
      return _matchedMovies.firstWhere((movie) => movie.id == movieId);
    } catch (e) {
      return null;
    }
  }

  /// Refresh matches
  Future<void> refreshMatches(String roomId) async {
    await loadMatches(roomId);
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

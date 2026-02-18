import 'package:flutter/foundation.dart';
import '../../data/models/movie_model.dart';
import '../../data/models/swipe_model.dart';
import '../../data/services/tmdb_service.dart';
import '../../data/services/firestore_service.dart';

/// ViewModel for managing movie swiping logic
class SwipeViewModel extends ChangeNotifier {
  final TmdbService _tmdbService;
  final FirestoreService _firestoreService;

  SwipeViewModel(this._tmdbService, this._firestoreService);

  // State variables
  List<MovieModel> _movies = [];
  SwipeModel? _currentUserSwipes;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentMovieIndex = 0;
  bool _hasMoreMovies = true;
  int _currentPage = 1;
  Map<int, String> _genreMap = {};
  Map<String, dynamic> _filters = {};

  // Getters
  List<MovieModel> get movies => _movies;
  SwipeModel? get currentUserSwipes => _currentUserSwipes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentMovieIndex => _currentMovieIndex;
  bool get hasMoreMovies => _hasMoreMovies;
  MovieModel? get currentMovie =>
      _movies.isNotEmpty && _currentMovieIndex < _movies.length
          ? _movies[_currentMovieIndex]
          : null;
  Map<int, String> get genreMap => _genreMap;
  int get totalLikes => _currentUserSwipes?.likes.length ?? 0;
  int get totalDislikes => _currentUserSwipes?.dislikes.length ?? 0;

  /// Initialize movie fetching and swipe listening
  Future<void> initialize(String roomId, {Map<String, dynamic> filters = const {}}) async {
    _filters = filters;
    _setLoading(true);
    _clearError();

    try {
      // Fetch genres first
      await _fetchGenres();

      // Fetch initial movies
      await _fetchMovies();

      // Listen to user's swipes
      _listenToSwipes(roomId);

      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch movies from TMDB
  Future<void> _fetchMovies() async {
    try {
      final List<int> genreIds = _filters['selectedGenres'] ?? [];
      final double minRating = _filters['minRating'] ?? 0.0;
      final int yearFrom = _filters['yearFrom'] ?? 1900;
      final int yearTo = _filters['yearTo'] ?? DateTime.now().year;

      List<MovieModel> newMovies;
      
      if (genreIds.isNotEmpty || minRating > 0 || yearFrom != 1900) {
        // Use discover API with filters
        newMovies = await _tmdbService.discoverMovies(
          page: _currentPage,
          genres: genreIds,
          minRating: minRating,
          yearFrom: yearFrom,
          yearTo: yearTo,
        );
      } else {
        // Use popular movies as default
        newMovies = await _tmdbService.fetchPopularMovies(page: _currentPage);
      }

      if (newMovies.isEmpty) {
        _hasMoreMovies = false;
      } else {
        _movies.addAll(newMovies);
        _currentPage++;
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch movies: $e');
    }
  }

  /// Fetch genres from TMDB
  Future<void> _fetchGenres() async {
    try {
      _genreMap = await _tmdbService.fetchGenres();
    } catch (e) {
      print('Failed to fetch genres: $e');
      // Continue without genres
    }
  }

  /// Listen to user's swipes in real-time
  void _listenToSwipes(String roomId) {
    _firestoreService.listenToSwipes(roomId).listen(
      (swipes) {
        _currentUserSwipes = swipes;
        notifyListeners();
      },
      onError: (error) {
        print('Error listening to swipes: $error');
      },
    );
  }

  /// Handle swipe right (like)
  Future<bool> swipeRight(String roomId, MovieModel movie) async {
    return await _handleSwipe(roomId, movie, isLike: true);
  }

  /// Handle swipe left (dislike)
  Future<bool> swipeLeft(String roomId, MovieModel movie) async {
    return await _handleSwipe(roomId, movie, isLike: false);
  }

  /// Handle swipe action
  Future<bool> _handleSwipe(String roomId, MovieModel movie,
      {required bool isLike}) async {
    try {
      // Check if already swiped
      if (_currentUserSwipes?.hasSwipedOn(movie.id) ?? false) {
        print('Already swiped on this movie');
        _moveToNextMovie();
        return false;
      }

      // Record swipe in Firestore
      final isMatch = await _firestoreService.recordSwipe(
        roomId: roomId,
        movieId: movie.id,
        isLike: isLike,
      );

      // Move to next movie
      _moveToNextMovie();

      // Fetch more movies if running low
      if (_movies.length - _currentMovieIndex < 5 && _hasMoreMovies) {
        await _fetchMovies();
      }

      return isMatch; // Return true if it's a match
    } catch (e) {
      _setError('Failed to record swipe: $e');
      return false;
    }
  }

  /// Move to next movie
  void _moveToNextMovie() {
    if (_currentMovieIndex < _movies.length - 1) {
      _currentMovieIndex++;
      notifyListeners();
    } else if (_hasMoreMovies) {
      // Fetch more movies if at the end
      _fetchMovies();
    }
  }

  /// Reset to first movie (for debugging/testing)
  void resetToStart() {
    _currentMovieIndex = 0;
    notifyListeners();
  }

  /// Check if movie was already swiped
  bool hasSwipedOn(int movieId) {
    return _currentUserSwipes?.hasSwipedOn(movieId) ?? false;
  }

  /// Check if movie was liked
  bool isLiked(int movieId) {
    return _currentUserSwipes?.isLiked(movieId) ?? false;
  }

  /// Reload more movies
  Future<void> loadMoreMovies() async {
    if (_isLoading || !_hasMoreMovies) return;

    _setLoading(true);
    try {
      await _fetchMovies();
    } catch (e) {
      _setError('Failed to load more movies: $e');
    } finally {
      _setLoading(false);
    }
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
    _tmdbService.dispose();
    super.dispose();
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';
import '../../core/constants/api_constants.dart';

/// Service for fetching movies from TMDB API
class TmdbService {
  final http.Client _client;

  TmdbService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch popular movies from TMDB
  ///
  /// Returns a list of popular movies. Handles pagination and errors.
  /// Throws an exception if the API call fails.
  Future<List<MovieModel>> fetchPopularMovies({int page = 1}) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.tmdbBaseUrl}${ApiConstants.popularMoviesEndpoint}'
        '?api_key=${ApiConstants.tmdbApiKey}'
        '&language=en-US'
        '&page=$page',
      );

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List<dynamic>;
        return results.map((movie) => MovieModel.fromJson(movie)).toList();
      } else {
        throw Exception(
            'Failed to load popular movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching popular movies: $e');
    }
  }

  /// Fetch top-rated movies from TMDB
  ///
  /// Returns a list of top-rated movies with ratings above 7.0
  Future<List<MovieModel>> fetchTopRatedMovies({int page = 1}) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.tmdbBaseUrl}${ApiConstants.topRatedMoviesEndpoint}'
        '?api_key=${ApiConstants.tmdbApiKey}'
        '&language=en-US'
        '&page=$page',
      );

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List<dynamic>;
        return results.map((movie) => MovieModel.fromJson(movie)).toList();
      } else {
        throw Exception(
            'Failed to load top-rated movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching top-rated movies: $e');
    }
  }

  /// Discover movies with filters (genres, rating, year, etc.)
  ///
  /// Fetches movies based on custom filters:
  /// - [genres]: List of genre IDs to filter by
  /// - [minRating]: Minimum vote average (0-10)
  /// - [yearFrom]: Minimum release year
  /// - [yearTo]: Maximum release year
  /// - [page]: Page number for pagination
  Future<List<MovieModel>> discoverMovies({
    List<int>? genres,
    double? minRating,
    int? yearFrom,
    int? yearTo,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, String>{
        'api_key': ApiConstants.tmdbApiKey,
        'language': 'en-US',
        'sort_by': 'popularity.desc',
        'include_adult': 'false',
        'include_video': 'false',
        'page': page.toString(),
      };

      // Add genre filter if provided
      if (genres != null && genres.isNotEmpty) {
        queryParams['with_genres'] = genres.join(',');
      }

      // Add rating filter if provided
      if (minRating != null && minRating > 0) {
        queryParams['vote_average.gte'] = minRating.toString();
        queryParams['vote_count.gte'] =
            '100'; // Ensure enough votes for credibility
      }

      // Add year filters if provided
      if (yearFrom != null && yearFrom > 1900) {
        queryParams['primary_release_date.gte'] = '$yearFrom-01-01';
      }
      if (yearTo != null && yearTo < DateTime.now().year + 1) {
        queryParams['primary_release_date.lte'] = '$yearTo-12-31';
      }

      final url = Uri.parse(
        '${ApiConstants.tmdbBaseUrl}${ApiConstants.discoverMoviesEndpoint}',
      ).replace(queryParameters: queryParams);

      print('🌐 TMDB API Request: $url');

      final response = await _client.get(url);

      print('📥 TMDB Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List<dynamic>;
        print('✅ TMDB returned ${results.length} movies');
        return results.map((movie) => MovieModel.fromJson(movie)).toList();
      } else {
        print('❌ TMDB Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to discover movies: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ TMDB Exception: $e');
      throw Exception('Error discovering movies: $e');
    }
  }

  /// Fetch movie genres from TMDB
  ///
  /// Returns a map of genre ID to genre name
  /// Example: {28: 'Action', 12: 'Adventure', ...}
  Future<Map<int, String>> fetchGenres() async {
    try {
      final url = Uri.parse(
        '${ApiConstants.tmdbBaseUrl}${ApiConstants.genresEndpoint}'
        '?api_key=${ApiConstants.tmdbApiKey}'
        '&language=en-US',
      );

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final genres = jsonData['genres'] as List<dynamic>;

        return Map.fromEntries(
          genres.map((genre) => MapEntry(
                genre['id'] as int,
                genre['name'] as String,
              )),
        );
      } else {
        throw Exception('Failed to load genres: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching genres: $e');
    }
  }

  /// Search movies by title
  ///
  /// Returns a list of movies matching the search query
  Future<List<MovieModel>> searchMovies(String query, {int page = 1}) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.tmdbBaseUrl}/search/movie'
        '?api_key=${ApiConstants.tmdbApiKey}'
        '&language=en-US'
        '&query=${Uri.encodeComponent(query)}'
        '&page=$page',
      );

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List<dynamic>;
        return results.map((movie) => MovieModel.fromJson(movie)).toList();
      } else {
        throw Exception('Failed to search movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching movies: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _client.close();
  }
}

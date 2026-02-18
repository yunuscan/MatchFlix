/// API Configuration Constants
class ApiConstants {
  // TMDB API Configuration
  static const String tmdbApiKey = 'cc15a581c49a1dc3085c92b91760c1cb';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const String tmdbImageOriginalUrl =
      'https://image.tmdb.org/t/p/original';

  // TMDB Endpoints
  static const String popularMoviesEndpoint = '/movie/popular';
  static const String topRatedMoviesEndpoint = '/movie/top_rated';
  static const String discoverMoviesEndpoint = '/discover/movie';
  static const String genresEndpoint = '/genre/movie/list';

  // Room Configuration
  static const int roomCodeLength = 6;
  static const int maxParticipants = 2;

  // Pagination
  static const int moviesPerPage = 20;
}

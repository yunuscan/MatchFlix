import 'dart:math';

/// Utility helper functions
class Helpers {
  /// Generates a random room code with specified length
  static String generateRoomCode(int length) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Validates room code format
  static bool isValidRoomCode(String code) {
    if (code.isEmpty || code.length < 4 || code.length > 8) {
      return false;
    }
    return RegExp(r'^[A-Z0-9]+$').hasMatch(code);
  }

  /// Formats rating to one decimal place
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Formats date to readable string
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  /// Converts genre IDs to names
  static String getGenreNames(List<int> genreIds, Map<int, String> genreMap) {
    return genreIds
        .map((id) => genreMap[id])
        .where((name) => name != null)
        .take(3)
        .join(', ');
  }
}

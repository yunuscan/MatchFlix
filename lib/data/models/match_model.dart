import 'package:cloud_firestore/cloud_firestore.dart';

/// Match model for tracking matched movies
class MatchModel {
  final String roomId;
  final List<int> matchedMovieIds;
  final DateTime lastMatchedAt;

  MatchModel({
    required this.roomId,
    required this.matchedMovieIds,
    required this.lastMatchedAt,
  });

  /// Create MatchModel from Firestore document
  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel(
      roomId: doc.id,
      matchedMovieIds: (data['matchedMovieIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      lastMatchedAt:
          (data['lastMatchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert MatchModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'matchedMovieIds': matchedMovieIds,
      'lastMatchedAt': Timestamp.fromDate(lastMatchedAt),
    };
  }

  /// Check if movie is already matched
  bool isMatched(int movieId) => matchedMovieIds.contains(movieId);

  /// Get total matches count
  int get totalMatches => matchedMovieIds.length;

  /// Create a copy with modifications
  MatchModel copyWith({
    String? roomId,
    List<int>? matchedMovieIds,
    DateTime? lastMatchedAt,
  }) {
    return MatchModel(
      roomId: roomId ?? this.roomId,
      matchedMovieIds: matchedMovieIds ?? this.matchedMovieIds,
      lastMatchedAt: lastMatchedAt ?? this.lastMatchedAt,
    );
  }

  @override
  String toString() =>
      'MatchModel(roomId: $roomId, matches: ${matchedMovieIds.length})';
}

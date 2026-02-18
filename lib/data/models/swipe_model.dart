import 'package:cloud_firestore/cloud_firestore.dart';

/// Swipe data model for tracking user swipes
class SwipeModel {
  final String userId;
  final List<int> likes;
  final List<int> dislikes;
  final DateTime lastUpdated;

  SwipeModel({
    required this.userId,
    required this.likes,
    required this.dislikes,
    required this.lastUpdated,
  });

  /// Create SwipeModel from Firestore document
  factory SwipeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SwipeModel(
      userId: doc.id,
      likes: (data['likes'] as List<dynamic>?)?.map((e) => e as int).toList() ??
          [],
      dislikes:
          (data['dislikes'] as List<dynamic>?)?.map((e) => e as int).toList() ??
              [],
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert SwipeModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'likes': likes,
      'dislikes': dislikes,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Check if movie was liked
  bool isLiked(int movieId) => likes.contains(movieId);

  /// Check if movie was disliked
  bool isDisliked(int movieId) => dislikes.contains(movieId);

  /// Check if movie was already swiped
  bool hasSwipedOn(int movieId) =>
      likes.contains(movieId) || dislikes.contains(movieId);

  /// Create a copy with modifications
  SwipeModel copyWith({
    String? userId,
    List<int>? likes,
    List<int>? dislikes,
    DateTime? lastUpdated,
  }) {
    return SwipeModel(
      userId: userId ?? this.userId,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() =>
      'SwipeModel(userId: $userId, likes: ${likes.length}, dislikes: ${dislikes.length})';
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Room model for Firestore
class RoomModel {
  final String roomId;
  final String roomCode;
  final List<String> participants;
  final DateTime createdAt;
  final RoomFilters filters;
  final bool isActive;

  RoomModel({
    required this.roomId,
    required this.roomCode,
    required this.participants,
    required this.createdAt,
    required this.filters,
    this.isActive = true,
  });

  /// Create RoomModel from Firestore document
  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      roomId: doc.id,
      roomCode: data['roomCode'] as String? ?? '',
      participants: (data['participants'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      filters:
          RoomFilters.fromJson(data['filters'] as Map<String, dynamic>? ?? {}),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Convert RoomModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'roomCode': roomCode,
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'filters': filters.toJson(),
      'isActive': isActive,
    };
  }

  /// Check if room is full
  bool get isFull => participants.length >= 2;

  /// Check if user is participant
  bool hasParticipant(String userId) => participants.contains(userId);

  /// Create a copy with modifications
  RoomModel copyWith({
    String? roomId,
    String? roomCode,
    List<String>? participants,
    DateTime? createdAt,
    RoomFilters? filters,
    bool? isActive,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      filters: filters ?? this.filters,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'RoomModel(roomId: $roomId, code: $roomCode, participants: ${participants.length})';
}

/// Room filter configuration
class RoomFilters {
  final List<int> genres;
  final double minRating;
  final int? yearFrom;
  final int? yearTo;
  final List<String> providers;

  RoomFilters({
    this.genres = const [],
    this.minRating = 0.0,
    this.yearFrom,
    this.yearTo,
    this.providers = const [],
  });

  factory RoomFilters.fromJson(Map<String, dynamic> json) {
    return RoomFilters(
      genres:
          (json['genres'] as List<dynamic>?)?.map((e) => e as int).toList() ??
              [],
      minRating: (json['minRating'] as num?)?.toDouble() ?? 0.0,
      yearFrom: json['yearFrom'] as int?,
      yearTo: json['yearTo'] as int?,
      providers: (json['providers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Create RoomFilters from UI filter map
  factory RoomFilters.fromFilterMap(Map<String, dynamic> filterMap) {
    final selectedGenres = filterMap['selectedGenres'] as List<int>? ?? [];
    final minRating = filterMap['minRating'] as double? ?? 0.0;
    final yearFrom = filterMap['yearFrom'] as int?;
    final yearTo = filterMap['yearTo'] as int?;

    return RoomFilters(
      genres: selectedGenres,
      minRating: minRating,
      yearFrom: yearFrom,
      yearTo: yearTo,
    );
  }

  /// Convert to UI filter map format
  Map<String, dynamic> toFilterMap() {
    return {
      'selectedGenres': genres,
      'minRating': minRating,
      'yearFrom': yearFrom,
      'yearTo': yearTo,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'genres': genres,
      'minRating': minRating,
      'yearFrom': yearFrom,
      'yearTo': yearTo,
      'providers': providers,
    };
  }
}

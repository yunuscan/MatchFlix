import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room_model.dart';
import '../models/swipe_model.dart';
import '../models/match_model.dart';
import '../models/proposal_model.dart';
import '../../core/utils/helpers.dart';
import '../../core/constants/api_constants.dart';

/// Service for managing Firestore operations (rooms, swipes, matches)
class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Collection references
  CollectionReference get _roomsCollection => _firestore.collection('rooms');

  /// Get current user ID (anonymous or authenticated)
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== ROOM MANAGEMENT ====================

  /// Create a new room
  ///
  /// Generates a unique room code and creates a Firestore document.
  /// The creator is automatically added as the first participant.
  /// Returns the created RoomModel.
  Future<RoomModel> createRoom({RoomFilters? filters}) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated to create a room');
    }

    try {
      // Generate unique room code
      String roomCode;
      bool codeExists;
      do {
        roomCode = Helpers.generateRoomCode(ApiConstants.roomCodeLength);
        codeExists = await _checkRoomCodeExists(roomCode);
      } while (codeExists);

      final roomData = RoomModel(
        roomId: '', // Will be set by Firestore
        roomCode: roomCode,
        participants: [currentUserId!],
        createdAt: DateTime.now(),
        filters: filters ?? RoomFilters(),
        isActive: true,
      );

      // Create room document
      final docRef = await _roomsCollection.add(roomData.toFirestore());

      // Initialize swipes subcollection for creator
      await _initializeSwipesForUser(docRef.id, currentUserId!);

      // Initialize matches document
      await _initializeMatchesForRoom(docRef.id);

      return roomData.copyWith(roomId: docRef.id);
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }

  /// Join an existing room by room code
  ///
  /// Finds the room by code and adds the current user as a participant.
  /// Throws an exception if the room is full or not found.
  /// Returns the joined RoomModel.
  Future<RoomModel> joinRoom(String roomCode) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated to join a room');
    }

    try {
      // Find room by code
      final querySnapshot = await _roomsCollection
          .where('roomCode', isEqualTo: roomCode.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Room not found with code: $roomCode');
      }

      final roomDoc = querySnapshot.docs.first;
      final room = RoomModel.fromFirestore(roomDoc);

      // Check if room is full
      if (room.isFull) {
        throw Exception(
            'Room is full (max ${ApiConstants.maxParticipants} participants)');
      }

      // Check if user is already in the room
      if (room.hasParticipant(currentUserId!)) {
        return room; // Already in room
      }

      // Add user to participants
      await roomDoc.reference.update({
        'participants': FieldValue.arrayUnion([currentUserId!]),
      });

      // Initialize swipes subcollection for new participant
      await _initializeSwipesForUser(room.roomId, currentUserId!);

      return room.copyWith(
        participants: [...room.participants, currentUserId!],
      );
    } catch (e) {
      throw Exception('Failed to join room: $e');
    }
  }

  /// Get room by ID
  Future<RoomModel?> getRoom(String roomId) async {
    try {
      final doc = await _roomsCollection.doc(roomId).get();
      if (!doc.exists) return null;
      return RoomModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get room: $e');
    }
  }

  /// Listen to room changes in real-time
  Stream<RoomModel> listenToRoom(String roomId) {
    return _roomsCollection.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('Room not found');
      }
      return RoomModel.fromFirestore(doc);
    });
  }

  /// Leave a room
  Future<void> leaveRoom(String roomId) async {
    if (currentUserId == null) return;

    try {
      await _roomsCollection.doc(roomId).update({
        'participants': FieldValue.arrayRemove([currentUserId!]),
      });

      // Check if room is empty and deactivate
      final room = await getRoom(roomId);
      if (room != null && room.participants.isEmpty) {
        await _roomsCollection.doc(roomId).update({'isActive': false});
      }
    } catch (e) {
      throw Exception('Failed to leave room: $e');
    }
  }

  // ==================== SWIPE MANAGEMENT ====================

  /// Record a swipe (like or dislike)
  ///
  /// Updates the user's swipe document and checks for matches.
  /// If both users liked the same movie, it's added to matches.
  /// Returns true if a new match was created.
  Future<bool> recordSwipe({
    required String roomId,
    required int movieId,
    required bool isLike,
  }) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated to swipe');
    }

    try {
      final swipeDocRef =
          _roomsCollection.doc(roomId).collection('swipes').doc(currentUserId!);

      // Update swipe document
      await swipeDocRef.set({
        'likes': isLike
            ? FieldValue.arrayUnion([movieId])
            : FieldValue.arrayRemove([movieId]),
        'dislikes': !isLike
            ? FieldValue.arrayUnion([movieId])
            : FieldValue.arrayRemove([movieId]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Check for match if it's a like
      if (isLike) {
        return await _checkForMatch(roomId, movieId);
      }

      return false;
    } catch (e) {
      throw Exception('Failed to record swipe: $e');
    }
  }

  /// Get swipes for current user in a room
  Future<SwipeModel?> getSwipes(String roomId) async {
    if (currentUserId == null) return null;

    try {
      final doc = await _roomsCollection
          .doc(roomId)
          .collection('swipes')
          .doc(currentUserId!)
          .get();

      if (!doc.exists) return null;
      return SwipeModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get swipes: $e');
    }
  }

  /// Listen to swipes for current user in real-time
  Stream<SwipeModel> listenToSwipes(String roomId) {
    if (currentUserId == null) {
      throw Exception('User must be authenticated');
    }

    return _roomsCollection
        .doc(roomId)
        .collection('swipes')
        .doc(currentUserId!)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        // Return empty swipe model if not exists
        return SwipeModel(
          userId: currentUserId!,
          likes: [],
          dislikes: [],
          lastUpdated: DateTime.now(),
        );
      }
      return SwipeModel.fromFirestore(doc);
    });
  }

  // ==================== MATCH MANAGEMENT ====================

  /// Get matches for a room
  Future<MatchModel?> getMatches(String roomId) async {
    try {
      final doc = await _roomsCollection
          .doc(roomId)
          .collection('matches')
          .doc('data')
          .get();

      if (!doc.exists) return null;
      return MatchModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get matches: $e');
    }
  }

  /// Listen to matches in real-time
  Stream<MatchModel> listenToMatches(String roomId) {
    return _roomsCollection
        .doc(roomId)
        .collection('matches')
        .doc('data')
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return MatchModel(
          roomId: roomId,
          matchedMovieIds: [],
          lastMatchedAt: DateTime.now(),
        );
      }
      return MatchModel.fromFirestore(doc);
    });
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Check if a room code already exists
  Future<bool> _checkRoomCodeExists(String roomCode) async {
    final querySnapshot = await _roomsCollection
        .where('roomCode', isEqualTo: roomCode)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  /// Initialize swipes subcollection for a user
  Future<void> _initializeSwipesForUser(String roomId, String userId) async {
    await _roomsCollection.doc(roomId).collection('swipes').doc(userId).set({
      'likes': [],
      'dislikes': [],
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Initialize matches document for a room
  Future<void> _initializeMatchesForRoom(String roomId) async {
    await _roomsCollection.doc(roomId).collection('matches').doc('data').set({
      'matchedMovieIds': [],
      'lastMatchedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if a movie creates a match between both users
  ///
  /// Checks if both participants have liked the same movie.
  /// If yes, adds it to the matches collection.
  /// Returns true if a new match was created.
  Future<bool> _checkForMatch(String roomId, int movieId) async {
    try {
      // Get room to find all participants
      final room = await getRoom(roomId);
      if (room == null || room.participants.length < 2) {
        return false; // Need 2 participants for a match
      }

      // Get swipes for all participants
      final swipesSnapshot =
          await _roomsCollection.doc(roomId).collection('swipes').get();

      // Check if all participants liked this movie
      final allParticipantsLiked = room.participants.every((participantId) {
        final swipeDoc = swipesSnapshot.docs.firstWhere(
          (doc) => doc.id == participantId,
          orElse: () => throw Exception('Swipe document not found'),
        );
        final swipe = SwipeModel.fromFirestore(swipeDoc);
        return swipe.isLiked(movieId);
      });

      if (allParticipantsLiked) {
        // Add to matches
        await _roomsCollection
            .doc(roomId)
            .collection('matches')
            .doc('data')
            .update({
          'matchedMovieIds': FieldValue.arrayUnion([movieId]),
          'lastMatchedAt': FieldValue.serverTimestamp(),
        });
        return true; // New match!
      }

      return false;
    } catch (e) {
      // If document doesn't exist or other error, return false
      print('Error checking for match: $e');
      return false;
    }
  }

  // ==================== PROPOSAL MANAGEMENT ====================

  /// Create a movie watch proposal
  Future<ProposalModel> createProposal({
    required String roomId,
    required String movieId,
    required String movieTitle,
    String? moviePoster,
    required String receiverUserId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated');
    }

    try {
      final proposalRef = _roomsCollection
          .doc(roomId)
          .collection('proposals')
          .doc(); // Auto-generate ID

      final proposal = ProposalModel(
        proposalId: proposalRef.id,
        roomId: roomId,
        movieId: movieId,
        movieTitle: movieTitle,
        moviePoster: moviePoster,
        proposerUserId: currentUserId!,
        receiverUserId: receiverUserId,
        status: ProposalStatus.pending,
        createdAt: DateTime.now(),
      );

      await proposalRef.set(proposal.toFirestore());
      return proposal;
    } catch (e) {
      throw Exception('Failed to create proposal: $e');
    }
  }

  /// Respond to a proposal (accept/reject)
  Future<void> respondToProposal({
    required String roomId,
    required String proposalId,
    required ProposalStatus status,
  }) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated');
    }

    if (status != ProposalStatus.accepted &&
        status != ProposalStatus.rejected) {
      throw Exception('Invalid response status');
    }

    try {
      await _roomsCollection
          .doc(roomId)
          .collection('proposals')
          .doc(proposalId)
          .update({
        'status': status.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to respond to proposal: $e');
    }
  }

  /// Cancel a proposal (only proposer can cancel)
  Future<void> cancelProposal({
    required String roomId,
    required String proposalId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated');
    }

    try {
      await _roomsCollection
          .doc(roomId)
          .collection('proposals')
          .doc(proposalId)
          .update({
        'status': ProposalStatus.cancelled.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel proposal: $e');
    }
  }

  /// Listen to proposals for current user (both sent and received)
  Stream<List<ProposalModel>> listenToProposals(String roomId) {
    if (currentUserId == null) {
      throw Exception('User must be authenticated');
    }

    return _roomsCollection
        .doc(roomId)
        .collection('proposals')
        .where(Filter.or(
          Filter('proposerUserId', isEqualTo: currentUserId!),
          Filter('receiverUserId', isEqualTo: currentUserId!),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProposalModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get pending proposals count
  Future<int> getPendingProposalsCount(String roomId) async {
    if (currentUserId == null) return 0;

    try {
      final snapshot = await _roomsCollection
          .doc(roomId)
          .collection('proposals')
          .where('receiverUserId', isEqualTo: currentUserId!)
          .where('status', isEqualTo: ProposalStatus.pending.name)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting pending proposals count: $e');
      return 0;
    }
  }
}

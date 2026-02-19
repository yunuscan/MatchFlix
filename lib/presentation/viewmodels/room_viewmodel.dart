import 'package:flutter/foundation.dart';
import '../../data/models/room_model.dart';
import '../../data/services/firestore_service.dart';

/// ViewModel for managing room state and operations
class RoomViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;

  RoomViewModel(this._firestoreService);

  // State variables
  RoomModel? _currentRoom;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  RoomModel? get currentRoom => _currentRoom;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInRoom => _currentRoom != null;
  bool get isRoomFull => _currentRoom?.isFull ?? false;
  String? get roomCode => _currentRoom?.roomCode;
  int get participantCount => _currentRoom?.participants.length ?? 0;

  /// Create a new room
  Future<void> createRoom({RoomFilters? filters}) async {
    _setLoading(true);
    _clearError();

    try {
      // Debug: Log filters being used to create room
      print('🏠 Creating room with filters:');
      print('   - Genres: ${filters?.genres ?? []}');
      print('   - Min Rating: ${filters?.minRating ?? 0.0}');
      print(
          '   - Year: ${filters?.yearFrom ?? "any"} - ${filters?.yearTo ?? "any"}');

      final room = await _firestoreService.createRoom(filters: filters);
      _currentRoom = room;

      // Start listening to room updates
      _listenToRoom(room.roomId);

      notifyListeners();
    } catch (e) {
      _setError('Failed to create room: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Join an existing room
  Future<void> joinRoom(String roomCode) async {
    _setLoading(true);
    _clearError();

    try {
      final room = await _firestoreService.joinRoom(roomCode);
      _currentRoom = room;

      // Debug: Log received filters
      print('🔍 Joined room with filters:');
      print('   - Genres: ${room.filters.genres}');
      print('   - Min Rating: ${room.filters.minRating}');
      print(
          '   - Year: ${room.filters.yearFrom ?? "any"} - ${room.filters.yearTo ?? "any"}');

      // Start listening to room updates
      _listenToRoom(room.roomId);

      notifyListeners();
    } catch (e) {
      _setError('Failed to join room: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Leave the current room
  Future<void> leaveRoom() async {
    if (_currentRoom == null) return;

    try {
      await _firestoreService.leaveRoom(_currentRoom!.roomId);
      _currentRoom = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to leave room: $e');
    }
  }

  /// Listen to room updates in real-time
  void _listenToRoom(String roomId) {
    _firestoreService.listenToRoom(roomId).listen(
      (room) {
        _currentRoom = room;
        notifyListeners();
      },
      onError: (error) {
        _setError('Room connection error: $error');
      },
    );
  }

  /// Refresh room data
  Future<void> refreshRoom() async {
    if (_currentRoom == null) return;

    try {
      final room = await _firestoreService.getRoom(_currentRoom!.roomId);
      if (room != null) {
        _currentRoom = room;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh room: $e');
    }
  }

  /// Check if both participants are in the room (ready to swipe)
  bool get isReadyToSwipe => _currentRoom?.isFull ?? false;

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

  /// Clear error message
  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/room_model.dart';
import '../viewmodels/room_viewmodel.dart';
import '../widgets/loading_indicator.dart';
import 'swipe_screen.dart';

/// Custom text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Room screen for creating or joining a room
class RoomScreen extends StatefulWidget {
  final bool isCreating;
  final Map<String, dynamic> filters;

  const RoomScreen({
    super.key,
    required this.isCreating,
    this.filters = const {},
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  bool _hasCreatedOrJoined = false;

  @override
  void initState() {
    super.initState();
    if (widget.isCreating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _createRoom();
      });
    }
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final roomViewModel = context.read<RoomViewModel>();

    // Convert UI filters to RoomFilters
    final roomFilters = RoomFilters.fromFilterMap(widget.filters);

    await roomViewModel.createRoom(filters: roomFilters);

    if (roomViewModel.errorMessage == null) {
      setState(() => _hasCreatedOrJoined = true);
    }
  }

  Future<void> _joinRoom() async {
    final roomCode = _roomCodeController.text.trim().toUpperCase();

    if (roomCode.isEmpty) {
      _showError('Please enter a room code');
      return;
    }

    final roomViewModel = context.read<RoomViewModel>();
    await roomViewModel.joinRoom(roomCode);

    if (roomViewModel.errorMessage == null) {
      setState(() => _hasCreatedOrJoined = true);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.dislikeRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.isCreating ? 'Create Room' : 'Join Room'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<RoomViewModel>(
        builder: (context, roomViewModel, child) {
          // Show error if any
          if (roomViewModel.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showError(roomViewModel.errorMessage!);
              roomViewModel.clearError();
            });
          }

          // Navigate to swipe screen when room is ready
          if (roomViewModel.isReadyToSwipe && _hasCreatedOrJoined) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Use filters from the room (applies to both creator and joiner)
              final roomFilters =
                  roomViewModel.currentRoom?.filters.toFilterMap() ?? {};

              print('🎬 Navigating to SwipeScreen with room filters:');
              print('   - Genres: ${roomFilters['selectedGenres']}');
              print('   - Min Rating: ${roomFilters['minRating']}');
              print(
                  '   - Year: ${roomFilters['yearFrom']} - ${roomFilters['yearTo']}');

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => SwipeScreen(filters: roomFilters),
                ),
              );
            });
          }

          if (roomViewModel.isLoading) {
            return const LoadingIndicator(
              message: 'Setting up room...',
            );
          }

          if (widget.isCreating) {
            return _buildWaitingRoom(roomViewModel);
          } else {
            return _buildJoinRoom(roomViewModel);
          }
        },
      ),
    );
  }

  /// Build waiting room UI (for creator)
  Widget _buildWaitingRoom(RoomViewModel roomViewModel) {
    final roomCode = roomViewModel.roomCode ?? '';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.likeGreen.withOpacity(0.2),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.likeGreen,
            ),
          ),
          const SizedBox(height: 32),

          // Room created text
          const Text(
            'Room Created!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Share code instruction
          const Text(
            'Share this code with your friend:',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Room code display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryRed, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  roomCode,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppTheme.primaryRed),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: roomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Room code copied!'),
                        backgroundColor: AppTheme.likeGreen,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Waiting indicator
          const LoadingIndicator(
            message: 'Waiting for someone to join...',
          ),
          const SizedBox(height: 24),

          // Participants count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${roomViewModel.participantCount} / 2 participants',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build join room UI
  Widget _buildJoinRoom(RoomViewModel roomViewModel) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          const Icon(
            Icons.meeting_room,
            size: 100,
            color: AppTheme.primaryRed,
          ),
          const SizedBox(height: 32),

          // Instruction
          const Text(
            'Enter Room Code',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Ask your friend for the 6-digit code',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Room code input
          TextField(
            controller: _roomCodeController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5),
                letterSpacing: 8,
              ),
              filled: true,
              fillColor: AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.primaryRed, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.primaryRed, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.primaryRed, width: 3),
              ),
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              UpperCaseTextFormatter(),
            ],
            onSubmitted: (_) => _joinRoom(),
          ),
          const SizedBox(height: 32),

          // Join button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: roomViewModel.isLoading ? null : _joinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: roomViewModel.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'JOIN ROOM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

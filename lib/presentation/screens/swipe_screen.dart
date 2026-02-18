import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../viewmodels/room_viewmodel.dart';
import '../viewmodels/swipe_viewmodel.dart';
import '../viewmodels/match_viewmodel.dart';
import '../widgets/movie_card.dart';
import '../widgets/match_dialog.dart';
import '../widgets/loading_indicator.dart';
import 'matches_screen.dart';

/// Main swiping screen with Tinder-like card interface
class SwipeScreen extends StatefulWidget {
  final Map<String, dynamic> filters;

  const SwipeScreen({super.key, this.filters = const {}});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _cardController = CardSwiperController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final roomViewModel = context.read<RoomViewModel>();
    final swipeViewModel = context.read<SwipeViewModel>();
    final matchViewModel = context.read<MatchViewModel>();

    if (roomViewModel.currentRoom != null) {
      final roomId = roomViewModel.currentRoom!.roomId;

      await Future.wait([
        swipeViewModel.initialize(roomId, filters: widget.filters),
        matchViewModel.initialize(roomId),
      ]);

      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showExitConfirmation(),
        ),
        title: Consumer<RoomViewModel>(
          builder: (context, roomViewModel, child) {
            return Text('Room: ${roomViewModel.roomCode ?? ""}');
          },
        ),
        actions: [
          // Matches button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.favorite, size: 28),
                Consumer<MatchViewModel>(
                  builder: (context, matchViewModel, child) {
                    if (matchViewModel.totalMatches > 0) {
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.likeGreen,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${matchViewModel.totalMatches}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            onPressed: () => _navigateToMatches(),
          ),
        ],
      ),
      body: !_isInitialized
          ? const LoadingIndicator(message: 'Loading movies...')
          : Consumer<SwipeViewModel>(
              builder: (context, swipeViewModel, child) {
                // Listen for matches
                return Consumer<MatchViewModel>(
                  builder: (context, matchViewModel, child) {
                    // Show match dialog when there's a new match
                    if (matchViewModel.latestMatchId != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final matchedMovie = matchViewModel.getMatchedMovie(
                          matchViewModel.latestMatchId!,
                        );
                        if (matchedMovie != null) {
                          MatchDialog.show(context, matchedMovie);
                        }
                        matchViewModel.clearLatestMatch();
                      });
                    }

                    return _buildSwipeInterface(swipeViewModel);
                  },
                );
              },
            ),
    );
  }

  /// Build the main swipe interface
  Widget _buildSwipeInterface(SwipeViewModel swipeViewModel) {
    if (swipeViewModel.isLoading) {
      return const LoadingIndicator(message: 'Loading movies...');
    }

    if (swipeViewModel.errorMessage != null) {
      return _buildError(swipeViewModel.errorMessage!);
    }

    if (swipeViewModel.movies.isEmpty) {
      return _buildNoMovies();
    }

    return Stack(
      children: [
        // Card swiper
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 150),
            child: CardSwiper(
              controller: _cardController,
              cardsCount: swipeViewModel.movies.length,
              numberOfCardsDisplayed: 3,
              backCardOffset: const Offset(0, 40),
              padding: const EdgeInsets.all(24),
              cardBuilder:
                  (context, index, percentThresholdX, percentThresholdY) {
                return MovieCard(
                  movie: swipeViewModel.movies[index],
                  genreMap: swipeViewModel.genreMap,
                );
              },
              onSwipe: (previousIndex, currentIndex, direction) {
                return _onSwipe(
                  swipeViewModel,
                  previousIndex,
                  direction,
                );
              },
              onUndo: (previousIndex, currentIndex, direction) {
                // Allow undo
                return true;
              },
              isLoop: false,
              allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                horizontal: true,
              ),
            ),
          ),
        ),

        // Stats overlay (top) - FIRST so indicators appear above
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: _buildStatsBar(swipeViewModel),
        ),

        // Swipe indicators overlay (subtle) - SECOND so they appear above stats
        Positioned(
          top: 140,
          left: 40,
          right: 40,
          child: IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dislike indicator (left)
                Opacity(
                  opacity: 0.7,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                      border: Border.all(color: AppTheme.dislikeRed, width: 3),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 32,
                      color: AppTheme.dislikeRed,
                    ),
                  ),
                ),

                // Like indicator (right)
                Opacity(
                  opacity: 0.7,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                      border: Border.all(color: AppTheme.likeGreen, width: 3),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 32,
                      color: AppTheme.likeGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.darkBackground.withOpacity(0.9),
                  AppTheme.darkBackground,
                ],
              ),
            ),
            child: _buildActionButtons(swipeViewModel),
          ),
        ),
      ],
    );
  }

  /// Build action buttons (dislike, info, like)
  Widget _buildActionButtons(SwipeViewModel swipeViewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Dislike button
        _ActionButton(
          icon: Icons.close,
          color: AppTheme.dislikeRed,
          size: 60,
          onPressed: () => _cardController.swipe(CardSwiperDirection.left),
        ),

        // Undo button
        _ActionButton(
          icon: Icons.replay,
          color: AppTheme.textSecondary,
          size: 50,
          onPressed: () => _cardController.undo(),
        ),

        // Like button
        _ActionButton(
          icon: Icons.favorite,
          color: AppTheme.likeGreen,
          size: 60,
          onPressed: () => _cardController.swipe(CardSwiperDirection.right),
        ),
      ],
    );
  }

  /// Build stats bar showing likes/dislikes
  Widget _buildStatsBar(SwipeViewModel swipeViewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.close,
            color: AppTheme.dislikeRed,
            count: swipeViewModel.totalDislikes,
            label: 'Passed',
          ),
          Container(
            width: 1,
            height: 30,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          _StatItem(
            icon: Icons.favorite,
            color: AppTheme.likeGreen,
            count: swipeViewModel.totalLikes,
            label: 'Liked',
          ),
        ],
      ),
    );
  }

  /// Handle swipe action
  bool _onSwipe(
    SwipeViewModel swipeViewModel,
    int previousIndex,
    CardSwiperDirection direction,
  ) {
    final roomViewModel = context.read<RoomViewModel>();
    final roomId = roomViewModel.currentRoom?.roomId;

    if (roomId == null || previousIndex >= swipeViewModel.movies.length) {
      return false;
    }

    final movie = swipeViewModel.movies[previousIndex];

    // Handle swipe asynchronously
    if (direction == CardSwiperDirection.right) {
      swipeViewModel.swipeRight(roomId, movie).then((isMatch) {
        // Match dialog will be shown automatically by the listener
      });
    } else if (direction == CardSwiperDirection.left) {
      swipeViewModel.swipeLeft(roomId, movie);
    }

    return true; // Allow swipe
  }

  /// Build error view
  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.dislikeRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build no movies view
  Widget _buildNoMovies() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.movie_filter_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No more movies',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your matches!',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToMatches(),
            icon: const Icon(Icons.favorite),
            label: const Text('VIEW MATCHES'),
          ),
        ],
      ),
    );
  }

  /// Navigate to matches screen
  void _navigateToMatches() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MatchesScreen(),
      ),
    );
  }

  /// Show exit confirmation dialog
  Future<void> _showExitConfirmation() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room?'),
        content: const Text('Are you sure you want to leave this room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dislikeRed),
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      final roomViewModel = context.read<RoomViewModel>();
      await roomViewModel.leaveRoom();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}

/// Action button widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          padding: EdgeInsets.all(size * 0.25),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.cardBackground,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: size * 0.5,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Stat item widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

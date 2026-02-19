import 'package:flutter/material.dart';
import '../../data/models/movie_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';

/// Enhanced match dialog with confetti animation
class MatchDialog extends StatefulWidget {
  final MovieModel movie;
  final VoidCallback onClose;

  const MatchDialog({
    super.key,
    required this.movie,
    required this.onClose,
  });

  /// Show the match dialog
  static void show(BuildContext context, MovieModel movie) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => MatchDialog(
        movie: movie,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<MatchDialog>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    // Start animations
    _animController.forward();
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti overlay
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 10,
            gravity: 0.3,
            colors: const [
              AppTheme.primaryRed,
              AppTheme.likeGreen,
              Colors.yellow,
              Colors.purple,
              Colors.blue,
            ],
          ),
        ),

        // Dialog content
        Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.cardBackground,
                        AppTheme.deepBlack,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryRed.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryRed.withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsing heart icon
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.2),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppTheme.primaryRed,
                                    AppTheme.primaryRed.withOpacity(0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryRed.withOpacity(0.8),
                                    blurRadius: 30,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        onEnd: () {
                          // Loop the animation
                          if (mounted) {
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // "IT'S A MATCH!" text with glow
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            AppTheme.primaryRed,
                            AppTheme.primaryRed.withOpacity(0.7),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          "IT'S A MATCH!",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: AppTheme.primaryRed,
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'You both loved this movie!',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Movie poster with shadow
                      Hero(
                        tag: 'movie_${widget.movie.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryRed.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: widget.movie.fullPosterPath != null
                                ? CachedNetworkImage(
                                    imageUrl: widget.movie.fullPosterPath!,
                                    height: 280,
                                    width: 190,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 280,
                                      width: 190,
                                      color: AppTheme.deepBlack,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.primaryRed,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 280,
                                    width: 190,
                                    color: AppTheme.deepBlack,
                                    child: const Icon(
                                      Icons.movie,
                                      size: 60,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Movie title
                      Text(
                        widget.movie.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Helpers.formatRating(widget.movie.voteAverage),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onClose,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppTheme.textSecondary,
                                  width: 2,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'KEEP SWIPING',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                widget.onClose();
                                // TODO: Navigate to movie details
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRed,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: 8,
                                shadowColor:
                                    AppTheme.primaryRed.withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'DETAILS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

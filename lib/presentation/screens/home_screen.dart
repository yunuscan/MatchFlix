import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/filter_panel.dart';
import 'room_screen.dart';

/// Home screen with app branding and navigation options
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _filters = {
    'selectedGenres': <int>[],
    'minRating': 0.0,
    'yearFrom': null, // null = no filter
    'yearTo': null, // null = no filter
  };

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterPanel(
        initialFilters: _filters,
        onFiltersChanged: (filters) {
          setState(() {
            _filters = filters;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackground,
              AppTheme.darkBackground.withOpacity(0.8),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // App logo/title
                const Icon(
                  Icons.local_movies_rounded,
                  size: 100,
                  color: AppTheme.primaryRed,
                ),
                const SizedBox(height: 24),

                // App name
                const Text(
                  'MatchFlix',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),

                // Tagline
                const Text(
                  'Swipe. Match. Watch Together.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1,
                  ),
                ),

                const Spacer(),

                // Filter button
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: _showFilterPanel,
                    icon: const Icon(Icons.tune, size: 24),
                    label: Text(
                      _getFilterSummary(),
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(
                        color: AppTheme.textSecondary.withOpacity(0.5),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // Create Room button
                ElevatedButton.icon(
                  onPressed: () => _navigateToRoom(context, isCreating: true),
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  label: const Text('CREATE ROOM'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Join Room button
                OutlinedButton.icon(
                  onPressed: () => _navigateToRoom(context, isCreating: false),
                  icon: const Icon(Icons.login, size: 28),
                  label: const Text('JOIN ROOM'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryRed,
                    side:
                        const BorderSide(color: AppTheme.primaryRed, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.textSecondary.withOpacity(0.3),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                      SizedBox(height: 12),
                      _InstructionRow(
                        icon: Icons.person_add,
                        text: 'Create or join a room with a friend',
                      ),
                      SizedBox(height: 8),
                      _InstructionRow(
                        icon: Icons.swipe,
                        text: 'Swipe right to like, left to pass',
                      ),
                      SizedBox(height: 8),
                      _InstructionRow(
                        icon: Icons.favorite,
                        text: 'Match when you both like the same movie!',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToRoom(BuildContext context, {required bool isCreating}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoomScreen(
          isCreating: isCreating,
          filters: _filters,
        ),
      ),
    );
  }

  String _getFilterSummary() {
    final selectedGenres = _filters['selectedGenres'] as List<int>;
    final minRating = _filters['minRating'] as double;
    final int? yearFrom = _filters['yearFrom'];
    final int? yearTo = _filters['yearTo'];

    if (selectedGenres.isEmpty &&
        minRating == 0.0 &&
        yearFrom == null &&
        yearTo == null) {
      return 'Film Filtrele (Tümü)';
    }

    final List<String> parts = [];
    if (selectedGenres.isNotEmpty) {
      parts.add('${selectedGenres.length} tür');
    }
    if (minRating > 0) {
      parts.add('⭐${minRating.toStringAsFixed(1)}+');
    }
    if (yearFrom != null || yearTo != null) {
      parts.add('${yearFrom ?? 1900}-${yearTo ?? DateTime.now().year}');
    }

    return 'Filtreler: ${parts.join(", ")}';
  }
}

/// Instruction row widget
class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryRed, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Filter panel for selecting movie preferences
class FilterPanel extends StatefulWidget {
  final Map<String, dynamic> initialFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const FilterPanel({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late Map<String, dynamic> _filters;

  // Common genres
  final List<Map<String, dynamic>> _genres = [
    {'id': 28, 'name': 'Action'},
    {'id': 12, 'name': 'Adventure'},
    {'id': 16, 'name': 'Animation'},
    {'id': 35, 'name': 'Comedy'},
    {'id': 80, 'name': 'Crime'},
    {'id': 99, 'name': 'Documentary'},
    {'id': 18, 'name': 'Drama'},
    {'id': 10751, 'name': 'Family'},
    {'id': 14, 'name': 'Fantasy'},
    {'id': 36, 'name': 'History'},
    {'id': 27, 'name': 'Horror'},
    {'id': 10402, 'name': 'Music'},
    {'id': 9648, 'name': 'Mystery'},
    {'id': 10749, 'name': 'Romance'},
    {'id': 878, 'name': 'Sci-Fi'},
    {'id': 10770, 'name': 'TV Movie'},
    {'id': 53, 'name': 'Thriller'},
    {'id': 10752, 'name': 'War'},
    {'id': 37, 'name': 'Western'},
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.initialFilters);

    // Initialize defaults if not set
    _filters['selectedGenres'] ??= <int>[];
    _filters['minRating'] ??= 0.0;
    _filters['yearFrom'] ??= 1990;
    _filters['yearTo'] ??= DateTime.now().year;
  }

  void _toggleGenre(int genreId) {
    setState(() {
      final List<int> selected =
          List<int>.from(_filters['selectedGenres'] ?? []);
      if (selected.contains(genreId)) {
        selected.remove(genreId);
      } else {
        selected.add(genreId);
      }
      _filters['selectedGenres'] = selected;
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _filters = {
        'selectedGenres': <int>[],
        'minRating': 0.0,
        'yearFrom': 1990,
        'yearTo': DateTime.now().year,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryRed.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: AppTheme.primaryRed),
                const SizedBox(width: 12),
                const Text(
                  'Film Filtreleri',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text(
                    'Sıfırla',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Genres Section
                  _buildSectionTitle('Film Türleri'),
                  const SizedBox(height: 12),
                  _buildGenresGrid(),
                  const SizedBox(height: 32),

                  // Rating Section
                  _buildSectionTitle('Minimum Puan'),
                  const SizedBox(height: 12),
                  _buildRatingSlider(),
                  const SizedBox(height: 32),

                  // Year Range Section
                  _buildSectionTitle('Yıl Aralığı'),
                  const SizedBox(height: 12),
                  _buildYearRange(),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground,
              border: Border(
                top: BorderSide(
                  color: AppTheme.primaryRed.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.textSecondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'İptal',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Filtreleri Uygula',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryRed,
      ),
    );
  }

  Widget _buildGenresGrid() {
    final List<int> selectedGenres = _filters['selectedGenres'] ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _genres.map((genre) {
        final isSelected = selectedGenres.contains(genre['id']);
        return FilterChip(
          label: Text(genre['name'] as String),
          selected: isSelected,
          onSelected: (_) => _toggleGenre(genre['id'] as int),
          selectedColor: AppTheme.primaryRed,
          checkmarkColor: Colors.white,
          backgroundColor: AppTheme.darkBackground,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primaryRed
                : AppTheme.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingSlider() {
    final double minRating = _filters['minRating'] ?? 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '⭐ Minimum',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                minRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: minRating,
          min: 0,
          max: 10,
          divisions: 20,
          activeColor: AppTheme.primaryRed,
          inactiveColor: AppTheme.textSecondary.withOpacity(0.3),
          onChanged: (value) {
            setState(() {
              _filters['minRating'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildYearRange() {
    final int yearFrom = _filters['yearFrom'] ?? 1990;
    final int yearTo = _filters['yearTo'] ?? DateTime.now().year;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildYearSelector(
                'Başlangıç',
                yearFrom,
                1900,
                yearTo,
                (value) {
                  setState(() {
                    _filters['yearFrom'] = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward, color: AppTheme.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: _buildYearSelector(
                'Bitiş',
                yearTo,
                yearFrom,
                DateTime.now().year,
                (value) {
                  setState(() {
                    _filters['yearTo'] = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearSelector(
    String label,
    int value,
    int min,
    int max,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryRed.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppTheme.darkBackground,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            items: List.generate(
              max - min + 1,
              (index) => DropdownMenuItem(
                value: max - index,
                child: Text('${max - index}'),
              ),
            ),
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }
}

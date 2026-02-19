import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../viewmodels/match_viewmodel.dart';
import '../viewmodels/proposal_viewmodel.dart';
import '../widgets/loading_indicator.dart';

/// Screen displaying all matched movies
class MatchesScreen extends StatefulWidget {
  final String roomId;
  final String otherUserId;

  const MatchesScreen({
    super.key,
    required this.roomId,
    required this.otherUserId,
  });

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize proposal listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProposalViewModel>().initialize(widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Your Matches'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Pending proposals badge
          Consumer<ProposalViewModel>(
            builder: (context, proposalViewModel, child) {
              final count = proposalViewModel.pendingProposalsCount;
              if (count == 0) return const SizedBox.shrink();

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => _showProposalsDialog(context),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<MatchViewModel>(
        builder: (context, matchViewModel, child) {
          if (matchViewModel.isLoading) {
            return const LoadingIndicator(message: 'Loading matches...');
          }

          if (matchViewModel.errorMessage != null) {
            return _buildError(matchViewModel.errorMessage!);
          }

          if (!matchViewModel.hasMatches) {
            return _buildNoMatches(context);
          }

          return _buildMatchesList(matchViewModel);
        },
      ),
    );
  }

  /// Build matches list
  Widget _buildMatchesList(MatchViewModel matchViewModel) {
    final matchedMovies = matchViewModel.matchedMovies;

    return Column(
      children: [
        // Header with count
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.primaryRed.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${matchViewModel.totalMatches} Match${matchViewModel.totalMatches == 1 ? '' : 'es'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Text(
                    'Movies you both loved',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Matches grid
        Expanded(
          child: matchedMovies.isEmpty
              ? const Center(
                  child: LoadingIndicator(
                    message: 'Loading movie details...',
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: matchedMovies.length,
                  itemBuilder: (context, index) {
                    return _MatchCard(
                      movie: matchedMovies[index],
                      roomId: widget.roomId,
                      otherUserId: widget.otherUserId,
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Build error view
  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.dislikeRed,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Matches',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build no matches view
  Widget _buildNoMatches(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cardBackground,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 80,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Matches Yet',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Keep swiping to find movies\nyou both love!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.swipe),
              label: const Text('BACK TO SWIPING'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show proposals dialog
void _showProposalsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppTheme.cardBackground,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Row(
              children: [
                Icon(Icons.notifications, color: AppTheme.primaryRed),
                SizedBox(width: 12),
                Text(
                  'Film Teklifleri',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Proposals list
            Expanded(
              child: Consumer<ProposalViewModel>(
                builder: (context, proposalViewModel, child) {
                  if (proposalViewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final receivedProposals = proposalViewModel.receivedProposals;

                  if (receivedProposals.isEmpty) {
                    return const Center(
                      child: Text(
                        'Henüz teklif yok',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: receivedProposals.length,
                    itemBuilder: (context, index) {
                      final proposal = receivedProposals[index];
                      return _ProposalCard(proposal: proposal);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Close button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('KAPAT'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Proposal card widget
class _ProposalCard extends StatelessWidget {
  final dynamic proposal;

  const _ProposalCard({required this.proposal});

  @override
  Widget build(BuildContext context) {
    final proposalViewModel = context.read<ProposalViewModel>();
    final isPending = proposal.status.name == 'pending';

    return Card(
      color: AppTheme.darkBackground,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie title
            Text(
              proposal.movieTitle ?? 'Unknown Movie',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Status or action buttons
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await proposalViewModel.acceptProposal(
                          roomId: proposal.roomId,
                          proposalId: proposal.proposalId,
                        );

                        if (!context.mounted) return;

                        if (success) {
                          // Show success dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppTheme.cardBackground,
                              title: const Text(
                                '🎉 Harika!',
                                style: TextStyle(color: AppTheme.textPrimary),
                              ),
                              content: Text(
                                '${proposal.movieTitle} filmini izlemeyi kabul ettiniz!',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Close success dialog
                                    Navigator.of(context)
                                        .pop(); // Close proposals dialog
                                  },
                                  child: const Text('TAMAM'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Kabul Et'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.likeGreen,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await proposalViewModel.rejectProposal(
                          roomId: proposal.roomId,
                          proposalId: proposal.proposalId,
                        );
                      },
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('Reddet'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dislikeRed,
                        side: const BorderSide(color: AppTheme.dislikeRed),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                proposalViewModel.getStatusText(proposal),
                style: TextStyle(
                  fontSize: 14,
                  color: proposal.status.name == 'accepted'
                      ? AppTheme.likeGreen
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Match card widget
class _MatchCard extends StatelessWidget {
  final dynamic movie;
  final String roomId;
  final String otherUserId;

  const _MatchCard({
    required this.movie,
    required this.roomId,
    required this.otherUserId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMovieDetails(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Movie poster
              movie.fullPosterPath != null
                  ? CachedNetworkImage(
                      imageUrl: movie.fullPosterPath!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.cardBackground,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildFallback(),
                    )
                  : _buildFallback(),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),

              // Movie info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.title ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Helpers.formatRating(movie.voteAverage ?? 0.0),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Helpers.formatDate(movie.releaseDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Match badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Match',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: AppTheme.cardBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.movie,
              size: 40,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                movie.title ?? 'Unknown',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMovieDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardBackground,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  movie.title ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Rating and year
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      Helpers.formatRating(movie.voteAverage ?? 0.0),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      Helpers.formatDate(movie.releaseDate),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Overview
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  movie.overview ?? 'No overview available.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) => Column(
                      children: [
                        // Propose button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _sendProposal(context);
                          },
                          icon: const Icon(Icons.movie),
                          label: const Text('TEKLIF GÖNDER'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Close button
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('KAPAT'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Send proposal to watch this movie
  void _sendProposal(BuildContext context) async {
    final proposalViewModel = context.read<ProposalViewModel>();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await proposalViewModel.createProposal(
      roomId: roomId,
      movieId: movie.id?.toString() ?? '',
      movieTitle: movie.title ?? 'Unknown',
      moviePoster: movie.posterPath,
      receiverUserId: otherUserId,
    );

    if (!context.mounted) return;

    // Close loading dialog
    Navigator.of(context).pop();

    // Show result
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          success ? '✅ Teklif Gönderildi!' : '❌ Hata',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          success
              ? 'Film izleme teklifin karşı tarafa gönderildi. Yanıt bekleniyor...'
              : proposalViewModel.error ?? 'Teklif gönderilemedi.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('TAMAM'),
          ),
        ],
      ),
    );
  }
}

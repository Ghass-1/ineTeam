import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../features/matches/match_provider.dart';
import '../../../data/models/match_model.dart';
import '../../widgets/match_card.dart';
import '../../widgets/empty_state.dart';

/// Displays the user's matches split into "Upcoming" and "Past" categories.
class MyMatchesScreen extends StatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MatchProvider, AuthProvider>(
      builder: (context, matchProvider, authProvider, _) {
        // Get all user matches (both created and joined)
        final joinedMatchesOnly = matchProvider.userMatches
            .where((m) => m.creatorId != authProvider.userId)
            .toList();
        
        final createdMatches = matchProvider.createdMatches;
        final combined = {...joinedMatchesOnly, ...createdMatches}.toList();

        // Calculate counts
        final now = DateTime.now();
        final upcomingCount = combined.where((m) => m.dateTime.isAfter(now)).length;
        final pastCount = combined
            .where((m) => m.dateTime.isBefore(now) || m.dateTime.isAtSameMomentAs(now))
            .length;

        // Split into upcoming and past
        final upcomingMatches = combined
            .where((m) => m.dateTime.isAfter(now))
            .toList();
        final pastMatches = combined
            .where((m) => m.dateTime.isBefore(now) || m.dateTime.isAtSameMomentAs(now))
            .toList();

        // Sort both lists
        upcomingMatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        pastMatches.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Newest first

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Matches'),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.schedule),
                  text: upcomingCount > 0 ? 'Upcoming ($upcomingCount)' : 'Upcoming',
                ),
                Tab(
                  icon: const Icon(Icons.history),
                  text: pastCount > 0 ? 'Past ($pastCount)' : 'Past',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // ── Upcoming Matches Tab ──
              _buildMatchesList(
                matches: upcomingMatches,
                currentUserId: authProvider.userId,
                emptyTitle: 'No Upcoming Matches',
                emptySubtitle: 'Join a match or create your own!',
              ),

              // ── Past Matches Tab ──
              _buildMatchesList(
                matches: pastMatches,
                currentUserId: authProvider.userId,
                emptyTitle: 'No Match History',
                emptySubtitle: 'Your completed matches will appear here.',
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a ListView for displaying matches.
  Widget _buildMatchesList({
    required List<MatchModel> matches,
    required String currentUserId,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (matches.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.sports_outlined,
          title: emptyTitle,
          subtitle: emptySubtitle,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return MatchCard(
          match: match,
          currentUserId: currentUserId,
          isMyMatchesView: true,
          onTap: () => context.push('/match/${match.id}'),
        );
      },
    );
  }
}


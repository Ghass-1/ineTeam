import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../features/matches/match_provider.dart';
import '../../widgets/match_card.dart';
import '../../widgets/empty_state.dart';

/// Displays the user's unified matches.
class MyMatchesScreen extends StatelessWidget {
  const MyMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Matches'),
      ),
      body: Consumer2<MatchProvider, AuthProvider>(
        builder: (context, matchProvider, authProvider, _) {
          // Keep joined matches where the user is NOT the creator
          final joinedMatchesOnly = matchProvider.userMatches
              .where((m) => m.creatorId != authProvider.userId);
          
          final createdMatches = matchProvider.createdMatches;

          // Merge both lists together
          final combined = {...joinedMatchesOnly, ...createdMatches}.toList();

          // Sort chronologically (earliest first)
          combined.sort((a, b) => a.dateTime.compareTo(b.dateTime));

          if (combined.isEmpty) {
            return const EmptyState(
              icon: Icons.sports_outlined,
              title: 'No Matches Yet',
              subtitle: 'Join a match or create your own to see them here!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: combined.length,
            itemBuilder: (context, index) {
              final match = combined[index];
              return MatchCard(
                match: match,
                currentUserId: authProvider.userId,
                isMyMatchesView: true,
                onTap: () => context.push('/match/${match.id}'),
              );
            },
          );
        },
      ),
    );
  }
}


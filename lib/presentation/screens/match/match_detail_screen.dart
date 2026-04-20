import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/helpers.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../features/matches/match_provider.dart';
import '../../../features/matches/matchmaking_service.dart'; // ignore: unused_import - used via matchProvider
import '../../../features/profile/user_provider.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/skill_indicator.dart';

/// Match detail screen showing full match info, players, and team balancing.
class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  bool _repairAttempted = false;
  String? _teamPlayersCacheKey;
  Future<_TeamPlayersData>? _teamPlayersFuture;

  static const Set<String> _genericCreatorNames = {
    '',
    'player',
    'unknown',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchProvider = context.read<MatchProvider>();
    final auth = context.read<AuthProvider>();

    return StreamBuilder<MatchModel?>(
      stream: matchProvider.matchStream(widget.matchId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final match = snapshot.data;
        if (match == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Match not found')),
          );
        }

        _maybeRepairTeams(match);
        _ensureTeamPlayersFuture(context.read<UserProvider>(), match);

        final isCreator = match.isCreator(auth.userId);
        final hasJoined = match.hasPlayer(auth.userId);
        final sportColor = Helpers.sportColor(match.sport);

        return Scaffold(
          appBar: AppBar(
            title: Text(match.sport),
            actions: [
              if (isCreator)
                PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'delete') {
                      final confirmed = await _showDeleteConfirmation(context);

                      if (!context.mounted || !confirmed) return;

                      final success = await matchProvider.deleteMatch(widget.matchId);

                      if (!context.mounted) return;

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Match deleted successfully'),
                          ),
                        );
                        context.pop(); // go back ONLY if delete worked
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              matchProvider.errorMessage ??
                                  'Failed to delete match',
                            ),
                          ),
                        );
                      }
                    } else if (val == 'complete') {
                      final success = await matchProvider.updateMatchStatus(
                        widget.matchId,
                        'completed',
                      );

                      if (!context.mounted) return;

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Match marked as completed'),
                          ),
                        );
                        context.pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              matchProvider.errorMessage ??
                                  'Failed to update match',
                            ),
                          ),
                        );
                      }
                    }
                  },

                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Mark Completed'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete Match',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Card ──
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        sportColor.withAlpha(40),
                        sportColor.withAlpha(10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sportColor.withAlpha(40)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Helpers.sportIcon(match.sport),
                        size: 56,
                        color: sportColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        match.sport,
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: sportColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<UserModel?>(
                        stream: context.read<UserProvider>().getUserByIdStream(
                          match.creatorId,
                        ),
                        builder: (context, creatorSnapshot) {
                          final creatorName = _resolveCreatorName(
                            storedCreatorName: match.creatorName,
                            liveCreatorName: creatorSnapshot.data?.name,
                          );

                          return Text(
                            'by $creatorName',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(150),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Helpers.matchStatusColor(
                            match.status,
                          ).withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          match.status.toUpperCase(),
                          style: TextStyle(
                            color: Helpers.matchStatusColor(match.status),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Match Details ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        context,
                        Icons.location_on_outlined,
                        'Location',
                        match.location,
                      ),
                      _buildDetailRow(
                        context,
                        Icons.schedule,
                        'Date & Time',
                        '${Helpers.formatDate(match.dateTime)} at ${Helpers.formatTime(match.dateTime)}',
                      ),
                      _buildDetailRow(
                        context,
                        Icons.people_outline,
                        'Format',
                        '${match.playerCount} joined • ${Helpers.formatPlayersVs(match.maxPlayers)}',
                      ),
                      if (match.description != null &&
                          match.description!.isNotEmpty)
                        _buildDetailRow(
                          context,
                          Icons.description_outlined,
                          'Description',
                          match.description!,
                        ),
                      if (match.minSkill != null || match.maxSkill != null)
                        _buildDetailRow(
                          context,
                          Icons.trending_up,
                          'Skill Range',
                          '${match.minSkill ?? 1} — ${match.maxSkill ?? 100}',
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Teams Display ──
                FutureBuilder<_TeamPlayersData>(
                  future: _teamPlayersFuture,
                  builder: (context, playerSnapshot) {
                    if (playerSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final teamPlayers = playerSnapshot.data ??
                        const _TeamPlayersData(
                          allPlayers: [],
                          teamAPlayers: [],
                          teamBPlayers: [],
                          unassignedPlayers: [],
                        );
                    final players = teamPlayers.allPlayers;
                    final teamAPlayers = teamPlayers.teamAPlayers;
                    final teamBPlayers = teamPlayers.teamBPlayers;
                    final unassignedPlayers = teamPlayers.unassignedPlayers;
                    final maxPerTeam = match.maxPlayers ~/ 2;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTeamSection(
                          context,
                          theme,
                          teamName: match.teamAName,
                          playerIds: match.teamA,
                          players: teamAPlayers,
                          match: match,
                          maxLimit: maxPerTeam,
                          color: const Color(0xFF10B981), // Emerald
                        ),
                        const SizedBox(height: 24),
                        _buildTeamSection(
                          context,
                          theme,
                          teamName: match.teamBName,
                          playerIds: match.teamB,
                          players: teamBPlayers,
                          match: match,
                          maxLimit: maxPerTeam,
                          color: const Color(0xFF38BDF8), // Sky
                        ),
                        if (unassignedPlayers.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildUnassignedPlayersSection(
                            context,
                            theme,
                            players: unassignedPlayers,
                          ),
                        ],
                        if (kDebugMode && _shouldShowDataDiagnostics(match)) ...[
                          const SizedBox(height: 24),
                          _buildDataDiagnosticsSection(
                            context,
                            theme,
                            match: match,
                          ),
                        ],
                        
                        // ── Team Balance Suggestion ──
                        if (players.length >= 2 && teamAPlayers.isNotEmpty && teamBPlayers.isNotEmpty)
                          ...[
                            const SizedBox(height: 24),
                            _buildTeamBalanceSuggestion(
                              context,
                              theme,
                              players,
                              teamAPlayers,
                              teamBPlayers,
                              match,
                            ),
                          ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // ── Bottom Action Button ──
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 56,
                child: hasJoined
                    ? (isCreator
                          ? ElevatedButton(
                              onPressed: null,
                              child: const Text('You created this match'),
                            )
                          : OutlinedButton(
                              onPressed: () async {
                                await context.read<MatchProvider>().leaveMatch(
                                  widget.matchId,
                                  auth.userId,
                                );
                                if (context.mounted) {
                                  Helpers.showSnackBar(
                                    context,
                                    'Left the match',
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Leave Match'),
                            ))
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  match.teamA.length >= match.maxPlayers ~/ 2
                                  ? null
                                  : () => _joinTeam(
                                      context,
                                      widget.matchId,
                                      auth.userId,
                                      'A',
                                      match.teamAName,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF10B981,
                                ), // Emerald
                              ),
                              child: Text(
                                match.teamA.length >= match.maxPlayers ~/ 2
                                    ? 'Full'
                                    : 'Join ${match.teamAName}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  match.teamB.length >= match.maxPlayers ~/ 2
                                  ? null
                                  : () => _joinTeam(
                                      context,
                                      widget.matchId,
                                      auth.userId,
                                      'B',
                                      match.teamBName,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF38BDF8), // Sky
                              ),
                              child: Text(
                                match.teamB.length >= match.maxPlayers ~/ 2
                                    ? 'Full'
                                    : 'Join ${match.teamBName}',
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _maybeRepairTeams(MatchModel match) {
    if (_repairAttempted || !_shouldRepairTeams(match)) {
      return;
    }

    _repairAttempted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<MatchProvider>().repairTeamAssignments(widget.matchId);
    });
  }

  void _ensureTeamPlayersFuture(
    UserProvider userProvider,
    MatchModel match,
  ) {
    final nextKey = [
      match.id,
      match.creatorName,
      ...match.playerIds,
      '|A|',
      ...match.teamA,
      '|B|',
      ...match.teamB,
      '|Teams|',
      ...match.playerTeams.entries
          .map((entry) => '${entry.key}:${entry.value}')
          .toList()
        ..sort(),
    ].join(':');

    if (_teamPlayersCacheKey == nextKey && _teamPlayersFuture != null) {
      return;
    }

    _teamPlayersCacheKey = nextKey;
    _teamPlayersFuture = _loadTeamPlayers(userProvider, match);
  }

  bool _shouldRepairTeams(MatchModel match) {
    if (match.sport == 'Table Tennis' || match.playerIds.isEmpty) {
      return false;
    }

    final assignedIds = <String>{
      ...match.teamA.where(match.playerIds.contains),
      ...match.teamB.where(match.playerIds.contains),
      ...match.playerTeams.keys.where(match.playerIds.contains),
    };

    return match.playerIds.any((userId) => !assignedIds.contains(userId));
  }

  bool _shouldShowDataDiagnostics(MatchModel match) {
    if (match.playerIds.isEmpty) return false;

    final assignedIds = <String>{
      ...match.teamA.where(match.playerIds.contains),
      ...match.teamB.where(match.playerIds.contains),
      ...match.playerTeams.keys.where(match.playerIds.contains),
    };

    return match.playerIds.any((userId) => !assignedIds.contains(userId)) ||
        (match.teamA.isEmpty && match.teamB.isEmpty && match.playerIds.isNotEmpty);
  }

  Future<void> _joinTeam(BuildContext context, String matchId, String userId, String teamId, String teamName) async {
    final success = await context.read<MatchProvider>().joinMatch(matchId, userId, teamId);
    if (context.mounted) {
      if (success) {
        if (teamName.startsWith("team ") || teamName.startsWith("Team ")){
          teamName = 't${teamName.substring(1)}'; // show message "joined team A"
          Helpers.showSnackBar(context, 'Joined $teamName! 🎉');
        }
        else{
          Helpers.showSnackBar(context, 'Joined team $teamName! 🎉');
        }
      } else {
        Helpers.showSnackBar(
          context,
          context.read<MatchProvider>().errorMessage ?? 'Cannot join',
          isError: true,
        );
      }
    }
  }

  Widget _buildTeamSection(
    BuildContext context,
    ThemeData theme, {
    required String teamName,
    required List<String> playerIds,
    required List<UserModel> players,
    required MatchModel match,
    required int maxLimit,
    required Color color,
  }) {
    final seededPlayers = _mergeResolvedPlayers(
      players: players,
      playerIds: playerIds,
      match: match,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                teamName,
                style: theme.textTheme.titleLarge?.copyWith(color: color),
              ),
              Text(
                '${playerIds.length}/$maxLimit',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: playerIds.length >= maxLimit ? Colors.red : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (playerIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No players joined yet.',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
            )
          else
            StreamBuilder<List<UserModel>>(
              stream: context.read<UserProvider>().getUsersByIdsStream(playerIds),
              initialData: seededPlayers,
              builder: (context, snapshot) {
                final resolvedPlayers = _mergeResolvedPlayers(
                  players: snapshot.data ?? seededPlayers,
                  playerIds: playerIds,
                  match: match,
                );

                return Column(
                  children: _buildPlayerTiles(
                    theme: theme,
                    players: resolvedPlayers,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerTiles({
    required ThemeData theme,
    required List<UserModel> players,
  }) {
    return players.map((player) {
      final sportsLabel = player.sports.isEmpty ? 'Player joined' : player.sports.join(', ');

      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: PlayerAvatar(
          name: player.name,
          imageUrl: player.profilePictureUrl,
          skillLevel: player.skillLevel,
        ),
        title: Text(player.name, style: theme.textTheme.titleMedium),
        subtitle: Text(
          sportsLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(120),
          ),
        ),
        trailing: SkillIndicator(
          skillLevel: player.skillLevel,
          size: 36,
          showLabel: false,
        ),
      );
    }).toList();
  }

  Widget _buildTeamBalanceSuggestion(
    BuildContext context,
    ThemeData theme,
    List<UserModel> allPlayers,
    List<UserModel> currentTeamA,
    List<UserModel> currentTeamB,
    MatchModel match,
  ) {
    // Use matchmaking service to suggest balanced teams
    final matchProvider = context.read<MatchProvider>();
    final balanceResult = matchProvider.matchmakingService.balanceTeams(allPlayers);

    // Check if suggested teams are different from current teams
    final suggestedTeamAIds = balanceResult.teamA.map((p) => p.uid).toSet();
    final suggestedTeamBIds = balanceResult.teamB.map((p) => p.uid).toSet();
    final currentTeamAIds = currentTeamA.map((p) => p.uid).toSet();
    final currentTeamBIds = currentTeamB.map((p) => p.uid).toSet();

    final isBalanced = suggestedTeamAIds == currentTeamAIds && suggestedTeamBIds == currentTeamBIds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: balanceResult.isBalanced
            ? const Color(0xFF2ECC71).withAlpha(15)
            : const Color(0xFFF39C12).withAlpha(15),
        border: Border.all(
          color: balanceResult.isBalanced
              ? const Color(0xFF2ECC71).withAlpha(50)
              : const Color(0xFFF39C12).withAlpha(50),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with balance status
          Row(
            children: [
              Icon(
                isBalanced ? Icons.check_circle : Icons.lightbulb_outline,
                color: balanceResult.isBalanced
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFFF39C12),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBalanced
                      ? 'Teams are well balanced!'
                      : 'Teams could be more balanced',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: balanceResult.isBalanced
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFF39C12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Skill difference: ${balanceResult.skillDifferential.toStringAsFixed(1)} pts',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
          if (!isBalanced) ...[
            const SizedBox(height: 12),
            Text(
              'Suggested team arrangement:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.teamAName,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: balanceResult.teamA
                            .map((player) => Chip(
                                  label: Text(
                                    player.name.split(' ').first,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  backgroundColor:
                                      const Color(0xFF10B981).withAlpha(30),
                                  side: BorderSide(
                                    color:
                                        const Color(0xFF10B981).withAlpha(50),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.teamBName,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: balanceResult.teamB
                            .map((player) => Chip(
                                  label: Text(
                                    player.name.split(' ').first,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  backgroundColor:
                                      const Color(0xFF38BDF8).withAlpha(30),
                                  side: BorderSide(
                                    color:
                                        const Color(0xFF38BDF8).withAlpha(50),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnassignedPlayersSection(
    BuildContext context,
    ThemeData theme, {
    required List<UserModel> players,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF39C12).withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFF39C12).withAlpha(40),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Joined Players Without Team Assignment',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFFF39C12),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This match has joined players, but their team assignment data is missing.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 12),
            ...players.map(
              (player) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: PlayerAvatar(
                  name: player.name,
                  imageUrl: player.profilePictureUrl,
                  skillLevel: player.skillLevel,
                ),
                title: Text(player.name, style: theme.textTheme.titleMedium),
                subtitle: Text(
                  player.sports.join(', '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataDiagnosticsSection(
    BuildContext context,
    ThemeData theme, {
    required MatchModel match,
  }) {
    final diagnostics = <String, Object?>{
      'matchId': match.id,
      'creatorId': match.creatorId,
      'creatorTeam': match.creatorTeam,
      'playerIds': match.playerIds,
      'teamA': match.teamA,
      'teamB': match.teamB,
      'playerTeams': match.playerTeams,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug: Match Team Data',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              const JsonEncoder.withIndent('  ').convert(diagnostics),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolveCreatorName({
    required String storedCreatorName,
    String? liveCreatorName,
  }) {
    final normalizedStored = storedCreatorName.trim().toLowerCase();
    final normalizedLive = liveCreatorName?.trim().toLowerCase() ?? '';

    if (!_genericCreatorNames.contains(normalizedStored) &&
        storedCreatorName.trim().isNotEmpty) {
      return storedCreatorName.trim();
    }

    if (!_genericCreatorNames.contains(normalizedLive) &&
        (liveCreatorName?.trim().isNotEmpty ?? false)) {
      return liveCreatorName!.trim();
    }

    return storedCreatorName.trim().isNotEmpty ? storedCreatorName.trim() : 'Player';
  }

  Future<_TeamPlayersData> _loadTeamPlayers(
    UserProvider userProvider,
    MatchModel match,
  ) async {
    final allUserIds = <String>{
      ...match.teamA,
      ...match.teamB,
      ...match.playerIds,
    }.toList();
    final users = await userProvider.getUsersByIds(allUserIds);
    final usersById = {for (final user in users) user.uid: user};

    final teamAPlayers = _mapUsersForIds(
      usersById: usersById,
      userIds: match.teamA,
      match: match,
    );
    final teamBPlayers = _mapUsersForIds(
      usersById: usersById,
      userIds: match.teamB,
      match: match,
    );
    final assignedIds = {
      ...teamAPlayers.map((player) => player.uid),
      ...teamBPlayers.map((player) => player.uid),
    };
    final unassignedIds = match.playerIds
        .where((userId) => !assignedIds.contains(userId))
        .toList();
    final unassignedPlayers = _mapUsersForIds(
      usersById: usersById,
      userIds: unassignedIds,
      match: match,
    );

    return _TeamPlayersData(
      allPlayers: [...teamAPlayers, ...teamBPlayers, ...unassignedPlayers],
      teamAPlayers: teamAPlayers,
      teamBPlayers: teamBPlayers,
      unassignedPlayers: unassignedPlayers,
    );
  }

  List<UserModel> _mapUsersForIds({
    required Map<String, UserModel> usersById,
    required List<String> userIds,
    required MatchModel match,
  }) {
    return userIds.map((userId) {
      final user = usersById[userId];
      if (user != null) {
        if (user.uid == match.creatorId &&
            _genericCreatorNames.contains(user.name.trim().toLowerCase())) {
          return user.copyWith(
            name: _resolveCreatorName(
              storedCreatorName: match.creatorName,
              liveCreatorName: user.name,
            ),
          );
        }
        return user;
      }

      final fallbackName = userId == match.creatorId
          ? _resolveCreatorName(
              storedCreatorName: match.creatorName,
              liveCreatorName: null,
            )
          : 'Player';

      return UserModel(
        uid: userId,
        name: fallbackName,
        email: '',
        createdAt: match.createdAt,
      );
    }).toList();
  }

  List<UserModel> _mergeResolvedPlayers({
    required List<UserModel> players,
    required List<String> playerIds,
    required MatchModel match,
  }) {
    final usersById = {for (final player in players) player.uid: player};
    return _mapUsersForIds(
      usersById: usersById,
      userIds: playerIds,
      match: match,
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Match'),
            content: const Text(
              'Are you sure you want to delete this match? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _TeamPlayersData {
  final List<UserModel> allPlayers;
  final List<UserModel> teamAPlayers;
  final List<UserModel> teamBPlayers;
  final List<UserModel> unassignedPlayers;

  const _TeamPlayersData({
    required this.allPlayers,
    required this.teamAPlayers,
    required this.teamBPlayers,
    required this.unassignedPlayers,
  });
}

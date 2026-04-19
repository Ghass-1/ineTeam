import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/match_model.dart';
import '../../data/models/user_model.dart';
import '../../features/profile/user_provider.dart';

/// A premium match card for displaying match information in lists.
class MatchCard extends StatelessWidget {
  static const Set<String> _genericCreatorNames = {
    '',
    'player',
    'unknown',
  };

  final MatchModel match;
  final VoidCallback? onTap;

  /// Used to compute ownership/roles explicitly when displaying unified lists
  final String? currentUserId;
  final bool isMyMatchesView;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
    this.currentUserId,
    this.isMyMatchesView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sportColor = Helpers.sportColor(match.sport);
    final statusColor = Helpers.matchStatusColor(match.status);
    final fillPercentage = match.maxPlayers > 0
        ? match.playerCount / match.maxPlayers
        : 0.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: null,
      shape: null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: Sport badge + Status ──
              Row(
                children: [
                  // Sport icon badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: sportColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Helpers.sportIcon(match.sport),
                      color: sportColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Match info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.sport,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                      ],
                    ),
                  ),

                  // ── Status & Category Badges ──
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Ownership/Role Tag (Only in My Matches View)
                      if (isMyMatchesView && currentUserId != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: match.creatorId == currentUserId
                                ? const Color(0xFF10B981) // Emerald bold
                                : const Color(0xFF38BDF8), // Sky bold
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            match.creatorId == currentUserId
                                ? 'Created by Me'
                                : 'Joined',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      // Match Status Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withAlpha(40)),
                        ),
                        child: Text(
                          match.status.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Location & Time Row ──
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      match.location,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Helpers.formatDateTime(match.dateTime),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Player Count Bar ──
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${match.playerCount} joined • ${Helpers.formatPlayersVs(match.maxPlayers)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fillPercentage,
                        backgroundColor: theme.colorScheme.outline.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          fillPercentage >= 1.0
                              ? const Color(0xFFF39C12)
                              : sportColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Description (if present) ──
              if (match.description != null &&
                  match.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  match.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
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
}

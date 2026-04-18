import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../features/matches/matchmaking_service.dart';
import 'player_avatar.dart';
import 'skill_indicator.dart';

/// Displays the balanced team suggestion for a full match.
class TeamBalanceView extends StatelessWidget {
  final TeamBalanceResult result;

  const TeamBalanceView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              result.isBalanced ? Icons.check_circle : Icons.warning_amber,
              color: result.isBalanced
                  ? const Color(0xFF2ECC71)
                  : const Color(0xFFF39C12),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              result.isBalanced ? 'Teams are balanced!' : 'Teams may be unbalanced',
              style: theme.textTheme.titleMedium?.copyWith(
                color: result.isBalanced
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFFF39C12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Skill differential
        Center(
          child: Text(
            'Skill difference: ${result.skillDifferential.toStringAsFixed(1)} pts',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Two team columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team A
            Expanded(
              child: _buildTeamColumn(
                context,
                'Team A',
                result.teamA,
                result.teamAAvgSkill,
                const Color(0xFF3498DB),
              ),
            ),
            const SizedBox(width: 12),
            // Divider
            Container(
              width: 1,
              height: 200,
              color: theme.colorScheme.outline.withAlpha(40),
            ),
            const SizedBox(width: 12),
            // Team B
            Expanded(
              child: _buildTeamColumn(
                context,
                'Team B',
                result.teamB,
                result.teamBAvgSkill,
                const Color(0xFFE74C3C),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamColumn(
    BuildContext context,
    String teamName,
    List<UserModel> players,
    double avgSkill,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Team header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            teamName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Avg: ${avgSkill.toStringAsFixed(0)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(150),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),

        // Player list
        ...players.map((player) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  PlayerAvatar(
                    name: player.name,
                    imageUrl: player.profilePictureUrl,
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      player.name,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SkillIndicator(
                    skillLevel: player.skillLevel,
                    size: 28,
                    showLabel: false,
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

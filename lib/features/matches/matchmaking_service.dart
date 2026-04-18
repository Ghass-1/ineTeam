import '../../data/models/user_model.dart';

/// Result of the team balancing algorithm.
class TeamBalanceResult {
  final List<UserModel> teamA;
  final List<UserModel> teamB;
  final double teamAAvgSkill;
  final double teamBAvgSkill;
  final double skillDifferential;

  const TeamBalanceResult({
    required this.teamA,
    required this.teamB,
    required this.teamAAvgSkill,
    required this.teamBAvgSkill,
    required this.skillDifferential,
  });

  /// Whether the teams are reasonably balanced (< 10 point difference).
  bool get isBalanced => skillDifferential < 10;
}

/// Provides team balancing algorithms for filled matches.
class MatchmakingService {
  /// Balances players into two teams using alternating draft by skill.
  ///
  /// Algorithm:
  /// 1. Sort players by skill level (descending)
  /// 2. Alternate picks: best → team A, second best → team B, etc.
  /// This is a greedy approach that produces near-optimal balance.
  TeamBalanceResult balanceTeams(List<UserModel> players) {
    if (players.length < 2) {
      return TeamBalanceResult(
        teamA: players,
        teamB: [],
        teamAAvgSkill: _avgSkill(players),
        teamBAvgSkill: 0,
        skillDifferential: 0,
      );
    }

    // Sort by skill descending
    final sorted = List<UserModel>.from(players)
      ..sort((a, b) => b.skillLevel.compareTo(a.skillLevel));

    final teamA = <UserModel>[];
    final teamB = <UserModel>[];

    // Alternating draft
    for (var i = 0; i < sorted.length; i++) {
      if (i % 2 == 0) {
        teamA.add(sorted[i]);
      } else {
        teamB.add(sorted[i]);
      }
    }

    final avgA = _avgSkill(teamA);
    final avgB = _avgSkill(teamB);

    return TeamBalanceResult(
      teamA: teamA,
      teamB: teamB,
      teamAAvgSkill: avgA,
      teamBAvgSkill: avgB,
      skillDifferential: (avgA - avgB).abs(),
    );
  }

  double _avgSkill(List<UserModel> players) {
    if (players.isEmpty) return 0;
    final total = players.fold<int>(0, (sum, p) => sum + p.skillLevel);
    return total / players.length;
  }
}

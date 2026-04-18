/// App-wide constants, enums, and configuration values.
library;

// ─── Sport Types ───────────────────────────────────────────────────────────────
enum SportType {
  football('Football', '⚽'),
  basketball('Basketball', '🏀'),
  volleyball('Volleyball', '🏐'),
  tableTennis('Table Tennis', '🏓');

  const SportType(this.label, this.emoji);
  final String label;
  final String emoji;

  /// Default max players for this sport (total, both teams).
  int get defaultMaxPlayers {
    switch (this) {
      case SportType.football:
        return 10;
      case SportType.basketball:
        return 10;
      case SportType.volleyball:
        return 12; // Adjusted to better support 6v6
      case SportType.tableTennis:
        return 2;
    }
  }

  /// Campus locations mapped explicitly per sport.
  List<String> get availableLocations {
    switch (this) {
      case SportType.football:
        return ['INPT field', 'Terrain l9orb'];
      case SportType.basketball:
        return ['INPT field 1', 'INPT field 2'];
      case SportType.volleyball:
        return ['INPT Volleyball field'];
      case SportType.tableTennis:
        return ['table1', 'table2', 'table3'];
    }
  }
}

// ─── Skill Level ───────────────────────────────────────────────────────────────
enum SkillLevel {
  beginner('Beginner', 1, 33),
  intermediate('Intermediate', 34, 66),
  advanced('Advanced', 67, 100);

  const SkillLevel(this.label, this.minRating, this.maxRating);
  final String label;
  final int minRating;
  final int maxRating;

  static SkillLevel fromRating(int rating) {
    if (rating <= 33) return SkillLevel.beginner;
    if (rating <= 66) return SkillLevel.intermediate;
    return SkillLevel.advanced;
  }
}

// ─── Play Frequency ────────────────────────────────────────────────────────────
enum PlayFrequency {
  casual('Casual'),
  regular('Regular'),
  competitive('Competitive');

  const PlayFrequency(this.label);
  final String label;
}

// ─── Match Status ──────────────────────────────────────────────────────────────
enum MatchStatus {
  open('Open'),
  full('Full'),
  completed('Completed');

  const MatchStatus(this.label);
  final String label;
}

// ─── Firestore Collection Names ────────────────────────────────────────────────
class FirestoreCollections {
  FirestoreCollections._();
  static const String users = 'users';
  static const String matches = 'matches';
}

// ─── App Info ──────────────────────────────────────────────────────────────────
class AppInfo {
  AppInfo._();
  static const String appName = 'ineTeam';
  static const String tagline = 'Find Your Team, Own The Game';

  /// Only emails ending with this domain can sign up.
  static const String allowedEmailDomain = '@ine.inpt.ac.ma';
}

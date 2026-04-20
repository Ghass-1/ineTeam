import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a sports match stored in Firestore.
class MatchModel {
  final String id;
  final String creatorId;
  final String creatorName;
  final String sport;
  final String location;
  final DateTime dateTime;
  final int maxPlayers;
  final List<String> playerIds;
  final List<String> teamA;
  final List<String> teamB;
  final Map<String, String> playerTeams;
  final String? creatorTeam;
  final String teamAName;
  final String teamBName;
  final String? description;
  final int? minSkill;
  final int? maxSkill;
  final String status; // 'open' | 'full' | 'completed'
  final DateTime createdAt;

  const MatchModel({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.sport,
    required this.location,
    required this.dateTime,
    required this.maxPlayers,
    this.playerIds = const [],
    this.teamA = const [],
    this.teamB = const [],
    this.playerTeams = const {},
    this.creatorTeam,
    this.teamAName = 'Team A',
    this.teamBName = 'Team B',
    this.description,
    this.minSkill,
    this.maxSkill,
    this.status = 'open',
    required this.createdAt,
  });

  /// Creates a MatchModel from a Firestore document map.
  factory MatchModel.fromMap(Map<String, dynamic> map, String id) {
    final playerIds = List<String>.from(map['playerIds'] ?? []);
    final rawTeamA = List<String>.from(map['teamA'] ?? []);
    final rawTeamB = List<String>.from(map['teamB'] ?? []);
    final parsedPlayerTeams = _parsePlayerTeams(map['playerTeams']);
    final effectiveTeamA = _buildEffectiveTeam(
      playerIds: playerIds,
      rawTeam: rawTeamA,
      parsedPlayerTeams: parsedPlayerTeams,
      teamId: 'A',
    );
    final effectiveTeamB = _buildEffectiveTeam(
      playerIds: playerIds,
      rawTeam: rawTeamB,
      parsedPlayerTeams: parsedPlayerTeams,
      teamId: 'B',
    );

    return MatchModel(
      id: id,
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      sport: map['sport'] ?? '',
      location: map['location'] ?? '',
      dateTime: (map['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxPlayers: map['maxPlayers'] ?? 10,
      playerIds: playerIds,
      teamA: effectiveTeamA,
      teamB: effectiveTeamB,
      playerTeams: parsedPlayerTeams.isNotEmpty
          ? parsedPlayerTeams
          : _derivePlayerTeams(effectiveTeamA, effectiveTeamB),
      creatorTeam: map['creatorTeam']?.toString(),
      teamAName: map['teamAName'] ?? 'Team A',
      teamBName: map['teamBName'] ?? 'Team B',
      description: map['description'],
      minSkill: map['minSkill'],
      maxSkill: map['maxSkill'],
      status: map['status'] ?? 'open',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this model to a Firestore-ready map.
  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'creatorName': creatorName,
      'sport': sport,
      'location': location,
      'dateTime': Timestamp.fromDate(dateTime),
      'maxPlayers': maxPlayers,
      'playerIds': playerIds,
      'teamA': teamA,
      'teamB': teamB,
      'playerTeams': playerTeams,
      'creatorTeam': creatorTeam,
      'teamAName': teamAName,
      'teamBName': teamBName,
      'description': description,
      'minSkill': minSkill,
      'maxSkill': maxSkill,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a copy with optional overrides.
  MatchModel copyWith({
    String? creatorId,
    String? creatorName,
    String? sport,
    String? location,
    DateTime? dateTime,
    int? maxPlayers,
    List<String>? playerIds,
    List<String>? teamA,
    List<String>? teamB,
    Map<String, String>? playerTeams,
    String? creatorTeam,
    String? teamAName,
    String? teamBName,
    String? description,
    int? minSkill,
    int? maxSkill,
    String? status,
  }) {
    return MatchModel(
      id: id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      sport: sport ?? this.sport,
      location: location ?? this.location,
      dateTime: dateTime ?? this.dateTime,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      playerIds: playerIds ?? this.playerIds,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      playerTeams: playerTeams ?? this.playerTeams,
      creatorTeam: creatorTeam ?? this.creatorTeam,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      description: description ?? this.description,
      minSkill: minSkill ?? this.minSkill,
      maxSkill: maxSkill ?? this.maxSkill,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  /// Whether the match is full.
  bool get isFull => playerIds.length >= maxPlayers;

  /// Whether a specific user has joined.
  bool hasPlayer(String userId) => playerIds.contains(userId);

  /// Current player count.
  int get playerCount => playerIds.length;

  /// Spots remaining.
  int get spotsLeft => maxPlayers - playerIds.length;

  /// Whether the match is in the future.
  bool get isUpcoming => dateTime.isAfter(DateTime.now());

  /// Whether the given user is the creator.
  bool isCreator(String userId) => creatorId == userId;

  static Map<String, String> _parsePlayerTeams(dynamic rawPlayerTeams) {
    if (rawPlayerTeams is! Map) return {};

    final parsed = <String, String>{};
    rawPlayerTeams.forEach((key, value) {
      final team = value?.toString();
      if (team == 'A' || team == 'B') {
        parsed[key.toString()] = team!;
      }
    });
    return parsed;
  }

  static Map<String, String> _derivePlayerTeams(
    List<String> teamA,
    List<String> teamB,
  ) {
    return {
      for (final userId in teamA) userId: 'A',
      for (final userId in teamB) userId: 'B',
    };
  }

  static List<String> _buildEffectiveTeam({
    required List<String> playerIds,
    required List<String> rawTeam,
    required Map<String, String> parsedPlayerTeams,
    required String teamId,
  }) {
    final playerIdSet = playerIds.toSet();
    final effectiveTeam = <String>[];

    for (final userId in rawTeam) {
      if (playerIdSet.contains(userId) && !effectiveTeam.contains(userId)) {
        effectiveTeam.add(userId);
      }
    }

    for (final userId in playerIds) {
      if (parsedPlayerTeams[userId] == teamId &&
          !effectiveTeam.contains(userId)) {
        effectiveTeam.add(userId);
      }
    }

    return effectiveTeam;
  }
}

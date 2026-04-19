import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user profile stored in Firestore.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePictureUrl;
  final List<String> sports;
  final int skillLevel; // 1-100, average across all sports
  final Map<String, int> sportSkills; // Per-sport skill levels (sport -> 1-100)
  final String frequency; // 'casual' | 'regular' | 'competitive'
  final List<String> createdMatches;
  final List<String> joinedMatches;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePictureUrl,
    this.sports = const [],
    this.skillLevel = 50,
    this.sportSkills = const {},
    this.frequency = 'casual',
    this.createdMatches = const [],
    this.joinedMatches = const [],
    required this.createdAt,
  });

  /// Creates a UserModel from a Firestore document map.
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final email = map['email']?.toString() ?? '';
    final name = map['name']?.toString() ?? '';
    // If name is empty (legacy accounts), fallback to email prefix so they can complete profile
    final displayName = name.isNotEmpty
        ? name
        : (email.isNotEmpty ? email.split('@').first : 'Player');

    // Parse sport skills - convert dynamic map to Map<String, int>
    Map<String, int> parsedSportSkills = {};
    if (map['sportSkills'] is Map) {
      (map['sportSkills'] as Map).forEach((key, value) {
        parsedSportSkills[key.toString()] = (value as num?)?.toInt() ?? 50;
      });
    }

    return UserModel(
      uid: uid,
      name: displayName,
      email: email,
      profilePictureUrl: map['profilePictureUrl'],
      sports: List<String>.from(map['sports'] ?? []),
      skillLevel: map['skillLevel'] ?? 50,
      sportSkills: parsedSportSkills,
      frequency: map['frequency'] ?? 'casual',
      createdMatches: List<String>.from(map['createdMatches'] ?? []),
      joinedMatches: List<String>.from(map['joinedMatches'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this model to a Firestore-ready map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'sports': sports,
      'skillLevel': skillLevel,
      'sportSkills': sportSkills,
      'frequency': frequency,
      'createdMatches': createdMatches,
      'joinedMatches': joinedMatches,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a copy with optional overrides.
  UserModel copyWith({
    String? name,
    String? email,
    String? profilePictureUrl,
    List<String>? sports,
    int? skillLevel,
    Map<String, int>? sportSkills,
    String? frequency,
    List<String>? createdMatches,
    List<String>? joinedMatches,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      sports: sports ?? this.sports,
      skillLevel: skillLevel ?? this.skillLevel,
      sportSkills: sportSkills ?? this.sportSkills,
      frequency: frequency ?? this.frequency,
      createdMatches: createdMatches ?? this.createdMatches,
      joinedMatches: joinedMatches ?? this.joinedMatches,
      createdAt: createdAt,
    );
  }

  /// Whether the user has completed their profile setup.
  bool get hasCompletedProfile => name.isNotEmpty && sports.isNotEmpty;
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/exceptions/app_exceptions.dart';
import 'dart:developer' as developer;
import '../models/match_model.dart';

/// Handles all Firestore operations for matches with timeout and error handling.
class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _operationTimeout = Duration(seconds: 15);

  CollectionReference get _matchesCollection =>
      _firestore.collection(FirestoreCollections.matches);

  /// Creates a new match document with timeout and error handling.
  /// Throws [MatchServiceException] if creation fails.
  Future<void> createMatch(MatchModel match) async {
    try {
      await _matchesCollection
          .doc(match.id)
          .set(match.toMap())
          .timeout(_operationTimeout, onTimeout: () {
        throw TimeoutException('Match creation timed out. Please check your connection.');
      });
    } on TimeoutException {
      rethrow;
    } on FirebaseException catch (e) {
      developer.log('[MatchService] ERROR creating match: $e');
      throw MatchServiceException('Failed to create match: ${e.message}');
    } catch (e) {
      developer.log('[MatchService] Unexpected error creating match: $e');
      throw MatchServiceException('An unexpected error occurred.');
    }
  }

  /// Checks if a field is available at a specific exact time with timeout.
  /// Returns true if available (no conflicts), false if already booked.
  Future<bool> isFieldAvailable(String location, DateTime dateTime) async {
    try {
      developer.log('[MatchService] Checking availability for $location at $dateTime');
      
      // Get all matches for this location (only single where clause, no index needed)
      final query = await _matchesCollection
          .where('location', isEqualTo: location)
          .get()
          .timeout(_operationTimeout, onTimeout: () {
        throw TimeoutException('Availability check timed out.');
      });

      developer.log('[MatchService] Found ${query.docs.length} matches at this location');

      // Check if any match has conflict (within 1 hour and not deleted/completed)
      final conflictExists = query.docs.any((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? 'open';
        
        // Skip deleted or completed matches
        if (status != 'open' && status != 'full') {
          return false;
        }
        
        final matchDateTime = (data['dateTime'] as Timestamp?)?.toDate();
        if (matchDateTime == null) return false;
        
        // Check if within 1 hour (matches at same location & time)
        final timeDiff = matchDateTime.difference(dateTime).inMinutes.abs();
        final hasConflict = timeDiff < 60;
        
        if (hasConflict) {
          developer.log('[MatchService] Conflict found: existing match at $matchDateTime');
        }
        
        return hasConflict;
      });

      developer.log('[MatchService] Availability check result: ${!conflictExists} (conflict: $conflictExists)');
      return !conflictExists;
    } on TimeoutException {
      developer.log('[MatchService] Availability check TIMEOUT');
      rethrow;
    } catch (e) {
      developer.log('[MatchService] ERROR checking field availability: $e', error: e, stackTrace: StackTrace.current);
      throw MatchServiceException('Failed to check field availability.');
    }
  }

  /// Fetches a single match by ID with timeout.
  /// Throws [MatchServiceException] on failure.
  Future<MatchModel?> getMatchById(String matchId) async {
    try {
      final doc = await _matchesCollection
          .doc(matchId)
          .get()
          .timeout(_operationTimeout, onTimeout: () {
        throw TimeoutException('Match fetch timed out.');
      });

      if (!doc.exists) return null;
      return MatchModel.fromMap(doc.data() as Map<String, dynamic>, matchId);
    } on TimeoutException {
      rethrow;
    } catch (e) {
      developer.log('[MatchService] ERROR fetching match $matchId: $e');
      throw MatchServiceException('Failed to fetch match details.');
    }
  }

  /// Repairs missing or inconsistent team assignments for legacy/corrupted matches.
  Future<bool> repairTeamAssignments(String matchId) async {
    try {
      final repaired = await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(_matchesCollection.doc(matchId));
        if (!doc.exists) {
          throw MatchServiceException('Match not found.');
        }

        final match = MatchModel.fromMap(
          doc.data() as Map<String, dynamic>,
          matchId,
        );

        if (!_needsTeamRepair(match)) {
          return false;
        }

        final repairedPlayerTeams = _buildRepairedPlayerTeams(match);
        final repairedTeamA = match.playerIds
            .where((userId) => repairedPlayerTeams[userId] == 'A')
            .toList();
        final repairedTeamB = match.playerIds
            .where((userId) => repairedPlayerTeams[userId] == 'B')
            .toList();

        transaction.update(_matchesCollection.doc(matchId), {
          'teamA': repairedTeamA,
          'teamB': repairedTeamB,
          'playerTeams': repairedPlayerTeams,
          'creatorTeam': repairedPlayerTeams[match.creatorId],
        });

        return true;
      }).timeout(_operationTimeout, onTimeout: () {
        throw TimeoutException('Repairing teams timed out. Please try again.');
      });

      return repaired;
    } on MatchServiceException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      developer.log('[MatchService] ERROR repairing teams for $matchId: $e');
      throw MatchServiceException('Failed to repair team assignments.');
    }
  }

  /// Returns all reserved date times for a particular location on a specific day.
  Future<List<DateTime>> getReservedTimesForDay(
    String location,
    DateTime date,
  ) async {
    // Only query by location to avoid requiring a composite index setup
    final query = await _matchesCollection
        .where('location', isEqualTo: location)
        .get();

    final reservedTimes = <DateTime>[];

    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'open';

      // Ignore completed or cancelled matches
      if (status != 'open' && status != 'full') continue;

      final dtRaw = data['dateTime'];
      if (dtRaw == null) continue;

      final dt = (dtRaw as Timestamp).toDate();
      // Check if same day
      if (dt.year == date.year &&
          dt.month == date.month &&
          dt.day == date.day) {
        reservedTimes.add(dt);
      }
    }

    return reservedTimes;
  }

  /// Real-time stream of all open matches, ordered by date.
  Stream<List<MatchModel>> matchesStream() {
    return _matchesCollection
        //.where('status', whereIn: ['open'])
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => MatchModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  /// Real-time stream of a single match for live updates.
  Stream<MatchModel?> matchStream(String matchId) {
    return _matchesCollection.doc(matchId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MatchModel.fromMap(doc.data() as Map<String, dynamic>, matchId);
    });
  }

  /// Adds a player to a match with validation and timeout.
  /// Throws [MatchServiceException] with specific error messages.
  /// Returns true if successfully joined, false if validation fails.
  Future<bool> joinMatch(String matchId, String userId, String teamId) async {
    try {
      final result = await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(_matchesCollection.doc(matchId));
        if (!doc.exists) {
          throw MatchServiceException('Match not found.');
        }

        final match = MatchModel.fromMap(
          doc.data() as Map<String, dynamic>,
          matchId,
        );

        // Validate match status
        if (match.isFull) {
          throw MatchServiceException('This match is full.');
        }

        // Prevent duplicate joins (already in match)
        if (match.hasPlayer(userId)) {
          throw MatchServiceException('You are already in this match.');
        }

        // Determine max players per team
        final maxPerTeam = match.maxPlayers ~/ 2;

        List<String> currentTeamArray;
        if (teamId == 'A') {
          currentTeamArray = match.teamA;
        } else if (teamId == 'B') {
          currentTeamArray = match.teamB;
        } else {
          throw ValidationException('Invalid team ID.');
        }

        // Prevent joining full team
        if (currentTeamArray.length >= maxPerTeam) {
          throw MatchServiceException('This team is full.');
        }

        final newPlayerIds = [...match.playerIds, userId];
        final newTeamArray = [...currentTeamArray, userId];
        final newStatus = newPlayerIds.length >= match.maxPlayers
            ? 'full'
            : 'open';
        final newPlayerTeams = {
          ...match.playerTeams,
          userId: teamId,
        };

        transaction.update(_matchesCollection.doc(matchId), {
          'playerIds': newPlayerIds,
          if (teamId == 'A') 'teamA': newTeamArray,
          if (teamId == 'B') 'teamB': newTeamArray,
          'playerTeams': newPlayerTeams,
          'status': newStatus,
        });

        return true;
      }).timeout(_operationTimeout, onTimeout: () {
        throw TimeoutException('Joining match timed out. Please try again.');
      });

      return result;
    } on MatchServiceException {
      developer.log('[MatchService] Validation error joining match: $userId to $matchId');
      rethrow;
    } on ValidationException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      developer.log('[MatchService] ERROR joining match: $e');
      throw MatchServiceException('Failed to join match. Please try again.');
    }
  }

  /// Removes a player from a match and all teams with timeout.
  /// Throws [MatchServiceException] if operation fails.
  Future<void> leaveMatch(String matchId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(_matchesCollection.doc(matchId));
        if (!doc.exists) {
          throw MatchServiceException('Match not found.');
        }

        final match = MatchModel.fromMap(
          doc.data() as Map<String, dynamic>,
          matchId,
        );

        // Check if player is actually in the match
        if (!match.hasPlayer(userId)) {
          throw MatchServiceException('You are not in this match.');
        }

        final newPlayerIds = match.playerIds.where((id) => id != userId).toList();
        final newTeamA = match.teamA.where((id) => id != userId).toList();
        final newTeamB = match.teamB.where((id) => id != userId).toList();
        final newPlayerTeams = Map<String, String>.from(match.playerTeams)
          ..remove(userId);

        final newStatus = newPlayerIds.length >= match.maxPlayers
            ? 'full'
            : 'open';

        transaction.update(_matchesCollection.doc(matchId), {
          'playerIds': newPlayerIds,
          'teamA': newTeamA,
          'teamB': newTeamB,
          'playerTeams': newPlayerTeams,
          'status': newStatus,
        });
      }).timeout(_operationTimeout, onTimeout: () {
        throw TimeoutException('Leaving match timed out. Please try again.');
      });
    } on MatchServiceException {
      developer.log('[MatchService] Validation error leaving match: $userId from $matchId');
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      developer.log('[MatchService] ERROR leaving match: $e');
      throw MatchServiceException('Failed to leave match. Please try again.');
    }
  }

  /// Updates match status (e.g. to 'completed').
  Future<void> updateMatchStatus(String matchId, String status) async {
    await _matchesCollection.doc(matchId).update({'status': status});
  }

  /// Deletes a match document.
  Future<void> deleteMatch(String matchId) async {
    await _matchesCollection.doc(matchId).delete();
  }

  /// Fetches matches where the user is a player.
  Stream<List<MatchModel>> userMatchesStream(String userId) {
    return _matchesCollection
        .where('playerIds', arrayContains: userId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => MatchModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  /// Fetches matches created by the user.
  Stream<List<MatchModel>> createdMatchesStream(String userId) {
    return _matchesCollection
        .where('creatorId', isEqualTo: userId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => MatchModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  /// Checks and auto-deletes expired matches that don't have enough players.
  /// Returns the number of matches deleted.
  Future<int> autoDeleteExpiredMatches() async {
    final now = DateTime.now();
    
    // Query matches that are expired and not already completed
    final expiredMatches = await _matchesCollection
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('status', whereIn: ['open', 'full'])
        .get();

    int deletedCount = 0;

    for (final doc in expiredMatches.docs) {
      final match = MatchModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      // Check if match has fewer players than required
      if (match.playerCount < match.maxPlayers) {
        developer.log(
          '[MatchService] Auto-deleting expired match: ${match.id} '
          '(${match.playerCount}/${match.maxPlayers} players)',
        );
        
        // Delete the match
        await deleteMatch(match.id);
        deletedCount++;

        // Send notification to players (optional)
        await _notifyPlayersOfMatchDeletion(match);
      }
    }

    if (deletedCount > 0) {
      developer.log('[MatchService] Auto-deleted $deletedCount expired matches');
    }

    return deletedCount;
  }

  /// Sends notifications to all players in a deleted match.
  Future<void> _notifyPlayersOfMatchDeletion(MatchModel match) async {
    // Note: This would require a messaging service (e.g., Cloud Messaging)
    // For now, we'll just log it
    developer.log(
      '[MatchService] Would notify ${match.playerCount} players about match deletion',
    );
    
    // TODO: Implement actual notifications when messaging service is set up
    // Could store notifications in a 'notifications' collection or use FCM
  }

  bool _needsTeamRepair(MatchModel match) {
    if (match.playerIds.isEmpty || match.sport == 'Table Tennis') {
      return false;
    }

    final assignedIds = <String>{
      ...match.teamA.where(match.playerIds.contains),
      ...match.teamB.where(match.playerIds.contains),
      ...match.playerTeams.keys.where(match.playerIds.contains),
    };

    final missingAssignments =
        match.playerIds.any((userId) => !assignedIds.contains(userId));
    final hasEmptyTeamsWithPlayers =
        match.playerIds.isNotEmpty && match.teamA.isEmpty && match.teamB.isEmpty;
    final arraysMismatchMap = match.playerIds.any((userId) {
      final team = match.playerTeams[userId];
      if (team == null) return false;
      return (team == 'A' && !match.teamA.contains(userId)) ||
          (team == 'B' && !match.teamB.contains(userId));
    });

    return missingAssignments ||
        hasEmptyTeamsWithPlayers ||
        arraysMismatchMap ||
        match.playerTeams.isEmpty;
  }

  Map<String, String> _buildRepairedPlayerTeams(MatchModel match) {
    final maxPerTeam = match.maxPlayers ~/ 2;
    final repaired = <String, String>{};

    for (final userId in match.playerIds) {
      final storedTeam = match.playerTeams[userId];
      if (storedTeam == 'A' || storedTeam == 'B') {
        repaired[userId] = storedTeam!;
        continue;
      }

      if (match.teamA.contains(userId)) {
        repaired[userId] = 'A';
        continue;
      }

      if (match.teamB.contains(userId)) {
        repaired[userId] = 'B';
      }
    }

    if (match.playerIds.contains(match.creatorId) &&
        !repaired.containsKey(match.creatorId)) {
      repaired[match.creatorId] = match.creatorTeam == 'B' ? 'B' : 'A';
    }

    for (final userId in match.playerIds) {
      if (repaired.containsKey(userId)) continue;

      final teamACount = repaired.values.where((team) => team == 'A').length;
      final teamBCount = repaired.values.where((team) => team == 'B').length;

      if (teamACount >= maxPerTeam && teamBCount < maxPerTeam) {
        repaired[userId] = 'B';
      } else if (teamBCount >= maxPerTeam && teamACount < maxPerTeam) {
        repaired[userId] = 'A';
      } else {
        repaired[userId] = teamACount <= teamBCount ? 'A' : 'B';
      }
    }

    return repaired;
  }
}

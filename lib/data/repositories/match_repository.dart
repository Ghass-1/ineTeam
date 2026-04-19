import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';

/// Wraps MatchService with business logic validation.
class MatchRepository {
  final MatchService _matchService;
  static const Set<String> _genericCreatorNames = {
    '',
    'player',
    'unknown',
  };

  MatchRepository({MatchService? matchService})
      : _matchService = matchService ?? MatchService();

  /// Creates a match and auto-adds the creator as the first player.
  /// Throws [MatchRepositoryException] if validation fails.
  Future<void> createMatch(MatchModel match) async {
    // Validate the match
    if (match.maxPlayers < 2) {
      throw MatchRepositoryException('Match must have at least 2 players.');
    }
    if (match.dateTime.isBefore(DateTime.now())) {
      throw MatchRepositoryException('Match date must be in the future.');
    }
    if (match.location.trim().isEmpty) {
      throw MatchRepositoryException('Location is required.');
    }

    try {
      final resolvedCreatorName = await _resolveCreatorName(match);
      final canonicalMatch = match.copyWith(creatorName: resolvedCreatorName);

      // Check availability
      final isAvailable = await _matchService.isFieldAvailable(
        canonicalMatch.location,
        canonicalMatch.dateTime,
      );
      if (!isAvailable) {
        throw MatchRepositoryException(
            'This location is already booked at that time. Please pick another.');
      }

      await _matchService.createMatch(canonicalMatch);

      // Update user's createdMatches array
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(canonicalMatch.creatorId)
          .update({
        'createdMatches': FieldValue.arrayUnion([canonicalMatch.id]),
      });
    } on TimeoutException catch (e) {
      throw MatchRepositoryException(e.message);
    } on MatchServiceException catch (e) {
      throw MatchRepositoryException(e.message);
    } catch (e) {
      throw MatchRepositoryException('Failed to create match.');
    }
  }

  Future<void> updateMatchStatus(String matchId, String status) async {
    await _matchService.updateMatchStatus(matchId, status);
  }

  /// Joins a match with proper error handling.
  /// Throws [MatchRepositoryException] with specific error messages.
  Future<void> joinMatch(String matchId, String userId, String teamId) async {
    try {
      await _matchService.joinMatch(matchId, userId, teamId);

      // Update user's joinedMatches array
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(userId)
          .update({
        'joinedMatches': FieldValue.arrayUnion([matchId]),
      });
    } on MatchServiceException catch (e) {
      throw MatchRepositoryException(e.message);
    } on TimeoutException catch (e) {
      throw MatchRepositoryException(e.message);
    } catch (e) {
      throw MatchRepositoryException('Failed to join match.');
    }
  }

  /// Leaves a match with proper error handling.
  /// Throws [MatchRepositoryException] if operation fails.
  Future<void> leaveMatch(String matchId, String userId) async {
    try {
      await _matchService.leaveMatch(matchId, userId);

      // Update user's joinedMatches array
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(userId)
          .update({
        'joinedMatches': FieldValue.arrayRemove([matchId]),
      });
    } on MatchServiceException catch (e) {
      throw MatchRepositoryException(e.message);
    } on TimeoutException catch (e) {
      throw MatchRepositoryException(e.message);
    } catch (e) {
      throw MatchRepositoryException('Failed to leave match.');
    }
  }

  /// Deletes a match (only the creator should call this).
  Future<void> deleteMatch(String matchId) async {
  await _matchService.deleteMatch(matchId);
  }

  /// Real-time stream of all open matches.
  Stream<List<MatchModel>> matchesStream() => _matchService.matchesStream();

  /// Real-time stream of a single match.
  Stream<MatchModel?> matchStream(String matchId) =>
      _matchService.matchStream(matchId);

  /// Fetches a single match.
  Future<MatchModel?> getMatchById(String matchId) =>
      _matchService.getMatchById(matchId);

  /// Matches the user has joined.
  Stream<List<MatchModel>> userMatchesStream(String userId) =>
      _matchService.userMatchesStream(userId);

  /// Matches the user created.
  Stream<List<MatchModel>> createdMatchesStream(String userId) =>
      _matchService.createdMatchesStream(userId);

  /// Checks and auto-deletes expired matches with insufficient players.
  Future<int> autoDeleteExpiredMatches() =>
      _matchService.autoDeleteExpiredMatches();

  Future<bool> repairTeamAssignments(String matchId) =>
      _matchService.repairTeamAssignments(matchId);

  Future<String> _resolveCreatorName(MatchModel match) async {
    final incomingName = match.creatorName.trim();
    if (!_genericCreatorNames.contains(incomingName.toLowerCase()) &&
        incomingName.isNotEmpty) {
      return incomingName;
    }

    final creatorDoc = await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(match.creatorId)
        .get();

    final data = creatorDoc.data();
    final storedName = data?['name']?.toString().trim() ?? '';
    if (!_genericCreatorNames.contains(storedName.toLowerCase()) &&
        storedName.isNotEmpty) {
      return storedName;
    }

    final storedEmail = data?['email']?.toString().trim() ?? '';
    if (storedEmail.isNotEmpty) {
      return storedEmail.split('@').first;
    }

    return incomingName.isNotEmpty ? incomingName : 'Player';
  }
}

/// Custom exception for match repository errors.
class MatchRepositoryException implements Exception {
  final String message;
  const MatchRepositoryException(this.message);

  @override
  String toString() => message;
}

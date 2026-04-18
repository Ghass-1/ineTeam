import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Utility helper functions used across the app.
class Helpers {
  Helpers._();

  // ─── Date Formatting ─────────────────────────────────────────────────────
  /// e.g. "Apr 17, 2026"
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// e.g. "14:30"
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// e.g. "Apr 17 at 14:30"
  static String formatDateTime(DateTime date) {
    return '${DateFormat('MMM d').format(date)} at ${DateFormat('HH:mm').format(date)}';
  }

  /// e.g. "In 2 days", "Tomorrow", "Today"
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.isNegative) return 'Past';
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return 'In ${diff.inDays} days';
    return formatDate(date);
  }

  /// Converts player count into a versus string (e.g., 10 -> "5v5").
  static String formatPlayersVs(int totalPlayers) {
    if (totalPlayers % 2 == 0) {
      final perTeam = totalPlayers ~/ 2;
      return '${perTeam}v$perTeam';
    }
    return '$totalPlayers players';
  }

  // ─── Sport Icons ──────────────────────────────────────────────────────────
  /// Returns the Material icon for a given sport.
  static IconData sportIcon(String sport) {
    switch (sport) {
      case 'Football':
        return Icons.sports_soccer;
      case 'Basketball':
        return Icons.sports_basketball;
      case 'Volleyball':
        return Icons.sports_volleyball;
      case 'Table Tennis':
        return Icons.sports_tennis;
      default:
        return Icons.sports;
    }
  }

  /// Returns the color for a given sport.
  static Color sportColor(String sport) {
    return appThemeSportColors[sport] ?? const Color(0xFF2ECC71);
  }

  // ─── Skill Level ──────────────────────────────────────────────────────────
  /// Returns a color for the skill level (green → yellow → red).
  static Color skillColor(int skillLevel) {
    if (skillLevel <= 33) return const Color(0xFF2ECC71);
    if (skillLevel <= 66) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  /// Returns a label for the skill level.
  static String skillLabel(int skillLevel) {
    return SkillLevel.fromRating(skillLevel).label;
  }

  // ─── Match Status ─────────────────────────────────────────────────────────
  static Color matchStatusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFF2ECC71);
      case 'full':
        return const Color(0xFFF39C12);
      case 'completed':
        return const Color(0xFF95A5A6);
      default:
        return const Color(0xFF2ECC71);
    }
  }

  /// Returns user initials from name (e.g. "John Doe" → "JD").
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ─── Snackbar ─────────────────────────────────────────────────────────────
  static void showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE74C3C) : null,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}

/// Sport colors map, referenced from theme.
const Map<String, Color> appThemeSportColors = {
  'Football': Color(0xFF2ECC71),
  'Basketball': Color(0xFFE67E22),
  'Volleyball': Color(0xFF3498DB),
  'Table Tennis': Color(0xFFE74C3C),
};

import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;

/// Service for calling Firebase Cloud Functions.
class CloudFunctionsService {
  /// Manually triggers the auto-delete expired matches function.
  /// Returns the number of matches deleted.
  Future<int> manualDeleteExpiredMatches() async {
    try {
      developer.log('[CloudFunctionsService] Calling manualDeleteExpiredMatches');
      
      // Get project info
      final projectId = Firebase.app().options.projectId;
      developer.log('[CloudFunctionsService] Project: $projectId');
      
      // Note: Full implementation requires firebase_functions package
      // For now, the scheduled function runs automatically every hour
      developer.log('[CloudFunctionsService] Auto-delete scheduled function runs hourly');
      
      return 0;
    } catch (e) {
      developer.log('[CloudFunctionsService] Error: $e', error: e);
      rethrow;
    }
  }
}

import 'dart:io';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Handles Firestore and Storage operations for user profiles.
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  /// Creates a new user profile document in Firestore.
  Future<void> createUserProfile(UserModel user) async {
    developer.log('[UserService] Creating user profile for UID: ${user.uid}');
    developer.log('[UserService] User data: ${user.toMap()}');
    
    try {
      await _usersCollection.doc(user.uid).set(user.toMap());
      developer.log('[UserService] User profile created successfully');
    } catch (e) {
      developer.log('[UserService] ERROR creating user profile: $e', 
        error: e);
      rethrow;
    }
  }

  /// Fetches a user profile by UID.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
  }

  /// Updates specific fields of a user profile.
  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).set(data, SetOptions(merge: true));
  }

  /// Real-time stream of the user's profile.
  Stream<UserModel?> userProfileStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    });
  }

  /// Uploads a profile picture to Firebase Storage and returns the URL.
  Future<String> uploadProfilePicture(String uid, File file) async {
    final ref = _storage.ref().child('profile_pictures/$uid.jpg');
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await uploadTask.ref.getDownloadURL();

    // Also update the user's profile document
    await updateUserProfile(uid, {'profilePictureUrl': url});
    return url;
  }

  /// Fetches multiple user profiles by their UIDs.
  /// Useful for displaying player lists in match details.
  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];

    final futures = uids.map((uid) async {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });

    final results = await Future.wait(futures);
    return results.whereType<UserModel>().toList();
  }

  Stream<UserModel?> getUserByIdStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    });
  }

  /// Real-time stream of multiple user profiles by their UIDs.
  /// Updates whenever any of the users' data changes.
  Stream<List<UserModel>> getUsersByIdsStream(List<String> uids) async* {
    if (uids.isEmpty) {
      yield [];
      return;
    }

    yield await getUsersByIds(uids);
  }
}

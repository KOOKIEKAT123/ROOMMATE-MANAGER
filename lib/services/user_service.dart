import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update user record
  Future<void> createOrUpdateUser(User firebaseUser) async {
    try {
      await _firestore.collection('users').doc(firebaseUser.uid).set(
        {
          'uid': firebaseUser.uid,
          'email': firebaseUser.email?.toLowerCase() ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get user by email
  Future<String?> getUserIdByEmail(String email) async {
    try {
      final result = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      if (result.docs.isNotEmpty) {
        return result.docs.first.id;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}

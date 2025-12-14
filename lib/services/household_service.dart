import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommate_manager/models/household.dart';
import 'package:roommate_manager/models/member.dart';

class HouseholdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a household
  Future<String> createHousehold(Household household) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('households')
          .add(household.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Get household
  Future<Household?> getHousehold(String householdId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('households').doc(householdId).get();
      if (doc.exists) {
        return Household.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get user's households
  Stream<List<Household>> getUserHouseholds(String userId) {
    return _firestore
        .collection('households')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Household.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add member to household
  Future<void> addMemberToHousehold(
      String householdId, Member member) async {
    try {
      // Add member to members subcollection
      await _firestore
          .collection('households')
          .doc(householdId)
          .collection('members')
          .doc(member.id)
          .set(member.toMap());

      // Add member ID to household's memberIds array
      await _firestore
          .collection('households')
          .doc(householdId)
          .update({
        'memberIds': FieldValue.arrayUnion([member.id])
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get household members
  Stream<List<Member>> getHouseholdMembers(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('members')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Member.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update household
  Future<void> updateHousehold(String householdId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('households')
          .doc(householdId)
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete household
  Future<void> deleteHousehold(String householdId) async {
    try {
      await _firestore.collection('households').doc(householdId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Check if email is registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Check if the email exists in a users collection
      final result = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      // If collection doesn't exist, return false
      return false;
    }
  }

  // Remove member from household
  Future<void> removeMemberFromHousehold(
      String householdId, String memberId) async {
    try {
      // Remove member document
      await _firestore
          .collection('households')
          .doc(householdId)
          .collection('members')
          .doc(memberId)
          .delete();

      // Remove member ID from household's memberIds array
      await _firestore
          .collection('households')
          .doc(householdId)
          .update({
        'memberIds': FieldValue.arrayRemove([memberId])
      });
    } catch (e) {
      rethrow;
    }
  }
}

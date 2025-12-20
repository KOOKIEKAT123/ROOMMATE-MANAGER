import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roommate_manager/models/chore.dart';

class ChoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add chore
  Future<String> addChore(Chore chore) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('households')
          .doc(chore.householdId)
          .collection('chores')
          .add(chore.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Get household chores
  Stream<List<Chore>> getHouseholdChores(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('chores')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Chore.fromMap(doc.data(), doc.id)).toList());
  }

  // Get member's chores
  Stream<List<Chore>> getMemberChores(String householdId, String memberId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('chores')
        .where('assignedTo', isEqualTo: memberId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Chore.fromMap(doc.data(), doc.id)).toList());
  }

  // Mark chore as completed
  Future<void> markChoreCompleted(String householdId, String choreId) async {
    try {
      await _firestore.collection('households').doc(householdId).collection('chores').doc(choreId).update({
        'completed': true,
        'lastCompletedAt': DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Mark chore as incomplete (for weekly reset)
  Future<void> markChoreIncomplete(String householdId, String choreId) async {
    try {
      await _firestore.collection('households').doc(householdId).collection('chores').doc(choreId).update({
        'completed': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update chore
  Future<void> updateChore(String householdId, String choreId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('households').doc(householdId).collection('chores').doc(choreId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete chore
  Future<void> deleteChore(String householdId, String choreId) async {
    try {
      await _firestore.collection('households').doc(householdId).collection('chores').doc(choreId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get overdue chores (daily chores not completed today)
  Future<List<Chore>> getOverdueChores(String householdId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('households')
          .doc(householdId)
          .collection('chores')
          .where('frequency', isEqualTo: 'daily')
          .where('completed', isEqualTo: false)
          .get();

      return snapshot.docs.map((doc) => Chore.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      rethrow;
    }
  }
}

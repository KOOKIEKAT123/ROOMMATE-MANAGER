import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roommate_manager/models/expense.dart';
import 'package:roommate_manager/models/settlement.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add expense
  Future<String> addExpense(Expense expense) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('households')
          .doc(expense.householdId)
          .collection('expenses')
          .add(expense.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Get household expenses
  Stream<List<Expense>> getHouseholdExpenses(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get expenses by date range
  Stream<List<Expense>> getExpensesByDateRange(
    String householdId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Delete expense
  Future<void> deleteExpense(String householdId, String expenseId) async {
    try {
      await _firestore
          .collection('households')
          .doc(householdId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Add settlement
  Future<String> addSettlement(Settlement settlement) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('households')
          .doc(settlement.householdId)
          .collection('settlements')
          .add(settlement.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Get settlements
  Stream<List<Settlement>> getSettlements(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('settlements')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Settlement.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Calculate balances
  Future<Map<String, double>> calculateBalances(String householdId) async {
    try {
      // Get all expenses and settlements
      QuerySnapshot expensesSnapshot = await _firestore
          .collection('households')
          .doc(householdId)
          .collection('expenses')
          .get();

      QuerySnapshot settlementsSnapshot = await _firestore
          .collection('households')
          .doc(householdId)
          .collection('settlements')
          .get();

      Map<String, double> balances = {};

      // Process expenses
      for (var doc in expensesSnapshot.docs) {
        Expense expense = Expense.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        
        // Each person's balance = what they owe - what they paid
        for (var entry in expense.splits.entries) {
          String memberId = entry.key;
          double owedAmount = entry.value;
          balances[memberId] = (balances[memberId] ?? 0) - owedAmount;
        }
        
        balances[expense.payerId] = (balances[expense.payerId] ?? 0) + expense.amount;
      }

      // Process settlements
      for (var doc in settlementsSnapshot.docs) {
        Settlement settlement =
            Settlement.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        balances[settlement.fromMemberId] =
            (balances[settlement.fromMemberId] ?? 0) - settlement.amount;
        balances[settlement.toMemberId] =
            (balances[settlement.toMemberId] ?? 0) + settlement.amount;
      }

      return balances;
    } catch (e) {
      rethrow;
    }
  }
}

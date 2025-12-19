import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/expense_service.dart';
import '../../services/household_service.dart';
import '../../models/expense.dart';
import '../../models/member.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatelessWidget {
  final String householdId;

  const ExpensesScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context) {
    final expenseService = context.read<ExpenseService>();
    final householdService = context.read<HouseholdService>();

    return Scaffold(
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.getHouseholdExpenses(householdId),
        builder: (context, expenseSnapshot) {
          if (expenseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!expenseSnapshot.hasData || expenseSnapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first expense',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<List<Member>>(
            stream: householdService.getHouseholdMembers(householdId),
            builder: (context, memberSnapshot) {
              if (memberSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = memberSnapshot.data ?? [];
              final memberMap = {for (var m in members) m.id: m.name};

              return ListView.builder(
                itemCount: expenseSnapshot.data!.length,
                itemBuilder: (context, index) {
                  final expense = expenseSnapshot.data![index];
                  final payerName = memberMap[expense.payerId] ?? 'Unknown';

                  return ListTile(
                    leading: const Icon(Icons.receipt),
                    title: Text(expense.description),
                    subtitle: Text(
                      'Paid by $payerName • ${expense.splitMethod.toString().split('.').last}',
                    ),
                    trailing: Text(
                      '\$${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Expense?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                expenseService.deleteExpense(
                                  householdId,
                                  expense.id,
                                );
                                Navigator.pop(context);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(householdId: householdId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

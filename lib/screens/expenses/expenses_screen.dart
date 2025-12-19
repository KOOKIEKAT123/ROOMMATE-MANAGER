import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/expense_service.dart';
import '../../services/household_service.dart';
import '../../models/expense.dart';
import '../../models/member.dart';
import 'add_expense_screen.dart';
import '../balance/settle_up_screen.dart';

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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading expenses...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          if (!expenseSnapshot.hasData || expenseSnapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No expenses yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first expense',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<List<Member>>(
            stream: householdService.getHouseholdMembers(householdId),
            builder: (context, memberSnapshot) {
              if (memberSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }

              final members = memberSnapshot.data ?? [];
              final memberMap = {for (var m in members) m.id: m.name};

              return FutureBuilder<Map<String, double>>(
                future: expenseService.calculateBalances(householdId),
                builder: (context, balanceSnapshot) {
                  final balances = balanceSnapshot.data ?? {};
                  final totalOutstanding = balances.values
                      .where((v) => v > 0)
                      .fold<double>(0.0, (p, c) => p + c);

                  final transfers = _computeTransfers(balances);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      // Total Outstanding
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Total Outstanding',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${totalOutstanding.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Who Owes What',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (transfers.isEmpty)
                        Text(
                          'All settled up. 🎉',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...transfers.map((t) {
                          final fromName = memberMap[t.from] ?? 'Unknown';
                          final toName = memberMap[t.to] ?? 'Unknown';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    fromName,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                const Icon(Icons.double_arrow),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(toName, style: Theme.of(context).textTheme.titleMedium),
                                        Text('\$${t.amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.labelLarge),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SettleUpScreen(householdId: householdId),
                              ),
                            );
                          },
                          child: const Text('MARK PAYMENT'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Recent Expenses',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...expenseSnapshot.data!.map((expense) {
                        final payerName = memberMap[expense.payerId] ?? 'Unknown';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onLongPress: () {
                                _showDeleteDialog(context, expenseService, householdId, expense);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.receipt,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            expense.description,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Paid by $payerName • ${expense.splitMethod.toString().split('.').last}',
                                            style: Theme.of(context).textTheme.labelSmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '\$${expense.amount.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(householdId: householdId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ExpenseService expenseService,
    String householdId,
    Expense expense,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text('Remove "${expense.description}" permanently?'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Expense deleted'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Greedy settle-up suggestion generator
  List<_Transfer> _computeTransfers(Map<String, double> balances) {
    final debtors = <_Entry>[]; // owe to others (positive)
    final creditors = <_Entry>[]; // should receive (negative)
    balances.forEach((id, bal) {
      if (bal > 0.01) debtors.add(_Entry(id, bal));
      if (bal < -0.01) creditors.add(_Entry(id, -bal));
    });
    debtors.sort((a, b) => b.amount.compareTo(a.amount));
    creditors.sort((a, b) => b.amount.compareTo(a.amount));

    final transfers = <_Transfer>[];
    int i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      final pay = debtors[i];
      final recv = creditors[j];
      final amt = pay.amount < recv.amount ? pay.amount : recv.amount;
      transfers.add(_Transfer(from: pay.id, to: recv.id, amount: amt));
      pay.amount -= amt;
      recv.amount -= amt;
      if (pay.amount <= 0.01) i++;
      if (recv.amount <= 0.01) j++;
    }
    return transfers;
  }
}

class _Entry {
  final String id;
  double amount;
  _Entry(this.id, this.amount);
}

class _Transfer {
  final String from;
  final String to;
  final double amount;
  _Transfer({required this.from, required this.to, required this.amount});
}
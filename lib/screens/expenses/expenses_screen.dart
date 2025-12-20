import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../models/member.dart';
import '../../services/expense_service.dart';
import '../../services/household_service.dart';
import '../balance/settle_up_screen.dart';
import 'add_expense_screen.dart';

// ignore_for_file: prefer_if_elements_to_conditional_expressions, dead_code

class TransferData {
  final String from;
  final String to;
  final double amount;

  TransferData({required this.from, required this.to, required this.amount});
}

class ExpensesScreen extends StatelessWidget {
  final String householdId;

  const ExpensesScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context) {
    final expenseService = context.read<ExpenseService>();
    final householdService = context.read<HouseholdService>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.18),
            Theme.of(context).colorScheme.surface.withOpacity(0.6),
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.18),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: _buildAnimatedFAB(),
        body: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _glowBlob(
                140,
                Theme.of(context).colorScheme.primary.withOpacity(0.12),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: _glowBlob(
                120,
                Theme.of(context).colorScheme.secondary.withOpacity(0.12),
              ),
            ),

            /// EXPENSE STREAM
            StreamBuilder<List<Expense>>(
              stream: expenseService.getHouseholdExpenses(householdId),
              builder: (context, expenseSnapshot) {
                if (expenseSnapshot.connectionState ==
                    ConnectionState.waiting) {
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
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
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

                /// MEMBER STREAM
                return StreamBuilder<List<Member>>(
                  stream: householdService.getHouseholdMembers(householdId),
                  builder: (context, memberSnapshot) {
                    if (memberSnapshot.connectionState ==
                        ConnectionState.waiting) {
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

                    /// BALANCE FUTURE
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
                            /// TOTAL OUTSTANDING CARD
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: 0.9 + (0.1 * value),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                                      Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer
                                          .withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Total Outstanding',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tk ${totalOutstanding.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryContainer,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            Text(
                              'Who Owes What',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            if (transfers.isEmpty)
                              _buildAllSettledCard(context)
                            else
                              ...transfers.asMap().entries.map((entry) {
                                final transfer = entry.value;
                                final index = entry.key;

                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(
                                    milliseconds: 300 + index * 100,
                                  ),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 15 * (1 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _buildTransferCard(
                                    context,
                                    memberMap[transfer.from] ?? 'Unknown',
                                    memberMap[transfer.to] ?? 'Unknown',
                                    transfer.amount,
                                  ),
                                );
                              }),

                            const SizedBox(height: 16),
                            _buildMarkPaymentButton(context),
                            const SizedBox(height: 24),

                            Text(
                              'Recent Expenses',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),

                            ...expenseSnapshot.data!.asMap().entries.map((
                              entry,
                            ) {
                              final expense = entry.value;
                              final index = entry.key;

                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(
                                  milliseconds: 300 + index * 50,
                                ),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildExpenseCard(
                                  context,
                                  expense,
                                  memberMap[expense.payerId] ?? 'Unknown',
                                  index,
                                  expenseService,
                                  householdId,
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
          ],
        ),
      ),
    );
  }

  Widget _buildAllSettledCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.green.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'All settled up! 🎉',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.green.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    Expense expense,
    String payerName,
    int index,
    ExpenseService expenseService,
    String householdId,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: isHovered
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.12),
                        Theme.of(context).colorScheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: !isHovered
                  ? Theme.of(context).colorScheme.surface.withOpacity(0.92)
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                    : Theme.of(context).colorScheme.outlineVariant,
                width: isHovered ? 2 : 1,
              ),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 6,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary
                              .withOpacity(isHovered ? 0.28 : 0.12),
                          blurRadius: isHovered ? 18 : 10,
                          offset: const Offset(1, 0),
                        ),
                      ],
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onLongPress: () {
                      _showDeleteDialog(
                        context,
                        expenseService,
                        householdId,
                        expense,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    splashColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.08),
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.2)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
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
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Paid by $payerName • ${expense.splitMethod.toString().split('.').last}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.color
                                            ?.withOpacity(0.7),
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.2)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Tk ${expense.amount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isHovered
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedFAB() {
    return Builder(
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddExpenseScreen(householdId: householdId),
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            elevation: 0,
            label: const Text('Add Expense'),
            icon: const Icon(Icons.add),
          ),
        );
      },
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
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await expenseService.deleteExpense(householdId, expense.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferCard(
    BuildContext context,
    String fromName,
    String toName,
    double amount,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$fromName → $toName',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Transfer payment',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Text(
              'Tk ${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowBlob(double size, Color color) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [color, Colors.transparent],
              radius: 0.85,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkPaymentButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettleUpScreen(householdId: householdId),
          ),
        ),
        child: Text(
          'Mark Payment',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  List<TransferData> _computeTransfers(Map<String, double> balances) {
    List<TransferData> transfers = [];
    Map<String, double> remaining = Map.from(balances);

    while (remaining.values.any((v) => v.abs() > 0.01)) {
      String? debtor;
      String? creditor;
      double maxDebt = 0;
      double maxCredit = 0;

      remaining.forEach((id, balance) {
        if (balance < -maxDebt) {
          maxDebt = balance.abs();
          debtor = id;
        }
        if (balance > maxCredit) {
          maxCredit = balance;
          creditor = id;
        }
      });

      if (debtor != null && creditor != null) {
        final String debtorId = debtor!;
        final String creditorId = creditor!;
        double amount = min(maxDebt, maxCredit).toDouble();
        transfers.add(
          TransferData(from: debtorId, to: creditorId, amount: amount),
        );
        remaining[debtorId] = remaining[debtorId]! + amount;
        remaining[creditorId] = remaining[creditorId]! - amount;
      } else {
        break;
      }
    }

    return transfers;
  }
}

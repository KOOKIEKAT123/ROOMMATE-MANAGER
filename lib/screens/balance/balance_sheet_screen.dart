import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/expense_service.dart';
import '../../services/household_service.dart';
import '../../models/member.dart';
import 'settle_up_screen.dart';

class BalanceSheetScreen extends StatelessWidget {
  final String householdId;

  const BalanceSheetScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context) {
    final expenseService = context.read<ExpenseService>();
    final householdService = context.read<HouseholdService>();

    return Scaffold(
      body: FutureBuilder<Map<String, double>>(
        future: expenseService.calculateBalances(householdId),
        builder: (context, balanceSnapshot) {
          if (balanceSnapshot.connectionState == ConnectionState.waiting) {
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
                    'Calculating balances...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          if (!balanceSnapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load balances',
                    style: Theme.of(context).textTheme.headlineSmall,
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
              final balances = balanceSnapshot.data ?? {};
              final memberMap = {for (var m in members) m.id: m};

              // Sort members by balance (owe most to least)
              final sortedEntries = balances.entries.toList()
                ..sort((a, b) => a.value.compareTo(b.value));

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance Summary',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...sortedEntries.map((entry) {
                      final member = memberMap[entry.key];
                      final balance = entry.value;
                      
                      if (balance.abs() < 0.01) return const SizedBox.shrink();
                      
                      final isOwing = balance > 0;
                      final badgeColor = isOwing
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.secondaryContainer;
                      final badgeTextColor = isOwing
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.secondary;

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
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member?.name ?? 'Unknown',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isOwing ? 'Owes the group' : 'Owed by the group',
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isOwing
                                        ? '\$${balance.toStringAsFixed(2)}'
                                        : '\$${(-balance).toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: badgeTextColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SettleUpScreen(householdId: householdId),
            ),
          );
        },
        icon: const Icon(Icons.payment),
        label: const Text('Settle Up'),
      ),
    );
  }
}

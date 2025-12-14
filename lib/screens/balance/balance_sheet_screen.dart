import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/expense_service.dart';
import '../../services/household_service.dart';
import '../../models/member.dart';
import 'settle_up_screen.dart';

class BalanceSheetScreen extends StatelessWidget {
  final String householdId;

  const BalanceSheetScreen({Key? key, required this.householdId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expenseService = context.read<ExpenseService>();
    final householdService = context.read<HouseholdService>();

    return Scaffold(
      body: FutureBuilder<Map<String, double>>(
        future: expenseService.calculateBalances(householdId),
        builder: (context, balanceSnapshot) {
          if (balanceSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!balanceSnapshot.hasData) {
            return const Center(child: Text('Unable to load balances'));
          }

          return StreamBuilder<List<Member>>(
            stream: householdService.getHouseholdMembers(householdId),
            builder: (context, memberSnapshot) {
              if (memberSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = memberSnapshot.data ?? [];
              final balances = balanceSnapshot.data ?? {};
              final memberMap = {for (var m in members) m.id: m};

              // Sort members by balance (owe most to least)
              final sortedEntries = balances.entries.toList()
                ..sort((a, b) => a.value.compareTo(b.value));

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Balance Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...sortedEntries.map((entry) {
                          final member = memberMap[entry.key];
                          final balance = entry.value;
                          
                          if (balance.abs() < 0.01) return const SizedBox.shrink();
                          
                          final color = balance > 0
                              ? Colors.red
                              : Colors.green;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    member?.name ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    balance > 0
                                        ? 'owes \$${balance.toStringAsFixed(2)}'
                                        : 'is owed \$${(-balance).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final balance = balances[member.id] ?? 0;

                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(member.name),
                          trailing: Text(
                            balance > 0
                                ? 'owes \$${balance.toStringAsFixed(2)}'
                                : balance < 0
                                    ? 'is owed \$${(-balance).toStringAsFixed(2)}'
                                    : 'settled',
                            style: TextStyle(
                              color: balance > 0
                                  ? Colors.red
                                  : balance < 0
                                      ? Colors.green
                                      : Colors.grey,
                            ),
                          ),
                          onTap: balance != 0
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SettleUpScreen(
                                        householdId: householdId,
                                        selectedMemberId: member.id,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SettleUpScreen(householdId: householdId),
            ),
          );
        },
        child: const Icon(Icons.payment),
      ),
    );
  }
}

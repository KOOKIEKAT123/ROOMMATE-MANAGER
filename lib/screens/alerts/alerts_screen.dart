import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/expense_service.dart';
import '../../services/chore_service.dart';
import '../../services/household_service.dart';
import '../../models/member.dart';
import '../../models/chore.dart';

class AlertsScreen extends StatelessWidget {
  final String householdId;

  const AlertsScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context) {
    final expenseService = context.read<ExpenseService>();
    final choreService = context.read<ChoreService>();
    final householdService = context.read<HouseholdService>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.18),
            Theme.of(context).colorScheme.surface.withOpacity(0.6),
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Alerts & Reminders'),
        ),
        body: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _glowBlob(140, Theme.of(context).colorScheme.primary.withOpacity(0.12)),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: _glowBlob(120, Theme.of(context).colorScheme.error.withOpacity(0.1)),
            ),
            FutureBuilder<Map<String, double>>(
        future: expenseService.calculateBalances(householdId),
        builder: (context, balanceSnapshot) {
          return StreamBuilder<List<Chore>>(
            stream: choreService.getHouseholdChores(householdId),
            builder: (context, choreSnapshot) {
              if (choreSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final chores = choreSnapshot.data ?? [];
              final now = DateTime.now();

              int overdueCount = 0;
              final List<Chore> overdueChores = [];

              for (final c in chores) {
                final due = _computeDueDate(c);
                final isOverdue = !c.completed && due.isBefore(now);
                if (isOverdue) {
                  overdueCount++;
                  overdueChores.add(c);
                }
              }

              final balances = balanceSnapshot.data ?? {};
              // Total outstanding = sum of positive balances (amount owed to others)
              double totalOutstanding = 0;
              for (final v in balances.values) {
                if (v > 0) totalOutstanding += v;
              }

              return StreamBuilder<List<Member>>(
                stream: householdService.getHouseholdMembers(householdId),
                builder: (context, memberSnapshot) {
                  final members = memberSnapshot.data ?? [];
                  final memberMap = {for (var m in members) m.id: m.name};

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _summaryTile(
                                context,
                                title: 'Overdue Chores',
                                value: overdueCount.toString(),
                                icon: Icons.warning_amber_rounded,
                                color: Theme.of(context).colorScheme.errorContainer,
                                textColor: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryTile(
                                context,
                                title: 'Unsettled Balances',
                                value: totalOutstanding.toStringAsFixed(2),
                                icon: Icons.account_balance_wallet_outlined,
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active Alerts',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${overdueChores.length} Notifications',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (overdueChores.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            child: const Text('No overdue chores right now.'),
                          )
                        else
                          ...overdueChores.map((c) {
                            final assignee = memberMap[c.assignedTo] ?? 'Unknown';
                            final daysAgo = DateTime.now().difference(_computeDueDate(c)).inDays.abs();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                                  child: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                                ),
                                title: Text('Overdue: "${c.title}" assigned to $assignee'),
                                subtitle: Text(
                                  '${c.frequency.toString().split('.').last.toUpperCase()}  •  $daysAgo day(s) ago',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.done),
                                  tooltip: 'Mark complete',
                                  onPressed: () {
                                    context.read<ChoreService>().markChoreCompleted(householdId, c.id);
                                  },
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // Mark all as read is just a UX affordance here
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(const SnackBar(content: Text('All caught up!')));
                                },
                                child: const Text('Mark all as read'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () {
                                  // No persisted notifications to clear; provide feedback
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleared')));
                                },
                                child: const Text('Clear All'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

  DateTime _computeDueDate(Chore c) {
    final base = c.lastCompletedAt ?? c.createdAt;
    if (c.frequency == ChoreFrequency.daily) {
      return base.add(const Duration(days: 1));
    }
    return base.add(const Duration(days: 7));
  }

  Widget _summaryTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 6),
              Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: textColor)),
            ],
          ),
        ],
      ),
    );
  }
}

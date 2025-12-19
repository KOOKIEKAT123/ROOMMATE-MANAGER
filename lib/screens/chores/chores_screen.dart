import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/chore_service.dart';
import '../../services/household_service.dart';
import '../../models/chore.dart';
import '../../models/member.dart';
import 'add_chore_screen.dart';

class ChoresScreen extends StatelessWidget {
  final String householdId;

  const ChoresScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context) {
    final choreService = context.read<ChoreService>();
    final householdService = context.read<HouseholdService>();

    return Scaffold(
      body: StreamBuilder<List<Chore>>(
        stream: choreService.getHouseholdChores(householdId),
        builder: (context, choreSnapshot) {
          if (choreSnapshot.connectionState == ConnectionState.waiting) {
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
                    'Loading chores...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          if (!choreSnapshot.hasData || choreSnapshot.data!.isEmpty) {
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
                      Icons.cleaning_services,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No chores yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first chore',
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

              // Summary counters
              final chores = choreSnapshot.data!;
              final now = DateTime.now();
              int total = chores.length;
              int overdue = 0;
              int incoming = 0;
              for (final c in chores) {
                final due = _computeDueDate(c);
                final isOverdue = !c.completed && due.isBefore(now);
                final isIncoming = !c.completed && !isOverdue && due.isBefore(now.add(const Duration(days: 3)));
                if (isOverdue) overdue++;
                if (isIncoming) incoming++;
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: chores.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _summaryTile(context, 'Total Chores', total.toString(), Theme.of(context).colorScheme.secondaryContainer)),
                            const SizedBox(width: 12),
                            Expanded(child: _summaryTile(context, 'Overdue', overdue.toString(), Theme.of(context).colorScheme.errorContainer)),
                            const SizedBox(width: 12),
                            Expanded(child: _summaryTile(context, 'Incoming', incoming.toString(), Theme.of(context).colorScheme.primaryContainer)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('ALL Chores', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                      ],
                    );
                  }

                  final chore = chores[index - 1];
                  final assigneeName = memberMap[chore.assignedTo] ?? 'Unknown';

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
                          children: [
                            Checkbox(
                              value: chore.completed,
                              onChanged: (value) {
                                if (value == true) {
                                  context.read<ChoreService>().markChoreCompleted(
                                    householdId,
                                    chore.id,
                                  );
                                } else {
                                  context.read<ChoreService>().markChoreIncomplete(
                                    householdId,
                                    chore.id,
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chore.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      decoration: chore.completed
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: chore.completed
                                          ? Theme.of(context).colorScheme.outline
                                          : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Assigned to $assigneeName • ${chore.frequency.toString().split('.').last}',
                                    style: Theme.of(context).textTheme.labelSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: PopupMenuButton(
                                position: PopupMenuPosition.under,
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Theme.of(context).colorScheme.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Delete'),
                                      ],
                                    ),
                                    onTap: () {
                                      context.read<ChoreService>().deleteChore(
                                        householdId,
                                        chore.id,
                                      );
                                    },
                                  ),
                                ],
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
              builder: (_) => AddChoreScreen(householdId: householdId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Chore'),
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

  Widget _summaryTile(BuildContext context, String title, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

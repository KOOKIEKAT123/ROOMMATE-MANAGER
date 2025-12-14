import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/chore_service.dart';
import '../../services/household_service.dart';
import '../../models/chore.dart';
import '../../models/member.dart';
import 'add_chore_screen.dart';

class ChoresScreen extends StatelessWidget {
  final String householdId;

  const ChoresScreen({Key? key, required this.householdId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final choreService = context.read<ChoreService>();
    final householdService = context.read<HouseholdService>();

    return Scaffold(
      body: StreamBuilder<List<Chore>>(
        stream: choreService.getHouseholdChores(householdId),
        builder: (context, choreSnapshot) {
          if (choreSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!choreSnapshot.hasData || choreSnapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cleaning_services,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chores yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first chore',
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
                itemCount: choreSnapshot.data!.length,
                itemBuilder: (context, index) {
                  final chore = choreSnapshot.data![index];
                  final assigneeName = memberMap[chore.assignedTo] ?? 'Unknown';

                  return ListTile(
                    leading: Checkbox(
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
                    title: Text(
                      chore.title,
                      style: TextStyle(
                        decoration: chore.completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text(
                      'Assigned to $assigneeName • ${chore.frequency.toString().split('.').last}',
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Delete'),
                          onTap: () {
                            context.read<ChoreService>().deleteChore(
                                  householdId,
                                  chore.id,
                                );
                          },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddChoreScreen(householdId: householdId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

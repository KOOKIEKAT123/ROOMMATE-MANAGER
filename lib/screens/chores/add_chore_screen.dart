import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/chore_service.dart';
import '../../services/household_service.dart';
import '../../services/notification_service.dart';
import '../../models/chore.dart';
import '../../models/member.dart';

class AddChoreScreen extends StatefulWidget {
  final String householdId;

  const AddChoreScreen({super.key, required this.householdId});

  @override
  State<AddChoreScreen> createState() => _AddChoreScreenState();
}

class _AddChoreScreenState extends State<AddChoreScreen> {
  final _titleController = TextEditingController();
  String? _selectedMemberId;
  ChoreFrequency _frequency = ChoreFrequency.weekly;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addChore() async {
    if (_titleController.text.isEmpty || _selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final choreService = context.read<ChoreService>();
      final householdService = context.read<HouseholdService>();

      final chore = Chore(
        id: '',
        title: _titleController.text,
        frequency: _frequency,
        assignedTo: _selectedMemberId!,
        completed: false,
        createdAt: DateTime.now(),
        householdId: widget.householdId,
      );

      await choreService.addChore(chore);

      if (mounted) {
        // Get assigned member name
        final members = await householdService
            .getHouseholdMembers(widget.householdId)
            .first;
        final assignedMember = members.firstWhere(
          (m) => m.id == _selectedMemberId,
          orElse: () => members.isNotEmpty ? members.first : members[0],
        );

        // Show notification
        NotificationService().showChoreDeadlineNotification(
          title: '🧹 New Chore Assigned',
          choreTitle: _titleController.text,
          assignee: assignedMember.name,
        );

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chore added successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final householdService = context.read<HouseholdService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Chore'),
      ),
      body: StreamBuilder<List<Member>>(
        stream: householdService.getHouseholdMembers(widget.householdId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Chore Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedMemberId,
                  items: members
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMemberId = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Assign To',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Frequency'),
                RadioListTile<ChoreFrequency>(
                  title: const Text('Daily'),
                  value: ChoreFrequency.daily,
                  groupValue: _frequency,
                  onChanged: (value) {
                    setState(() {
                      _frequency = value ?? ChoreFrequency.weekly;
                    });
                  },
                ),
                RadioListTile<ChoreFrequency>(
                  title: const Text('Weekly'),
                  value: ChoreFrequency.weekly,
                  groupValue: _frequency,
                  onChanged: (value) {
                    setState(() {
                      _frequency = value ?? ChoreFrequency.weekly;
                    });
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addChore,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Chore'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/household_service.dart';
import '../../models/household.dart';
import '../../models/member.dart';

class CreateHouseholdScreen extends StatefulWidget {
  const CreateHouseholdScreen({Key? key}) : super(key: key);

  @override
  State<CreateHouseholdScreen> createState() => _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState extends State<CreateHouseholdScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    if (_nameController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final householdService = context.read<HouseholdService>();
      final currentUser = authService.getCurrentUser();
      final userId = currentUser?.uid ?? '';
      final userEmail = currentUser?.email ?? '';

      final household = Household(
        id: '',
        name: _nameController.text,
        ownerId: userId,
        memberIds: [userId],
        categories: [
          'Food',
          'Utilities',
          'Rent',
          'Entertainment',
          'Other'
        ],
        createdAt: DateTime.now(),
      );

      final householdId = await householdService.createHousehold(household);

      // Auto-add the creator as a member
      final creatorMember = Member(
        id: userId,
        name: userEmail.split('@')[0], // Use email prefix as name initially
        email: userEmail,
        createdAt: DateTime.now(),
      );

      await householdService.addMemberToHousehold(householdId, creatorMember);

      if (mounted) {
        Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Household'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Household Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _createHousehold,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

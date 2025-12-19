import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/household_service.dart';
import '../../models/household.dart';
import '../../models/member.dart';

class CreateHouseholdScreen extends StatefulWidget {
  const CreateHouseholdScreen({super.key});

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

      if (userId.isEmpty || userEmail.isEmpty) {
        throw 'User information not available';
      }

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

      // Create the household and get its ID
      final householdId = await householdService.createHousehold(household);
      
      print('DEBUG: Household created with ID: $householdId');

      if (householdId.isEmpty) {
        throw 'Failed to create household';
      }

      // Auto-add the creator as a member (with Firebase UID as member ID)
      final creatorMember = Member(
        id: userId, // Use the Firebase UID
        name: userEmail.split('@')[0], // Use email prefix as name
        email: userEmail,
        createdAt: DateTime.now(),
      );

      print('DEBUG: Adding creator member with ID: $userId, Email: $userEmail');
      
      // Add the creator to the members collection
      await householdService.addMemberToHousehold(householdId, creatorMember);
      
      print('DEBUG: Creator member added successfully');

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('DEBUG: Error in _createHousehold: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating household: $e'),
            duration: const Duration(seconds: 4),
          ),
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

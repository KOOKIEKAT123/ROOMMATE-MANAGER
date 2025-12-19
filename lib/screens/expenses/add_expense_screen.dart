import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/expense_service.dart';
import '../../services/household_service.dart';
import '../../services/notification_service.dart';
import '../../models/expense.dart';
import '../../models/member.dart';

class AddExpenseScreen extends StatefulWidget {
  final String householdId;

  const AddExpenseScreen({super.key, required this.householdId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedPayerId;
  String? _selectedCategory;
  SplitMethod _splitMethod = SplitMethod.equal;
  bool _isLoading = false;
  final Map<String, double> _customSplits = {};

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    if (_descriptionController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedPayerId == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Validate amount is positive
    try {
      final amount = double.parse(_amountController.text);
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount must be greater than 0')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final expenseService = context.read<ExpenseService>();
      final householdService = context.read<HouseholdService>();
      final amount = double.parse(_amountController.text);

      // Get all members for equal split
      Map<String, double> splits;
      if (_splitMethod == SplitMethod.equal) {
        final membersSnapshot = await householdService
            .getHouseholdMembers(widget.householdId)
            .first;
        final memberCount = membersSnapshot.length;
        if (memberCount > 0) {
          final splitAmount = amount / memberCount;
          splits = {
            for (var member in membersSnapshot) member.id: splitAmount
          };
        } else {
          splits = {_selectedPayerId!: amount};
        }
      } else {
        splits = _customSplits.isNotEmpty
            ? _customSplits
            : {_selectedPayerId!: amount};
      }

      final expense = Expense(
        id: '',
        description: _descriptionController.text,
        amount: amount,
        payerId: _selectedPayerId!,
        splitMethod: _splitMethod,
        splits: splits,
        category: [_selectedCategory!],
        date: DateTime.now(),
        householdId: widget.householdId,
      );

      await expenseService.addExpense(expense);

      if (mounted) {
        // Show notification
        NotificationService().showExpenseNotification(
          title: '💰 Expense Added',
          description: _descriptionController.text,
          amount: '\$${amount.toStringAsFixed(2)}',
        );
        
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully'),
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
        title: const Text('Add Expense'),
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
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPayerId,
                  items: members
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPayerId = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Paid By',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  items: const [
                    DropdownMenuItem(value: 'Food', child: Text('Food')),
                    DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                    DropdownMenuItem(value: 'Rent', child: Text('Rent')),
                    DropdownMenuItem(
                        value: 'Entertainment', child: Text('Entertainment')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Split Method'),
                RadioListTile<SplitMethod>(
                  title: const Text('Equal Split'),
                  value: SplitMethod.equal,
                  groupValue: _splitMethod,
                  onChanged: (value) {
                    setState(() {
                      _splitMethod = value ?? SplitMethod.equal;
                      _customSplits.clear();
                    });
                  },
                ),
                RadioListTile<SplitMethod>(
                  title: const Text('Custom Split'),
                  value: SplitMethod.custom,
                  groupValue: _splitMethod,
                  onChanged: (value) {
                    setState(() {
                      _splitMethod = value ?? SplitMethod.equal;
                    });
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addExpense,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Expense'),
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

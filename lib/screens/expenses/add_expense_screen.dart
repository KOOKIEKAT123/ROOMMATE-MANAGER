import 'dart:ui';

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
  final Map<String, TextEditingController> _splitControllers = {};

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    for (final controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _prefillCustomSplits(List<Member> members) {
    if (members.isEmpty) return;
    final amount = double.tryParse(_amountController.text);
    final double splitAmount = amount != null && amount > 0 ? amount / members.length : 0.0;
    for (final member in members) {
      _customSplits[member.id] = splitAmount;
    }
    _syncSplitControllers(members);
  }

  void _syncSplitControllers(List<Member> members) {
    for (final member in members) {
      _splitControllers.putIfAbsent(member.id, () => TextEditingController());
      final current = _customSplits[member.id];
      if (current != null) {
        final text = current.toStringAsFixed(2);
        if (_splitControllers[member.id]!.text != text) {
          _splitControllers[member.id]!.text = text;
        }
      }
    }
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

      // Get all members for equal or custom split
      Map<String, double> splits;
      if (_splitMethod == SplitMethod.equal) {
        final membersSnapshot = await householdService.getHouseholdMembers(widget.householdId).first;
        final memberCount = membersSnapshot.length;
        if (memberCount > 0) {
          final splitAmount = amount / memberCount;
          splits = {for (var member in membersSnapshot) member.id: splitAmount};
        } else {
          splits = {_selectedPayerId!: amount};
        }
      } else {
        if (_customSplits.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter custom split amounts')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final totalSplit = _customSplits.values.fold<double>(0, (sum, v) => sum + v);
        if ((totalSplit - amount).abs() > 0.01) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Custom split total (Tk ${totalSplit.toStringAsFixed(2)}) must equal amount (Tk ${amount.toStringAsFixed(2)})'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (_customSplits.values.any((v) => v < 0)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Split amounts cannot be negative')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }

        splits = Map<String, double>.from(_customSplits);
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
          amount: 'Tk ${amount.toStringAsFixed(2)}',
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
          title: const Text('Add Expense'),
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
              child: _glowBlob(120, Theme.of(context).colorScheme.secondary.withOpacity(0.12)),
            ),
            StreamBuilder<List<Member>>(
        stream: householdService.getHouseholdMembers(widget.householdId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data ?? [];

          _syncSplitControllers(members);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      prefixText: 'Tk ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
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
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
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
                      if (_splitMethod == SplitMethod.custom) {
                        _prefillCustomSplits(members);
                      }
                    });
                  },
                ),
                if (_splitMethod == SplitMethod.custom) ...[
                  const SizedBox(height: 8),
                  Column(
                    children: members.map((member) {
                      final controller = _splitControllers[member.id]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Amount for ${member.name}',
                            prefixText: 'Tk ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (value) {
                            final parsed = double.tryParse(value);
                            setState(() {
                              if (parsed != null) {
                                _customSplits[member.id] = parsed;
                              } else {
                                _customSplits.remove(member.id);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  Builder(
                    builder: (_) {
                      final total = _customSplits.values.fold<double>(0, (sum, v) => sum + v);
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Custom split total: Tk ${total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Add Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
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
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/expense_service.dart';
import '../../services/household_service.dart';
import '../../services/notification_service.dart';
import '../../models/settlement.dart';
import '../../models/member.dart';

class SettleUpScreen extends StatefulWidget {
  final String householdId;
  final String? selectedMemberId;

  const SettleUpScreen({super.key, required this.householdId, this.selectedMemberId});

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> {
  String? _fromMemberId;
  String? _toMemberId;
  final _amountController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fromMemberId = widget.selectedMemberId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _settleUp() async {
    if (_fromMemberId == null || _toMemberId == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    // Validate members are different
    if (_fromMemberId == _toMemberId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot settle payment with the same member')));
      return;
    }

    // Validate amount is positive
    try {
      final amount = double.parse(_amountController.text);
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount must be greater than 0')));
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final expenseService = context.read<ExpenseService>();
      final householdService = context.read<HouseholdService>();
      final amount = double.parse(_amountController.text);

      final settlement = Settlement(
        id: '',
        fromMemberId: _fromMemberId!,
        toMemberId: _toMemberId!,
        amount: amount,
        method: _paymentMethod,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        date: DateTime.now(),
        householdId: widget.householdId,
      );

      await expenseService.addSettlement(settlement);

      if (mounted) {
        // Get member names for notification
        final members = await householdService.getHouseholdMembers(widget.householdId).first;
        final fromMember = members.firstWhere(
          (m) => m.id == _fromMemberId,
          orElse: () => members.isNotEmpty ? members.first : members[0],
        );
        final toMember = members.firstWhere(
          (m) => m.id == _toMemberId,
          orElse: () => members.isNotEmpty ? members.first : members[0],
        );

        // Show notification
        NotificationService().showSettlementNotification(
          title: '✅ Payment Recorded',
          message: '${fromMember.name} paid ${toMember.name} Tk ${amount.toStringAsFixed(2)}',
        );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Settlement recorded'), duration: Duration(seconds: 2)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          title: const Text('Settle Up'),
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
              child: _glowBlob(120, Theme.of(context).colorScheme.tertiary.withOpacity(0.12)),
            ),
            StreamBuilder<List<Member>>(
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
                DropdownButtonFormField<String>(
                  initialValue: _fromMemberId,
                  items: members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                  onChanged: (value) {
                    setState(() {
                      _fromMemberId = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'From (who pays)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _toMemberId,
                  items: members
                      .where((m) => m.id != _fromMemberId)
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _toMemberId = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'To (who receives)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixText: 'Tk ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('Payment Method'),
                RadioListTile<PaymentMethod>(
                  title: const Text('Cash'),
                  value: PaymentMethod.cash,
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value ?? PaymentMethod.cash;
                    });
                  },
                ),
                RadioListTile<PaymentMethod>(
                  title: const Text('bKash'),
                  value: PaymentMethod.bkash,
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value ?? PaymentMethod.bkash;
                    });
                  },
                ),
                RadioListTile<PaymentMethod>(
                  title: const Text('Bank Transfer'),
                  value: PaymentMethod.bankTransfer,
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value ?? PaymentMethod.bankTransfer;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _settleUp,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Record Settlement'),
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

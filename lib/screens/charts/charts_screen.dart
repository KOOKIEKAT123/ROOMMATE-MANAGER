import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/expense_service.dart';
import '../../services/household_service.dart';
import '../../models/expense.dart';
import '../../models/member.dart';

class ChartsScreen extends StatefulWidget {
  final String householdId;

  const ChartsScreen({super.key, required this.householdId});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  _Range _range = _Range.monthly;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day);
    _startDate = DateTime(now.year, now.month, 1);
  }

  void _setRange(_Range range) {
    final now = DateTime.now();
    setState(() {
      _range = range;
      switch (range) {
        case _Range.weekly:
          _endDate = DateTime(now.year, now.month, now.day);
          _startDate = _endDate.subtract(const Duration(days: 6));
          break;
        case _Range.monthly:
          _endDate = DateTime(now.year, now.month, now.day);
          _startDate = DateTime(now.year, now.month, 1);
          break;
        case _Range.custom:
          // keep current custom dates
          break;
      }
    });
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (date != null) {
      setState(() {
        _range = _Range.custom;
        _startDate = date;
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _range = _Range.custom;
        _endDate = date;
        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseService = context.read<ExpenseService>();
    final householdService = context.read<HouseholdService>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.18),
            Theme.of(context).colorScheme.surface.withOpacity(0.6),
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.18),
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
          title: const Text('Charts & Analytics'),
        ),
        body: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _glowBlob(
                140,
                Theme.of(context).colorScheme.primary.withOpacity(0.12),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: _glowBlob(
                120,
                Theme.of(context).colorScheme.secondary.withOpacity(0.12),
              ),
            ),
            StreamBuilder<List<Expense>>(
              stream: expenseService.getExpensesByDateRange(
                widget.householdId,
                _startDate,
                _endDate,
              ),
              builder: (context, expenseSnapshot) {
                if (expenseSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!expenseSnapshot.hasData || expenseSnapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No expenses in this period'),
                  );
                }

                return StreamBuilder<List<Member>>(
                  stream: householdService.getHouseholdMembers(
                    widget.householdId,
                  ),
                  builder: (context, memberSnapshot) {
                    if (memberSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final expenses = expenseSnapshot.data ?? [];
                    final members = memberSnapshot.data ?? [];
                    final memberMap = {for (var m in members) m.id: m.name};

                    // Calculate expenses by category
                    final categoryTotals = <String, double>{};
                    for (var expense in expenses) {
                      for (var category in expense.category) {
                        categoryTotals[category] =
                            (categoryTotals[category] ?? 0) + expense.amount;
                      }
                    }

                    // Calculate expenses by member (who paid)
                    final memberTotals = <String, double>{};
                    for (var expense in expenses) {
                      memberTotals[expense.payerId] =
                          (memberTotals[expense.payerId] ?? 0) + expense.amount;
                    }

                    final totalExpense = categoryTotals.values.fold<double>(
                      0,
                      (prev, curr) => prev + curr,
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              ToggleButtons(
                                isSelected: [
                                  _range == _Range.weekly,
                                  _range == _Range.monthly,
                                  _range == _Range.custom,
                                ],
                                onPressed: (index) {
                                  if (index == 0) _setRange(_Range.weekly);
                                  if (index == 1) _setRange(_Range.monthly);
                                  if (index == 2) _setRange(_Range.custom);
                                },
                                borderRadius: BorderRadius.circular(12),
                                constraints: const BoxConstraints(
                                  minHeight: 40,
                                  minWidth: 88,
                                ),
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text('Weekly'),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text('Monthly'),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text('Custom'),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: _range == _Range.custom
                                    ? _pickStartDate
                                    : null,
                                child: Text(
                                  DateFormat('MM/dd/yyyy').format(_startDate),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _range == _Range.custom
                                    ? _pickEndDate
                                    : null,
                                child: Text(
                                  DateFormat('MM/dd/yyyy').format(_endDate),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Expenses by Category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 240,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 36,
                                sectionsSpace: 2,
                                sections: categoryTotals.entries
                                    .map(
                                      (e) => PieChartSectionData(
                                        value: e.value,
                                        title: '',
                                        radius: 90,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Total by Category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: categoryTotals.entries.map((e) {
                              final percentage = (e.value / totalExpense * 100)
                                  .toStringAsFixed(1);
                              return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 140,
                                  maxWidth: 220,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.key,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tk ${e.value.toStringAsFixed(2)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '$percentage%',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Total Expenses by Member',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: memberTotals.entries.map((e) {
                              final memberName = memberMap[e.key] ?? 'Unknown';
                              return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 140,
                                  maxWidth: 220,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        memberName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tk ${e.value.toStringAsFixed(2)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
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
}

enum _Range { weekly, monthly, custom }

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

  const ChartsScreen({Key? key, required this.householdId}) : super(key: key);

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day);
    _startDate = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final expenseService = context.read<ExpenseService>();
    final householdService = context.read<HouseholdService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charts & Analytics'),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.getExpensesByDateRange(
          widget.householdId,
          _startDate,
          _endDate,
        ),
        builder: (context, expenseSnapshot) {
          if (expenseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!expenseSnapshot.hasData || expenseSnapshot.data!.isEmpty) {
            return const Center(
              child: Text('No expenses in this period'),
            );
          }

          return StreamBuilder<List<Member>>(
            stream: householdService.getHouseholdMembers(widget.householdId),
            builder: (context, memberSnapshot) {
              if (memberSnapshot.connectionState == ConnectionState.waiting) {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                              });
                            }
                          },
                          child: Text(DateFormat('MM/dd/yyyy').format(_startDate)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                          child: Text(DateFormat('MM/dd/yyyy').format(_endDate)),
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
                      height: 300,
                      child: PieChart(
                        PieChartData(
                          sections: categoryTotals.entries
                              .map((e) => PieChartSectionData(
                                    value: e.value,
                                    title: e.key,
                                    radius: 100,
                                  ))
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
                    ...categoryTotals.entries.map((e) {
                      final percentage =
                          (e.value / totalExpense * 100).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${e.value.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$percentage%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                    const Text(
                      'Total Expenses by Member',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...memberTotals.entries.map((e) {
                      final memberName = memberMap[e.key] ?? 'Unknown';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(memberName),
                            Text(
                              '\$${e.value.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

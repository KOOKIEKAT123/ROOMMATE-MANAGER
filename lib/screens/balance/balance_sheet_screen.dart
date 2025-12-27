import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/expense_service.dart';
import '../../services/household_service.dart';
import '../../models/member.dart';
import 'settle_up_screen.dart';

class BalanceSheetScreen extends StatelessWidget {
  final String householdId;

  const BalanceSheetScreen({super.key, required this.householdId});

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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettleUpScreen(householdId: householdId),
              ),
            );
          },
          icon: const Icon(Icons.payment),
          label: const Text('Settle Up'),
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
                Theme.of(context).colorScheme.tertiary.withOpacity(0.12),
              ),
            ),
            FutureBuilder<Map<String, double>>(
              future: expenseService.calculateBalances(householdId),
              builder: (context, balanceSnapshot) {
                if (balanceSnapshot.connectionState ==
                    ConnectionState.waiting) {
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
                          'Calculating balances...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                if (!balanceSnapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load balances',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  );
                }

                return StreamBuilder<List<Member>>(
                  stream: householdService.getHouseholdMembers(householdId),
                  builder: (context, memberSnapshot) {
                    if (memberSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    }

                    final members = memberSnapshot.data ?? [];
                    final balances = balanceSnapshot.data ?? {};
                    final memberMap = {for (var m in members) m.id: m};

                    // Sort members by balance (owe most to least)
                    final sortedEntries = balances.entries.toList()
                      ..sort((a, b) => a.value.compareTo(b.value));

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balance Summary',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          ...sortedEntries.map((entry) {
                            final member = memberMap[entry.key];
                            final balance = entry.value;

                            if (balance.abs() < 0.01) {
                              return const SizedBox.shrink();
                            }

                            final isOwing = balance < 0;
                            final badgeColor = isOwing
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer;
                            final badgeTextColor = isOwing
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.secondary;

                            return StatefulBuilder(
                              builder: (context, setState) {
                                bool isHovered = false;
                                return MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => isHovered = true),
                                  onExit: (_) =>
                                      setState(() => isHovered = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      gradient: isHovered
                                          ? LinearGradient(
                                              colors: [
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.12),
                                                Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: !isHovered
                                          ? Theme.of(context)
                                                .colorScheme
                                                .surface
                                                .withOpacity(0.92)
                                          : null,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isHovered
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.5)
                                            : Theme.of(
                                                context,
                                              ).colorScheme.outlineVariant,
                                        width: isHovered ? 2 : 1,
                                      ),
                                      boxShadow: isHovered
                                          ? [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.22),
                                                blurRadius: 14,
                                                offset: const Offset(0, 6),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .shadow
                                                    .withOpacity(0.06),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            width: 6,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                      16,
                                                    ),
                                                    bottomLeft: Radius.circular(
                                                      16,
                                                    ),
                                                  ),
                                              gradient: LinearGradient(
                                                colors: [
                                                  isOwing
                                                      ? Theme.of(
                                                          context,
                                                        ).colorScheme.error
                                                      : Theme.of(
                                                          context,
                                                        ).colorScheme.tertiary,
                                                  isOwing
                                                      ? Theme.of(context)
                                                            .colorScheme
                                                            .error
                                                            .withOpacity(0.6)
                                                      : Theme.of(
                                                          context,
                                                        ).colorScheme.secondary,
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      (isOwing
                                                              ? Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .error
                                                              : Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .tertiary)
                                                          .withOpacity(
                                                            isHovered
                                                                ? 0.28
                                                                : 0.12,
                                                          ),
                                                  blurRadius: isHovered
                                                      ? 18
                                                      : 10,
                                                  offset: const Offset(1, 0),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            splashColor: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.08),
                                            highlightColor: Colors.transparent,
                                            onTap: () {},
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          member?.name ??
                                                              'Unknown',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .titleMedium
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          isOwing
                                                              ? 'Owes the group'
                                                              : 'Owed by the group',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .labelSmall,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: badgeColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      isOwing
                                                          ? 'Tk ${balance.toStringAsFixed(2)}'
                                                          : 'Tk ${(-balance).toStringAsFixed(2)}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                            color:
                                                                badgeTextColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
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

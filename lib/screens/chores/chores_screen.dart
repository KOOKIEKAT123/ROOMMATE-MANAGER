import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/chore_service.dart';
import '../../services/household_service.dart';
import '../../models/chore.dart';
import '../../models/member.dart';
import 'add_chore_screen.dart';

// Status buckets for summary and badges
enum _ChoreStatus { overdue, incoming, onTrack, done }

// ignore_for_file: prefer_if_elements_to_conditional_expressions, dead_code

class ChoresScreen extends StatelessWidget {
  final String householdId;

  const ChoresScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context) {
    final choreService = context.read<ChoreService>();
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
        floatingActionButton: _buildAnimatedFAB(),
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
            StreamBuilder<List<Chore>>(
              stream: choreService.getHouseholdChores(householdId),
              builder: (context, choreSnapshot) {
                if (choreSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 16),
                        Text('Loading chores...', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }

                if (!choreSnapshot.hasData || choreSnapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(Icons.cleaning_services, size: 64, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No chores yet',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Tap + to add your first chore', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }

                return StreamBuilder<List<Member>>(
                  stream: householdService.getHouseholdMembers(householdId),
                  builder: (context, memberSnapshot) {
                    if (memberSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                        ),
                      );
                    }

                    final members = memberSnapshot.data ?? [];
                    final memberMap = {for (var m in members) m.id: m.name};

                    // Summary counters
                    final chores = choreSnapshot.data!;
                    final now = DateTime.now();
                    int pending = 0;
                    int overdue = 0;
                    int incoming = 0;
                    for (final c in chores) {
                      if (c.completed) continue;
                      pending++;
                      final status = _choreStatus(c, now);
                      if (status == _ChoreStatus.overdue) overdue++;
                      if (status == _ChoreStatus.incoming) incoming++;
                    }

                    final colorScheme = Theme.of(context).colorScheme;
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final pendingColor = isDark
                        ? colorScheme.surfaceContainerHighest.withOpacity(0.6)
                        : colorScheme.secondaryContainer;
                    final overdueColor = isDark
                        ? colorScheme.errorContainer.withOpacity(0.35)
                        : colorScheme.errorContainer;
                    final incomingColor = isDark
                        ? colorScheme.primaryContainer.withOpacity(0.4)
                        : colorScheme.primaryContainer;

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: chores.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: 1),
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: 0.9 + (0.1 * value),
                                          child: Opacity(opacity: value, child: child),
                                        );
                                      },
                                      child: _summaryTile(
                                        context,
                                        'Pending',
                                        pending.toString(),
                                        pendingColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: 1),
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: 0.9 + (0.1 * value),
                                          child: Opacity(opacity: value, child: child),
                                        );
                                      },
                                      child: _summaryTile(
                                        context,
                                        'Overdue',
                                        overdue.toString(),
                                        overdueColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: 1),
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: 0.9 + (0.1 * value),
                                          child: Opacity(opacity: value, child: child),
                                        );
                                      },
                                      child: _summaryTile(
                                        context,
                                        'Incoming',
                                        incoming.toString(),
                                        incomingColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Chore Flow',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }

                        final chore = chores[index - 1];
                        final assigneeName = memberMap[chore.assignedTo] ?? 'Unknown';
                        final status = _choreStatus(chore, DateTime.now());

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: _buildChoreCard(context, chore, assigneeName, householdId, status),
                        );
                      },
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

  Widget _buildChoreCard(BuildContext context, Chore chore, String assigneeName, String householdId, _ChoreStatus status) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: isHovered
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.12),
                        Theme.of(context).colorScheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.92)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                    : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
                width: isHovered ? 2 : 1,
              ),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.06),
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
                    duration: const Duration(milliseconds: 220),
                    width: 6,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(isHovered ? 0.28 : 0.12),
                          blurRadius: isHovered ? 18 : 10,
                          offset: const Offset(1, 0),
                        ),
                      ],
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    highlightColor: Colors.transparent,
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          AnimatedScale(
                            scale: isHovered ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Checkbox(
                              value: chore.completed,
                              onChanged: (value) {
                                if (value == true) {
                                  context.read<ChoreService>().markChoreCompleted(householdId, chore.id);
                                } else {
                                  context.read<ChoreService>().markChoreIncomplete(householdId, chore.id);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chore.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        decoration: chore.completed ? TextDecoration.lineThrough : TextDecoration.none,
                                        color: chore.completed ? Theme.of(context).colorScheme.outline : null,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Assigned to $assigneeName • ${chore.frequency.toString().split('.').last}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).textTheme.labelSmall?.color?.withOpacity(0.7),
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _statusBadge(context, status, isHovered, chore),
                          const SizedBox(width: 8),
                          PopupMenuButton(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 8),
                                    const Text('Edit'),
                                  ],
                                ),
                                onTap: () {
                                  // Edit functionality
                                },
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Theme.of(context).colorScheme.error, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Delete'),
                                  ],
                                ),
                                onTap: () {
                                  context.read<ChoreService>().deleteChore(householdId, chore.id);
                                },
                              ),
                            ],
                            icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.outline, size: 20),
                            padding: EdgeInsets.zero,
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
  }

  Widget _buildAnimatedFAB() {
    return Builder(
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            elevation: 0,
            highlightElevation: 8,
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => AddChoreScreen(householdId: householdId),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Chore'),
          ),
        );
      },
    );
  }

  DateTime _computeDueDate(Chore c) {
    final base = c.lastCompletedAt ?? c.createdAt;
    final interval = c.frequency == ChoreFrequency.daily
        ? const Duration(days: 1)
        : const Duration(days: 7);
    return base.add(interval);
  }

  _ChoreStatus _choreStatus(Chore c, DateTime now) {
    if (c.completed) return _ChoreStatus.done;
    final due = _computeDueDate(c);
    if (now.isAfter(due)) return _ChoreStatus.overdue;
    if (now.isAfter(due.subtract(const Duration(days: 3)))) return _ChoreStatus.incoming;
    return _ChoreStatus.onTrack;
  }

  Widget _statusBadge(BuildContext context, _ChoreStatus status, bool isHovered, Chore chore) {
    String label;
    Color bg;
    Color fg;

    switch (status) {
      case _ChoreStatus.overdue:
        label = 'Overdue';
        bg = isHovered
            ? Theme.of(context).colorScheme.error.withOpacity(0.2)
            : Theme.of(context).colorScheme.errorContainer;
        fg = Theme.of(context).colorScheme.error;
        break;
      case _ChoreStatus.incoming:
        label = 'Due soon';
        bg = isHovered
            ? Theme.of(context).colorScheme.tertiary.withOpacity(0.15)
            : Theme.of(context).colorScheme.tertiaryContainer;
        fg = Theme.of(context).colorScheme.tertiary;
        break;
      case _ChoreStatus.done:
        label = 'Done';
        bg = Theme.of(context).colorScheme.primaryContainer;
        fg = Theme.of(context).colorScheme.primary;
        break;
      case _ChoreStatus.onTrack:
        label = 'On track';
        bg = Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3);
        fg = Theme.of(context).colorScheme.onSurface;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _summaryTile(BuildContext context, String title, String value, Color bg) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1, end: 1),
      duration: const Duration(seconds: 6),
      curve: Curves.easeInOutSine,
      builder: (context, shimmer, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bg,
                Color.lerp(bg, Theme.of(context).colorScheme.primary.withOpacity(0.1), 0.6)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment(shimmer, -1),
                  child: Transform.rotate(
                    angle: -0.6,
                    child: Container(
                      width: 90,
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.labelSmall?.color?.withOpacity(0.8),
                ),
            textAlign: TextAlign.center,
          ),
        ],
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

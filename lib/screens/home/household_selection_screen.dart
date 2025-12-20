import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/household_service.dart';
import '../../models/household.dart';
import 'home_screen.dart';
import 'create_household_screen.dart';

// ignore_for_file: prefer_if_elements_to_conditional_expressions, dead_code

class HouseholdSelectionScreen extends StatefulWidget {
  const HouseholdSelectionScreen({super.key});

  @override
  State<HouseholdSelectionScreen> createState() => _HouseholdSelectionScreenState();
}

class _HouseholdSelectionScreenState extends State<HouseholdSelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  final Map<int, bool> _hoverStates = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmationDialog(BuildContext context, Household household, HouseholdService householdService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AnimatedBuilder(
        animation: Tween<double>(
          begin: 0,
          end: 1,
        ).animate(CurvedAnimation(parent: ModalRoute.of(context)!.animation!, curve: Curves.easeOutCubic)),
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * (ModalRoute.of(context)!.animation?.value ?? 0)),
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Delete Household'),
              content: Text('Are you sure you want to delete "${household.name}"? This action cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    try {
                      await householdService.deleteHousehold(household.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${household.name} deleted'),
                            backgroundColor: Colors.red.shade400,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error deleting household: $e')));
                      }
                    }
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final householdService = context.read<HouseholdService>();
    final userId = authService.getCurrentUser()?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Households'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Tooltip(
              message: 'Sign out',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    try {
                      await authService.signOut();
                      if (context.mounted) {
                        while (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out error: $e')));
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Household>>(
        stream: householdService.getUserHouseholds(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                      ),
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading your households...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return FadeTransition(
              opacity: _fadeController,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context).colorScheme.secondaryContainer,
                            ],
                          ),
                        ),
                        child: Icon(Icons.home_outlined, size: 60, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No households yet',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create your first household to start\nmanaging expenses and chores',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildAnimatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const CreateHouseholdScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                            ),
                          );
                        },
                        label: 'Create Household',
                        icon: Icons.add,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeController,
            child: ListView.builder(
              itemCount: snapshot.data!.length,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemBuilder: (context, index) {
                final household = snapshot.data![index];
                return _buildHouseholdCard(context, household, householdService, index);
              },
            ),
          );
        },
      ),
      floatingActionButton: _buildAnimatedFAB(
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const CreateHouseholdScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHouseholdCard(BuildContext context, Household household, HouseholdService householdService, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: MouseRegion(
          onEnter: (_) {
            setState(() {
              _hoverStates[index] = true;
            });
          },
          onExit: (_) {
            setState(() {
              _hoverStates[index] = false;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: _hoverStates[index] == true
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(householdId: household.id),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.home, size: 30, color: Theme.of(context).colorScheme.onPrimary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              household.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${household.memberIds.length} member${household.memberIds.length != 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new, size: 20, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 12),
                                const Text('Open'),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      HomeScreen(householdId: household.id),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                ),
                              );
                            },
                          ),
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                const SizedBox(width: 12),
                                const Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                            onTap: () {
                              _showDeleteConfirmationDialog(context, household, householdService);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _hoverStates[index] == true ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({required VoidCallback onPressed, required String label, required IconData icon}) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedFAB({required VoidCallback onPressed}) {
    return Builder(
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: onPressed,
            elevation: 0,
            highlightElevation: 8,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

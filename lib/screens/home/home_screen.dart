import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/household_service.dart';
import '../../models/household.dart';
import '../expenses/expenses_screen.dart';
import '../chores/chores_screen.dart';
// Balance screen is now merged into Expenses; Alerts has its own tab
import '../members/members_screen.dart';
import '../charts/charts_screen.dart';
import '../alerts/alerts_screen.dart';
import '../chat/chat_screen.dart';
import '../../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  final String householdId;

  const HomeScreen({super.key, required this.householdId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final householdService = context.read<HouseholdService>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return FutureBuilder<Household?>(
      future: householdService.getHousehold(widget.householdId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 16),
                  Text('Loading household...', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Household not found', style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          );
        }

        final household = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  household.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text('Household', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Tooltip(
                    message: isDarkMode ? 'Light mode' : 'Dark mode',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, key: ValueKey(isDarkMode)),
                        ),
                        onPressed: () {
                          context.read<ThemeProvider>().toggleTheme();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Tooltip(
                    message: 'Sign out',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          // Show confirmation dialog
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: const Text('Sign Out'),
                              content: const Text('Are you sure you want to sign out?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Sign Out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && context.mounted) {
                            try {
                              await context.read<AuthService>().signOut();
                              if (context.mounted) {
                                while (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text('Sign out error: $e')));
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              MembersScreen(householdId: widget.householdId),
              ExpensesScreen(householdId: widget.householdId),
              ChoresScreen(householdId: widget.householdId),
              ChatScreen(householdId: widget.householdId),
              AlertsScreen(householdId: widget.householdId),
              ChartsScreen(householdId: widget.householdId),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(int.parse((0.1 * 255).toStringAsFixed(0))),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.people, 0),
                  activeIcon: _buildNavIconActive(Icons.people, 0),
                  label: 'Members',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.receipt, 1),
                  activeIcon: _buildNavIconActive(Icons.receipt, 1),
                  label: 'Expenses',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.checklist, 2),
                  activeIcon: _buildNavIconActive(Icons.checklist, 2),
                  label: 'Chores',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.chat_bubble, 3),
                  activeIcon: _buildNavIconActive(Icons.chat_bubble, 3),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.notifications, 4),
                  activeIcon: _buildNavIconActive(Icons.notifications, 4),
                  label: 'Alerts',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.pie_chart, 5),
                  activeIcon: _buildNavIconActive(Icons.pie_chart, 5),
                  label: 'Charts',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    return AnimatedContainer(duration: const Duration(milliseconds: 300), child: Icon(icon));
  }

  Widget _buildNavIconActive(IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon),
    );
  }
}

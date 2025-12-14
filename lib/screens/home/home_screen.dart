import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/household_service.dart';
import '../../models/household.dart';
import '../expenses/expenses_screen.dart';
import '../chores/chores_screen.dart';
import '../balance/balance_sheet_screen.dart';
import '../members/members_screen.dart';
import '../charts/charts_screen.dart';

class HomeScreen extends StatefulWidget {
  final String householdId;
  
  const HomeScreen({Key? key, required this.householdId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final householdService = context.read<HouseholdService>();

    return FutureBuilder<Household?>(
      future: householdService.getHousehold(widget.householdId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Household not found')),
          );
        }

        final household = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(household.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  try {
                    await context.read<AuthService>().signOut();
                    print('DEBUG: Sign out completed from HomeScreen');
                    if (context.mounted) {
                      print('DEBUG: Context mounted, clearing navigation stack');
                      // Clear all routes and go back to the root
                      while (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    }
                  } catch (e) {
                    print('DEBUG: Error during sign out from HomeScreen: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign out error: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              MembersScreen(householdId: widget.householdId),
              ExpensesScreen(householdId: widget.householdId),
              BalanceSheetScreen(householdId: widget.householdId),
              ChoresScreen(householdId: widget.householdId),
              ChartsScreen(householdId: widget.householdId),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Members',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt),
                label: 'Expenses',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.balance),
                label: 'Balance',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.checklist),
                label: 'Chores',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart),
                label: 'Charts',
              ),
            ],
          ),
        );
      },
    );
  }
}

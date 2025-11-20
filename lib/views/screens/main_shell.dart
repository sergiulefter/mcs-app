import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../controllers/navigation_controller.dart';
import 'home_screen.dart';
import 'doctors_screen.dart';
import 'consultations_screen.dart';
import 'account_screen.dart';

/// Main navigation shell for Patient user type
/// Contains bottom navigation with 4 tabs: Home, Doctors, Consultations, Account
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // List of screens - using IndexedStack to preserve state
  final List<Widget> _screens = const [
    HomeScreen(),
    DoctorsScreen(),
    ConsultationsScreen(),
    AccountScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Depend on locale so nav labels update immediately when language changes
    final locale = context.locale;

    return NavigationController(
      currentIndex: _currentIndex,
      onTabChange: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          key: ValueKey(locale.languageCode),
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: 'navigation.home'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_outlined),
              activeIcon: const Icon(Icons.search),
              label: 'navigation.doctors'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_outlined),
              activeIcon: const Icon(Icons.assignment),
              label: 'navigation.consultations'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outlined),
              activeIcon: const Icon(Icons.person),
              label: 'navigation.account'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/navigation_controller.dart';
import 'home_screen.dart';
import 'doctors_screen.dart';
import 'consultations_screen.dart';
import 'account_screen.dart';

/// Main navigation shell for Patient user type
/// Contains bottom navigation with 4 tabs: Home, Doctors, Consultations, Account
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int? _currentIndex;
  Set<int>? _visitedTabs;

  int get currentIndex => _currentIndex ??= widget.initialIndex.clamp(0, 3);
  Set<int> get visitedTabs => _visitedTabs ??= {currentIndex};

  // Build screen only when first visited, then cached by IndexedStack
  Widget _buildScreen(int index) {
    if (!visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const DoctorsScreen();
      case 2:
        return const ConsultationsScreen();
      case 3:
        return const AccountScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      visitedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Depend on locale so nav labels update immediately when language changes
    final locale = context.locale;

    return NavigationController(
      currentIndex: currentIndex,
      onTabChange: (index) {
        setState(() {
          _currentIndex = index;
          visitedTabs.add(index);
        });
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: List.generate(4, _buildScreen),
        ),
        bottomNavigationBar: NavigationBar(
          key: ValueKey(locale.languageCode),
          selectedIndex: currentIndex,
          onDestinationSelected: _onTabTapped,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: 'common.home'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.search_outlined),
              selectedIcon: const Icon(Icons.search),
              label: 'navigation.doctors'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.assignment_outlined),
              selectedIcon: const Icon(Icons.assignment),
              label: 'navigation.consultations'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outlined),
              selectedIcon: const Icon(Icons.person),
              label: 'common.account'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}

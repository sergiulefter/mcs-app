import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/navigation_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
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
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
          ),
          child: BottomNavigationBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            key: ValueKey(locale.languageCode),
            currentIndex: currentIndex,
            onTap: _onTabTapped,
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.home_outlined, false),
                activeIcon: _buildNavIcon(Icons.home, true),
                label: 'common.home'.tr(),
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.search_outlined, false),
                activeIcon: _buildNavIcon(Icons.search, true),
                label: 'navigation.doctors'.tr(),
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.assignment_outlined, false),
                activeIcon: _buildNavIcon(Icons.assignment, true),
                label: 'navigation.consultations'.tr(),
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person_outlined, false),
                activeIcon: _buildNavIcon(Icons.person, true),
                label: 'common.account'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, bool isActive) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing8,
      ),
      decoration: isActive
          ? BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            )
          : null,
      child: Icon(
        icon,
        size: AppTheme.iconMedium,
        color: color,
      ),
    );
  }
}

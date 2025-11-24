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
  late int _currentIndex;

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
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _screens.length - 1);
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
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            key: ValueKey(locale.languageCode),
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.home_outlined, false),
                activeIcon: _buildNavIcon(Icons.home, true),
                label: 'navigation.home'.tr(),
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
                label: 'navigation.account'.tr(),
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
        horizontal: AppTheme.spacing12,
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

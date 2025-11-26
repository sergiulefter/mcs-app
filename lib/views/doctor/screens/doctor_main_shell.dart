import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'doctor_home_screen.dart';
import 'requests_list_screen.dart';
import 'doctor_calendar_screen.dart';
import 'doctor_account_screen.dart';

/// Main navigation shell for Doctor user type
/// Contains bottom navigation with 4 tabs: Home, Requests, Calendar, Account
class DoctorMainShell extends StatefulWidget {
  const DoctorMainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<DoctorMainShell> createState() => _DoctorMainShellState();
}

class _DoctorMainShellState extends State<DoctorMainShell> {
  late int _currentIndex;
  late final DoctorConsultationsController _doctorConsultationsController;

  // List of screens - using IndexedStack to preserve state
  late final List<Widget> _screens;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _doctorConsultationsController = DoctorConsultationsController();
    _screens = [
      const DoctorHomeScreen(),
      ChangeNotifierProvider.value(
        value: _doctorConsultationsController,
        child: const RequestsListScreen(),
      ),
      ChangeNotifierProvider.value(
        value: _doctorConsultationsController,
        child: const DoctorCalendarScreen(),
      ),
      const DoctorAccountScreen(),
    ];
    _currentIndex = widget.initialIndex.clamp(0, _screens.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    // Depend on locale so nav labels update immediately when language changes
    final locale = context.locale;

    return Scaffold(
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
              icon: _buildNavIcon(Icons.dashboard_outlined, false),
              activeIcon: _buildNavIcon(Icons.dashboard, true),
              label: 'doctor.navigation.home'.tr(),
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.assignment_outlined, false),
              activeIcon: _buildNavIcon(Icons.assignment, true),
              label: 'doctor.navigation.requests'.tr(),
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.calendar_month_outlined, false),
              activeIcon: _buildNavIcon(Icons.calendar_month, true),
              label: 'doctor.navigation.calendar'.tr(),
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.person_outlined, false),
              activeIcon: _buildNavIcon(Icons.person, true),
              label: 'doctor.navigation.account'.tr(),
            ),
          ],
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

  @override
  void dispose() {
    _doctorConsultationsController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/controllers/doctor_profile_controller.dart';
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
  late final DoctorProfileController _doctorProfileController;

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
    _doctorProfileController = DoctorProfileController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final doctorId = auth.currentUser?.uid;
      if (doctorId != null) {
        _doctorProfileController.prime(doctorId);
      }
    });
    _screens = [
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: _doctorProfileController,
          ),
          ChangeNotifierProvider.value(
            value: _doctorConsultationsController,
          ),
        ],
        child: const DoctorHomeScreen(),
      ),
      ChangeNotifierProvider.value(
        value: _doctorConsultationsController,
        child: const RequestsListScreen(),
      ),
      ChangeNotifierProvider.value(
        value: _doctorConsultationsController,
        child: const DoctorCalendarScreen(),
      ),
      ChangeNotifierProvider.value(
        value: _doctorProfileController,
        child: const DoctorAccountScreen(),
      ),
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
      bottomNavigationBar: NavigationBar(
        key: ValueKey(locale.languageCode),
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: 'common.home'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: 'doctor.navigation.requests'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: 'doctor.navigation.calendar'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: 'common.account'.tr(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _doctorConsultationsController.dispose();
    _doctorProfileController.dispose();
    super.dispose();
  }
}

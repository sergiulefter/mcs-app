import 'package:flutter/material.dart';

/// NavigationController - InheritedWidget for managing tab navigation in MainShell
///
/// This controller allows child widgets (like HomeScreen) to programmatically
/// switch tabs in the MainShell bottom navigation.
///
/// Usage:
/// ```dart
/// final navController = NavigationController.of(context);
/// navController?.onTabChange(1); // Switch to Doctors tab
/// ```
class NavigationController extends InheritedWidget {
  const NavigationController({
    super.key,
    required this.onTabChange,
    required this.currentIndex,
    required super.child,
  });

  /// Callback to change the current tab index
  final Function(int) onTabChange;

  /// Current active tab index
  final int currentIndex;

  /// Retrieve the nearest NavigationController from the widget tree
  static NavigationController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NavigationController>();
  }

  @override
  bool updateShouldNotify(NavigationController oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

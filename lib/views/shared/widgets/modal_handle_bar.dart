import 'package:flutter/material.dart';

/// A consistent handle bar widget for modal bottom sheets.
///
/// This widget provides a visual indicator that the modal can be
/// dragged up or down. Use this at the top of all modal bottom sheets
/// to ensure consistent styling across the app.
class ModalHandleBar extends StatelessWidget {
  const ModalHandleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

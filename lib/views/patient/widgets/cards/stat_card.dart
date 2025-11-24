import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// A compact stat display card showing an icon, number, and label.
///
/// Used in dashboard-style layouts to show key metrics at a glance.
/// Features subtle gradient background and rounded corners.
///
/// Example:
/// ```dart
/// StatCard(
///   icon: Icons.assignment_outlined,
///   value: '12',
///   label: 'Total Consultations',
///   color: Theme.of(context).colorScheme.primary,
/// )
/// ```
class StatCard extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The numeric value or stat to display.
  final String value;

  /// The label describing the stat.
  final String label;

  /// The accent color for the icon.
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        // Gradient type 1
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            // 1. Top-Left Corner
            color.withValues(alpha: 0.0),
            
            // 2. Center-Top
            color.withValues(alpha: 0.3), 
            
            // 3. Center-Bottom
            color.withValues(alpha: 0.3), 
            
            // 4. Bottom-Right Corner
            color.withValues(alpha: 0.0), 
          ],
          stops: const [0.0, 0.45, 0.55, 1.0], // Controls where the color appears
        ),
        
        // Gradient type 2
        // gradient: LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        //   colors: [
        //     color.withValues(alpha: 0.05),
        //     Theme.of(context).colorScheme.surface, 
        //   ],
        // ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: AppTheme.elevationLow,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              size: AppTheme.iconMedium,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          // Label
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacing8),
          // Value (larger and more prominent)
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

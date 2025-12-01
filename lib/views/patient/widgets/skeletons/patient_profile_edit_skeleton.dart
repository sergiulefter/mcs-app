import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Skeleton loading widget for PatientProfileEditScreen.
/// Shows animated shimmer placeholders while data is loading,
/// matching the actual screen layout.
class PatientProfileEditSkeleton extends StatefulWidget {
  const PatientProfileEditSkeleton({super.key});

  @override
  State<PatientProfileEditSkeleton> createState() =>
      _PatientProfileEditSkeletonState();
}

class _PatientProfileEditSkeletonState extends State<PatientProfileEditSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Read-only section (Account Information)
              _buildReadOnlySectionSkeleton(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Personal info section
              _buildPersonalInfoSkeleton(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Save button
              _buildSaveButtonSkeleton(context),
              const SizedBox(height: AppTheme.spacing16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadOnlySectionSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with info icon
        Row(
          children: [
            _buildShimmerBox(context, width: 20, height: 20),
            const SizedBox(width: AppTheme.spacing8),
            _buildShimmerBox(context, width: 160, height: 20),
          ],
        ),
        const SizedBox(height: AppTheme.spacing4),
        // Hint text
        _buildShimmerBox(context, width: 220, height: 14),
        const SizedBox(height: AppTheme.spacing16),

        // Card with profile details (Email + Member Since)
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _buildProfileDetailRowSkeleton(context),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              _buildProfileDetailRowSkeleton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetailRowSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      child: Row(
        children: [
          _buildShimmerBox(context, width: 20, height: 20),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(context, width: 80, height: 12),
                const SizedBox(height: AppTheme.spacing4),
                _buildShimmerBox(context, width: 150, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildShimmerBox(context, width: 160, height: 20),
        const SizedBox(height: AppTheme.spacing16),

        // Full Name field
        _buildTextFieldSkeleton(context),
        const SizedBox(height: AppTheme.spacing16),

        // Date of Birth field
        _buildTextFieldSkeleton(context),
        const SizedBox(height: AppTheme.spacing16),

        // Sex field
        _buildTextFieldSkeleton(context),
        const SizedBox(height: AppTheme.spacing16),

        // Phone field
        _buildTextFieldSkeleton(context),
      ],
    );
  }

  Widget _buildTextFieldSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        _buildShimmerBox(context, width: 100, height: 14),
        const SizedBox(height: AppTheme.spacing8),
        // Input field
        _buildShimmerBox(
          context,
          width: double.infinity,
          height: 56,
          borderRadius: AppTheme.radiusMedium,
        ),
      ],
    );
  }

  Widget _buildSaveButtonSkeleton(BuildContext context) {
    return _buildShimmerBox(
      context,
      width: double.infinity,
      height: 56,
      borderRadius: AppTheme.radiusMedium,
    );
  }

  Widget _buildShimmerBox(
    BuildContext context, {
    required double width,
    required double height,
    double borderRadius = AppTheme.radiusSmall,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: [
            _clamp(_animation.value - 0.3),
            _clamp(_animation.value),
            _clamp(_animation.value + 0.3),
          ],
        ),
      ),
    );
  }

  double _clamp(double value) {
    return value.clamp(0.0, 1.0);
  }
}

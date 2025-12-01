import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Skeleton loading widget for DoctorProfileEditScreen.
/// Shows animated shimmer placeholders while data is loading,
/// matching the actual screen layout.
class DoctorProfileEditSkeleton extends StatefulWidget {
  const DoctorProfileEditSkeleton({super.key});

  @override
  State<DoctorProfileEditSkeleton> createState() =>
      _DoctorProfileEditSkeletonState();
}

class _DoctorProfileEditSkeletonState extends State<DoctorProfileEditSkeleton>
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
              // Read-only section
              _buildReadOnlySectionSkeleton(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Professional info section
              _buildProfessionalInfoSkeleton(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Education section
              _buildEducationSectionSkeleton(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Subspecialties section
              _buildSubspecialtiesSkeleton(context),
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
            _buildShimmerBox(context, width: 140, height: 20),
          ],
        ),
        const SizedBox(height: AppTheme.spacing4),
        // Hint text
        _buildShimmerBox(context, width: 200, height: 14),
        const SizedBox(height: AppTheme.spacing16),

        // Card with profile details
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
              Divider(height: 1, color: Theme.of(context).dividerColor),
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

  Widget _buildProfessionalInfoSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildShimmerBox(context, width: 180, height: 20),
        const SizedBox(height: AppTheme.spacing16),

        // Bio field
        _buildTextFieldSkeleton(context, height: 100),
        const SizedBox(height: AppTheme.spacing4),
        _buildShimmerBox(context, width: 250, height: 12),
        const SizedBox(height: AppTheme.spacing16),

        // Consultation price field
        _buildTextFieldSkeleton(context),
        const SizedBox(height: AppTheme.spacing16),

        // Experience years field
        _buildTextFieldSkeleton(context),
        const SizedBox(height: AppTheme.spacing16),

        // Languages section
        _buildShimmerBox(context, width: 140, height: 16),
        const SizedBox(height: AppTheme.spacing8),
        _buildChipsSkeleton(context, chipCount: 4),
      ],
    );
  }

  Widget _buildTextFieldSkeleton(BuildContext context, {double height = 56}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        _buildShimmerBox(context, width: 120, height: 14),
        const SizedBox(height: AppTheme.spacing8),
        // Input field
        _buildShimmerBox(
          context,
          width: double.infinity,
          height: height,
          borderRadius: AppTheme.radiusMedium,
        ),
      ],
    );
  }

  Widget _buildEducationSectionSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildShimmerBox(context, width: 100, height: 20),
            _buildShimmerBox(context, width: 120, height: 36),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),

        // Education cards
        _buildEducationCardSkeleton(context),
        const SizedBox(height: AppTheme.spacing12),
        _buildEducationCardSkeleton(context),
      ],
    );
  }

  Widget _buildEducationCardSkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon box
          _buildShimmerBox(context, width: 40, height: 40),
          const SizedBox(width: AppTheme.spacing12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(context, width: 150, height: 16),
                const SizedBox(height: AppTheme.spacing4),
                _buildShimmerBox(context, width: 200, height: 14),
                const SizedBox(height: AppTheme.spacing4),
                _buildShimmerBox(context, width: 50, height: 12),
              ],
            ),
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShimmerBox(context, width: 36, height: 36),
              const SizedBox(width: AppTheme.spacing4),
              _buildShimmerBox(context, width: 36, height: 36),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubspecialtiesSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildShimmerBox(context, width: 130, height: 20),
        const SizedBox(height: AppTheme.spacing16),
        // Chips
        _buildChipsSkeleton(context, chipCount: 6),
      ],
    );
  }

  Widget _buildChipsSkeleton(BuildContext context, {required int chipCount}) {
    return Wrap(
      spacing: AppTheme.spacing8,
      runSpacing: AppTheme.spacing8,
      children: List.generate(
        chipCount,
        (index) => _buildShimmerBox(
          context,
          width: 80 + (index % 3) * 20.0,
          height: 32,
          borderRadius: AppTheme.radiusLarge,
        ),
      ),
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

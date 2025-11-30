import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Skeleton loading widget for RequestDetailScreen.
/// Shows animated shimmer placeholders while data is loading,
/// matching the actual screen layout.
class RequestDetailSkeleton extends StatefulWidget {
  const RequestDetailSkeleton({super.key});

  @override
  State<RequestDetailSkeleton> createState() => _RequestDetailSkeletonState();
}

class _RequestDetailSkeletonState extends State<RequestDetailSkeleton>
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              _buildHeaderSkeleton(context),

              // Content with padding
              Padding(
                padding: AppTheme.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline stepper skeleton
                    _buildTimelineStepperSkeleton(context),
                    const SizedBox(height: AppTheme.sectionSpacing),

                    // Description section skeleton
                    _buildDescriptionSkeleton(context),
                    const SizedBox(height: AppTheme.sectionSpacing),

                    // Additional content placeholder
                    _buildContentSectionSkeleton(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSkeleton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and urgency badges
          Row(
            children: [
              _buildShimmerBox(context, width: 90, height: 24),
              const SizedBox(width: AppTheme.spacing8),
              _buildShimmerBox(context, width: 70, height: 24),
            ],
          ),
          const SizedBox(height: AppTheme.spacing20),

          // Title (two lines)
          _buildShimmerBox(
            context,
            width: MediaQuery.of(context).size.width * 0.7,
            height: 24,
          ),
          const SizedBox(height: AppTheme.spacing8),
          _buildShimmerBox(
            context,
            width: MediaQuery.of(context).size.width * 0.5,
            height: 24,
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Doctor info inline
          Row(
            children: [
              _buildShimmerCircle(context, size: 18),
              const SizedBox(width: AppTheme.spacing8),
              _buildShimmerBox(context, width: 140, height: 16),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Created date
          Row(
            children: [
              _buildShimmerBox(context, width: 16, height: 16),
              const SizedBox(width: AppTheme.spacing8),
              _buildShimmerBox(context, width: 180, height: 14),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStepperSkeleton(BuildContext context) {
    return Row(
      children: [
        // Step 1
        _buildShimmerCircle(context, size: 32),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
            child: _buildShimmerBox(context, width: double.infinity, height: 2),
          ),
        ),
        // Step 2
        _buildShimmerCircle(context, size: 32),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
            child: _buildShimmerBox(context, width: double.infinity, height: 2),
          ),
        ),
        // Step 3
        _buildShimmerCircle(context, size: 32),
      ],
    );
  }

  Widget _buildDescriptionSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildShimmerBox(context, width: 120, height: 18),
        const SizedBox(height: AppTheme.spacing16),

        // Description text lines
        _buildShimmerBox(context, width: double.infinity, height: 14),
        const SizedBox(height: AppTheme.spacing8),
        _buildShimmerBox(context, width: double.infinity, height: 14),
        const SizedBox(height: AppTheme.spacing8),
        _buildShimmerBox(
          context,
          width: MediaQuery.of(context).size.width * 0.7,
          height: 14,
        ),
      ],
    );
  }

  Widget _buildContentSectionSkeleton(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + title row
            Row(
              children: [
                _buildShimmerCircle(context, size: 24),
                const SizedBox(width: AppTheme.spacing12),
                _buildShimmerBox(context, width: 150, height: 18),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Content lines
            _buildShimmerBox(context, width: double.infinity, height: 14),
            const SizedBox(height: AppTheme.spacing8),
            _buildShimmerBox(context, width: double.infinity, height: 14),
            const SizedBox(height: AppTheme.spacing8),
            _buildShimmerBox(
              context,
              width: MediaQuery.of(context).size.width * 0.6,
              height: 14,
            ),
          ],
        ),
      ),
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

  Widget _buildShimmerCircle(BuildContext context, {required double size}) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
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

import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Skeleton loading widget for RequestReviewScreen (doctor UI).
/// Shows animated shimmer placeholders while data is loading,
/// matching the actual screen layout.
class RequestReviewSkeleton extends StatefulWidget {
  const RequestReviewSkeleton({super.key});

  @override
  State<RequestReviewSkeleton> createState() => _RequestReviewSkeletonState();
}

class _RequestReviewSkeletonState extends State<RequestReviewSkeleton>
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
              // Header section
              _buildHeaderSkeleton(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Request details section
              _buildRequestDetailsSkeleton(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Attachments section
              _buildAttachmentsSkeleton(context),
              const SizedBox(height: AppTheme.sectionSpacing),

              // Actions section
              _buildActionsSkeleton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        _buildShimmerBox(
          context,
          width: MediaQuery.of(context).size.width * 0.8,
          height: 24,
        ),
        const SizedBox(height: AppTheme.spacing8),

        // Description lines
        _buildShimmerBox(context, width: double.infinity, height: 16),
        const SizedBox(height: AppTheme.spacing4),
        _buildShimmerBox(
          context,
          width: MediaQuery.of(context).size.width * 0.6,
          height: 16,
        ),
        const SizedBox(height: AppTheme.spacing12),

        // Patient info card skeleton
        _buildPatientInfoCardSkeleton(context),
        const SizedBox(height: AppTheme.spacing12),

        // Date row
        Row(
          children: [
            _buildShimmerBox(context, width: 16, height: 16),
            const SizedBox(width: AppTheme.spacing8),
            _buildShimmerBox(context, width: 150, height: 14),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientInfoCardSkeleton(BuildContext context) {
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
        child: Row(
          children: [
            // Avatar
            _buildShimmerCircle(context, size: 40),
            const SizedBox(width: AppTheme.spacing12),
            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(context, width: 120, height: 16),
                  const SizedBox(height: AppTheme.spacing4),
                  _buildShimmerBox(context, width: 160, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestDetailsSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildShimmerBox(context, width: 140, height: 18),
        const SizedBox(height: AppTheme.spacing8),
        // Subtitle
        _buildShimmerBox(context, width: 200, height: 14),
        const SizedBox(height: AppTheme.spacing12),

        // Detail rows
        _buildDetailRowSkeleton(context),
        const SizedBox(height: AppTheme.spacing8),
        _buildDetailRowSkeleton(context),
        const SizedBox(height: AppTheme.spacing8),
        _buildDetailRowSkeleton(context),
      ],
    );
  }

  Widget _buildDetailRowSkeleton(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildShimmerBox(context, width: double.infinity, height: 14),
        ),
        const SizedBox(width: AppTheme.spacing16),
        _buildShimmerBox(context, width: 80, height: 24),
      ],
    );
  }

  Widget _buildAttachmentsSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildShimmerBox(context, width: 120, height: 18),
        const SizedBox(height: AppTheme.spacing8),
        // Subtitle
        _buildShimmerBox(context, width: 180, height: 14),
        const SizedBox(height: AppTheme.spacing12),

        // Attachment rows
        _buildAttachmentRowSkeleton(context),
        const SizedBox(height: AppTheme.spacing8),
        _buildAttachmentRowSkeleton(context),
      ],
    );
  }

  Widget _buildAttachmentRowSkeleton(BuildContext context) {
    return Row(
      children: [
        _buildShimmerBox(context, width: 24, height: 24),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(context, width: 140, height: 14),
              const SizedBox(height: AppTheme.spacing4),
              _buildShimmerBox(context, width: 100, height: 12),
            ],
          ),
        ),
        _buildShimmerBox(context, width: 16, height: 16),
      ],
    );
  }

  Widget _buildActionsSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildShimmerBox(context, width: 100, height: 18),
        const SizedBox(height: AppTheme.spacing8),
        // Subtitle
        _buildShimmerBox(context, width: 160, height: 14),
        const SizedBox(height: AppTheme.spacing12),

        // Action buttons
        _buildShimmerBox(
          context,
          width: double.infinity,
          height: 48,
          borderRadius: AppTheme.radiusMedium,
        ),
        const SizedBox(height: AppTheme.spacing12),
        _buildShimmerBox(
          context,
          width: double.infinity,
          height: 48,
          borderRadius: AppTheme.radiusMedium,
        ),
      ],
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

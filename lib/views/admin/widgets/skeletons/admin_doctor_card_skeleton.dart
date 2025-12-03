import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Skeleton loading widget matching the AdminDoctorCard layout.
/// Shows animated shimmer placeholders while doctor data is loading.
class AdminDoctorCardSkeleton extends StatefulWidget {
  const AdminDoctorCardSkeleton({super.key});

  @override
  State<AdminDoctorCardSkeleton> createState() =>
      _AdminDoctorCardSkeletonState();
}

class _AdminDoctorCardSkeletonState extends State<AdminDoctorCardSkeleton>
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

    // Delay animation start to allow route transition to complete
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
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            side: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: avatar, name/specialty, availability badge
                Row(
                  children: [
                    // Avatar circle
                    _buildShimmerCircle(context, size: 48),
                    const SizedBox(width: AppTheme.spacing12),
                    // Name and specialty
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(
                            context,
                            width: 140,
                            height: 18,
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          _buildShimmerBox(
                            context,
                            width: 100,
                            height: 14,
                          ),
                        ],
                      ),
                    ),
                    // Availability badge
                    _buildShimmerBox(
                      context,
                      width: 70,
                      height: 24,
                      borderRadius: AppTheme.radiusSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing12),

                // Info row: email and experience
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildShimmerBox(context, width: 16, height: 16),
                          const SizedBox(width: AppTheme.spacing4),
                          Expanded(
                            child: _buildShimmerBox(context, width: double.infinity, height: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Row(
                        children: [
                          _buildShimmerBox(context, width: 16, height: 16),
                          const SizedBox(width: AppTheme.spacing4),
                          Expanded(
                            child: _buildShimmerBox(context, width: double.infinity, height: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: AppTheme.spacing24),

                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildShimmerBox(context, width: 60, height: 32),
                    const SizedBox(width: AppTheme.spacing8),
                    _buildShimmerBox(context, width: 70, height: 32),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

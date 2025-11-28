import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

class ConsultationCardSkeleton extends StatefulWidget {
  const ConsultationCardSkeleton({super.key});

  @override
  State<ConsultationCardSkeleton> createState() =>
      _ConsultationCardSkeletonState();
}

class _ConsultationCardSkeletonState extends State<ConsultationCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
            padding: AppTheme.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row skeleton
                Row(
                  children: [
                    _buildShimmerBox(
                      context,
                      width: 70,
                      height: 24,
                      borderRadius: AppTheme.radiusCircular,
                    ),
                    const Spacer(),
                    _buildShimmerBox(
                      context,
                      width: 50,
                      height: 14,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing12),

                // Title skeleton (2 lines)
                _buildShimmerBox(
                  context,
                  width: double.infinity,
                  height: 18,
                ),
                const SizedBox(height: AppTheme.spacing4),
                _buildShimmerBox(
                  context,
                  width: 200,
                  height: 18,
                ),
                const SizedBox(height: AppTheme.spacing8),

                // Description skeleton (1 line)
                _buildShimmerBox(
                  context,
                  width: double.infinity,
                  height: 14,
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Doctor row skeleton
                Row(
                  children: [
                    _buildShimmerCircle(context, size: 32),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(
                            context,
                            width: 120,
                            height: 14,
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          _buildShimmerBox(
                            context,
                            width: 80,
                            height: 12,
                          ),
                        ],
                      ),
                    ),
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

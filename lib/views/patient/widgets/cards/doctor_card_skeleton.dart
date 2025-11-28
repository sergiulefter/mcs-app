import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

class DoctorCardSkeleton extends StatefulWidget {
  const DoctorCardSkeleton({super.key});

  @override
  State<DoctorCardSkeleton> createState() => _DoctorCardSkeletonState();
}

class _DoctorCardSkeletonState extends State<DoctorCardSkeleton>
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
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Padding(
            padding: AppTheme.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section: Avatar + Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar circle
                    _buildShimmerCircle(context, size: 64),
                    const SizedBox(width: AppTheme.spacing16),

                    // Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + badge
                          Row(
                            children: [
                              Expanded(
                                child: _buildShimmerBox(
                                  context,
                                  width: double.infinity,
                                  height: 18,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              _buildShimmerCircle(context, size: 22),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacing8),

                          // Specialty
                          _buildShimmerBox(
                            context,
                            width: 120,
                            height: 14,
                          ),
                          const SizedBox(height: AppTheme.spacing12),

                          // Experience badge
                          _buildShimmerBox(
                            context,
                            width: 100,
                            height: 24,
                            borderRadius: AppTheme.radiusSmall,
                          ),
                          const SizedBox(height: AppTheme.spacing8),

                          // Education row
                          Row(
                            children: [
                              _buildShimmerBox(
                                context,
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: AppTheme.spacing4),
                              Expanded(
                                child: _buildShimmerBox(
                                  context,
                                  width: double.infinity,
                                  height: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Divider placeholder
                Container(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Bottom row: Availability + Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildShimmerCircle(context, size: 8),
                        const SizedBox(width: AppTheme.spacing8),
                        _buildShimmerBox(
                          context,
                          width: 90,
                          height: 14,
                        ),
                      ],
                    ),
                    _buildShimmerBox(
                      context,
                      width: 100,
                      height: 14,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing12),

                // CTA Button placeholder
                _buildShimmerBox(
                  context,
                  width: double.infinity,
                  height: 44,
                  borderRadius: AppTheme.radiusMedium,
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

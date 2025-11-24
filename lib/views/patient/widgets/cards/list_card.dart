import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'surface_card.dart';

/// A reusable card that stacks children with optional dividers.
class ListCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool showDividers;
  final double dividerIndent;

  const ListCard({
    super.key,
    required this.children,
    this.padding,
    this.showDividers = true,
    this.dividerIndent = AppTheme.spacing16,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: padding,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (showDividers && i != children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor,
                indent: dividerIndent,
                endIndent: dividerIndent,
              ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Consistent card container (puzzle list rows, settings groups, the
/// premium upsell card) — themed border + radius from [CardThemeData],
/// tappable when [onTap] is provided.
///
/// Light mode adds a soft, warm-tinted shadow. Flat bordered rectangles on
/// a cream background is what made light mode read as rigid; a little depth
/// separates cards from the page without turning into heavy Material
/// elevation. Dark mode keeps the flat border, where shadows do nothing.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;
    final shape = cardTheme.shape as RoundedRectangleBorder?;
    final isLight = theme.brightness == Brightness.light;

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardTheme.color,
        borderRadius: shape?.borderRadius as BorderRadius?,
        border: shape?.side != null ? Border.fromBorderSide(shape!.side) : null,
        boxShadow: isLight
            ? const [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape?.borderRadius as BorderRadius?,
        child: content,
      ),
    );
  }
}

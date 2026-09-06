import 'package:flutter/material.dart';

/// Lower-emphasis action button (Restart, Restore Purchases, Skip) —
/// visually distinct from [PrimaryButton] so users always know which
/// action is the "main" one on a screen.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          // Flexible + scale-down: a translated label at a large
          // accessibility text scale is wider than the button, and
          // an unconstrained Text in a Row overflows sideways
          // rather than wrapping. Shrinking keeps the whole label
          // readable; ellipsis would hide what the button does.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, softWrap: false),
            ),
          ),
        ],
      ),
    );
  }
}

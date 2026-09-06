import 'package:flutter/material.dart';

/// The single call-to-action button style used across the app (Continue,
/// Start Puzzle, Purchase, etc.) so tap targets and visual weight stay
/// consistent. Wraps [ElevatedButton] rather than reinventing it — the
/// design system lives in the theme, this just gives it a semantic name
/// and a built-in loading state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
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

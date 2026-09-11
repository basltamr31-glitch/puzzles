import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Installs a global handler that turns uncaught Flutter framework errors
/// into a quiet debug log instead of a red screen / crash in release mode.
///
/// Call once from `main()` before `runApp`. This does not replace local
/// try/catch around expected failures ([AppException]) — it's the safety
/// net for genuinely unexpected errors so the user never sees a stack
/// trace or a frozen app.
void installGlobalErrorHandling() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      originalOnError?.call(details);
    } else {
      debugPrint('Unhandled Flutter error: ${details.exceptionAsString()}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled platform error: $error');
    return true;
  };
}

/// Wraps the app so widget-build errors render a friendly fallback instead
/// of the default red error box, in release builds only.
class AppErrorBoundary extends StatelessWidget {
  const AppErrorBoundary({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) return child;

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return const _FriendlyErrorFallback();
    };
    return child;
  }
}

class _FriendlyErrorFallback extends StatelessWidget {
  const _FriendlyErrorFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFAF7F2),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Something went wrong. Please restart the app.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

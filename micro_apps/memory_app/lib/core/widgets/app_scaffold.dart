import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

/// Standard screen scaffold used by every feature screen so padding,
/// safe-area handling, and app-bar styling stay consistent without each
/// screen reimplementing it. Content is centered with a max width on
/// large screens (tablets, foldables, desktop) so it never stretches
/// into an awkwardly wide single column — this app is phone-first, but
/// shouldn't look broken on anything bigger.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.padHorizontal = true,
    this.bottomBar,
    this.showBackButton = true,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final bool padHorizontal;
  final Widget? bottomBar;
  final bool showBackButton;

  static const double _maxContentWidth = 640;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              actions: actions,
              automaticallyImplyLeading: showBackButton && canPop,
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Padding(
              padding: padHorizontal
                  ? const EdgeInsets.symmetric(horizontal: AppSpacing.xl)
                  : EdgeInsets.zero,
              child: body,
            ),
          ),
        ),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}

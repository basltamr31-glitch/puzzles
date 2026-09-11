import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_config.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';

/// Shows the bundled privacy policy.
///
/// The bundled copy is what the player sees, so the policy is readable
/// with no connection — this app plays offline and its privacy notice
/// should too. [AppConfig.privacyPolicyUrl] is the authoritative,
/// publicly hosted version, reachable from the app bar; if the two ever
/// disagree the hosted one wins, which is why
/// `privacy_policy_test.dart` fails the build if the bundled copy still
/// contains unfilled placeholders once a URL is configured.
///
/// The policy is English-only by decision; a partial or machine
/// translation of a legal document is worse than none.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  /// Also the path published externally, so both come from one source.
  static const String assetPath = 'assets/legal/privacy_policy.md';

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final Future<String> _policy = rootBundle.loadString(
    PrivacyPolicyScreen.assetPath,
  );

  /// Opens the hosted policy in the browser. A failure is reported rather
  /// than swallowed: the bundled text is still on screen behind this, so
  /// the user has lost nothing, but silently doing nothing on a tap reads
  /// as a broken app.
  Future<void> _openHostedPolicy(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(AppConfig.privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.settingsPrivacy,
      padHorizontal: false,
      actions: [
        if (AppConfig.privacyPolicyUrl.isNotEmpty)
          IconButton(
            onPressed: () => _openHostedPolicy(context, l10n),
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: l10n.privacyPolicyViewOnline,
          ),
      ],
      body: FutureBuilder<String>(
        future: _policy,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(message: l10n.errorGeneric);
          }
          final markdown = snapshot.data;
          if (markdown == null) return const LoadingIndicator();

          return Scrollbar(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                // Selectable so a player can copy the contact address out
                // of it — the policy names an address to write to, and a
                // page you cannot copy from makes that pointlessly hard.
                SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _renderPolicy(context, markdown),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Renders the small Markdown subset this document actually uses:
/// `#`/`##`/`###` headings, `-` bullets, and paragraphs.
///
/// A dedicated Markdown package would handle far more syntax than one
/// hand-written document contains, so this stays a local helper rather
/// than a dependency. It is deliberately forgiving: anything it does not
/// recognise is shown as plain text, so an unrenderable line still ends
/// up in front of the reader rather than disappearing.
List<Widget> _renderPolicy(BuildContext context, String markdown) {
  final theme = Theme.of(context);
  final muted = theme.colorScheme.onSurfaceVariant;
  final widgets = <Widget>[];

  // Paragraphs are separated by blank lines; a hard-wrapped paragraph is
  // rejoined so it reflows to the reader's screen width and text size
  // instead of keeping the file's 72-column wrapping.
  for (final block in markdown.split(RegExp(r'\n\s*\n'))) {
    final text = block.trim();
    if (text.isEmpty) continue;

    if (text.startsWith('# ')) {
      widgets
        ..add(const SizedBox(height: AppSpacing.sm))
        ..add(Text(_inline(text.substring(2)), style: theme.textTheme.headlineSmall))
        ..add(const SizedBox(height: AppSpacing.md));
    } else if (text.startsWith('### ')) {
      widgets
        ..add(const SizedBox(height: AppSpacing.md))
        ..add(Text(_inline(text.substring(4)), style: theme.textTheme.titleSmall))
        ..add(const SizedBox(height: AppSpacing.sm));
    } else if (text.startsWith('## ')) {
      widgets
        ..add(const SizedBox(height: AppSpacing.xl))
        ..add(Text(_inline(text.substring(3)), style: theme.textTheme.titleLarge))
        ..add(const SizedBox(height: AppSpacing.sm));
    } else if (text.startsWith('- ')) {
      for (final line in _bulletsOf(text)) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: theme.textTheme.bodyMedium),
                Expanded(
                  child: Text(_inline(line), style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            _inline(text),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: text.startsWith('_') ? muted : null,
            ),
          ),
        ),
      );
    }
  }
  return widgets;
}

/// Splits a bullet block into its items, rejoining continuation lines.
List<String> _bulletsOf(String block) {
  final items = <String>[];
  for (final line in block.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('- ')) {
      items.add(trimmed.substring(2));
    } else if (items.isNotEmpty && trimmed.isNotEmpty) {
      items[items.length - 1] = '${items.last} $trimmed';
    }
  }
  return items;
}

/// Strips the inline markers the document uses. URLs are already written
/// out in full in the text, so nothing is lost by removing the syntax.
String _inline(String text) {
  return text
      .replaceAll('\n', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('**', '')
      .replaceAll(RegExp(r'^_|_$'), '')
      .trim();
}

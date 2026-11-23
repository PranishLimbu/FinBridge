import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../state/session.dart';
import '../theme.dart';

/// "English | नेपाली" toggle. The choice is remembered on the device.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final l10n = context.l10n;
    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        backgroundColor: FbColors.surface,
        foregroundColor: FbColors.primary,
        selectedBackgroundColor: FbColors.primary,
        selectedForegroundColor: Colors.white,
        side: const BorderSide(color: FbColors.border),
        visualDensity: VisualDensity.compact,
      ),
      segments: [
        ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
        ButtonSegment(value: 'ne', label: Text(l10n.languageNepali)),
      ],
      selected: {session.locale.languageCode},
      onSelectionChanged: (s) => session.setLocale(Locale(s.first)),
    );
  }
}

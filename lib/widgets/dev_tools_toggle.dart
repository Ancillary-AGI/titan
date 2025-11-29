import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../core/platform_theme.dart';
import '../core/localization/app_localizations.dart';

class DevToolsToggle extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onToggle;

  const DevToolsToggle({
    super.key,
    required this.isVisible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return IconButton(
      onPressed: onToggle,
      icon: PlatformTheme.isCupertinoPlatform
          ? const Icon(CupertinoIcons.settings)
          : const Icon(Icons.developer_mode),
      tooltip: l10n.devTools,
      color: isVisible ? Theme.of(context).colorScheme.primary : null,
    );
  }
}

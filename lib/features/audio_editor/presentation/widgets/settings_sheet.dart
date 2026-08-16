import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../bloc/settings_cubit.dart';

class SettingsSheet extends StatelessWidget {
  final SettingsCubit cubit;

  const SettingsSheet({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settings, style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            Text(l10n.theme, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _ThemeTile(
              icon: Icons.brightness_auto,
              label: l10n.systemDefault,
              mode: ThemeMode.system,
              groupValue: cubit.state.themeMode,
              onChanged: cubit.setThemeMode,
            ),
            _ThemeTile(
              icon: Icons.light_mode,
              label: l10n.light,
              mode: ThemeMode.light,
              groupValue: cubit.state.themeMode,
              onChanged: cubit.setThemeMode,
            ),
            _ThemeTile(
              icon: Icons.dark_mode,
              label: l10n.dark,
              mode: ThemeMode.dark,
              groupValue: cubit.state.themeMode,
              onChanged: cubit.setThemeMode,
            ),
            const SizedBox(height: 20),
            Text(l10n.language, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _LanguageTile(
              label: 'العربية',
              locale: const Locale('ar'),
              currentLocale: cubit.state.locale,
              onChanged: cubit.setLocale,
            ),
            _LanguageTile(
              label: 'English',
              locale: const Locale('en'),
              currentLocale: cubit.state.locale,
              onChanged: cubit.setLocale,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeMode mode;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.mode,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      secondary: Icon(icon),
      title: Text(label),
      value: mode,
      groupValue: groupValue,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final Locale locale;
  final Locale currentLocale;
  final ValueChanged<Locale> onChanged;

  const _LanguageTile({
    required this.label,
    required this.locale,
    required this.currentLocale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentLocale.languageCode == locale.languageCode;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onTap: () => onChanged(locale),
    );
  }
}

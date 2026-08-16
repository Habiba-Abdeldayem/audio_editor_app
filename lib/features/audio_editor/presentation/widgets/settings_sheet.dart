import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../bloc/settings_cubit.dart';
import '../pages/output_files_page.dart';

class SettingsSheet extends StatelessWidget {
  final SettingsCubit cubit;

  const SettingsSheet({super.key, required this.cubit});

  Future<void> _renameFolder(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: cubit.state.outputFolder);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.renameFolder),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.folderName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.rename),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != cubit.state.outputFolder) {
      await cubit.setOutputFolder(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settings, style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),

              // Output folder
              Text(l10n.outputFolder, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cubit.state.outputFolder,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.outputFolderPath(cubit.state.outputFolder),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: l10n.renameFolder,
                          onPressed: () => _renameFolder(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => OutputFilesPage(),
                          ));
                        },
                        icon: const Icon(Icons.audio_file, size: 18),
                        label: Text(l10n.openOutputFolder),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Theme
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

              // Language
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

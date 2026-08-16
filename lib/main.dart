import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/audio_editor/presentation/bloc/settings_cubit.dart';
import 'features/audio_editor/presentation/pages/audio_editor_page.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();

  // Request storage permissions
  await _requestPermissions();

  runApp(const AudioEditorApp());
}

Future<void> _requestPermissions() async {
  // Request storage permissions for Android
  if (await Permission.storage.request().isDenied) {
    await Permission.storage.request();
  }
  if (await Permission.manageExternalStorage.request().isDenied) {
    await Permission.manageExternalStorage.request();
  }
}

class AudioEditorApp extends StatelessWidget {
  const AudioEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<SettingsCubit>(),
      child: const _AudioEditorMaterialApp(),
    );
  }
}

class _AudioEditorMaterialApp extends StatelessWidget {
  const _AudioEditorMaterialApp();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;

    return MaterialApp(
      title: 'TafsirEditor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AudioEditorPage(),
    );
  }
}

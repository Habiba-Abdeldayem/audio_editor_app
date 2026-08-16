import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Locale locale;
  final String outputFolder;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ar'),
    this.outputFolder = 'TafsirEditor',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? outputFolder,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      outputFolder: outputFolder ?? this.outputFolder,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, outputFolder];
}

class SettingsCubit extends Cubit<SettingsState> {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale_code';
  static const _outputFolderKey = 'output_folder';

  SettingsCubit() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    final localeCode = prefs.getString(_localeKey);
    final outputFolder = prefs.getString(_outputFolderKey) ?? 'TafsirEditor';

    MediaStore.appFolder = outputFolder;

    emit(state.copyWith(
      themeMode: themeIndex != null
          ? ThemeMode.values[themeIndex]
          : ThemeMode.system,
      locale: Locale(localeCode ?? 'ar'),
      outputFolder: outputFolder,
    ));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setLocale(Locale locale) async {
    emit(state.copyWith(locale: locale));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> setOutputFolder(String folderName) async {
    final sanitized = folderName.replaceAll(RegExp(r'[/\\:*?"<>|]'), '').trim();
    if (sanitized.isEmpty) return;
    emit(state.copyWith(outputFolder: sanitized));
    MediaStore.appFolder = sanitized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_outputFolderKey, sanitized);
  }
}

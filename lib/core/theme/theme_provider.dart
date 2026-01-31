/// =====================================================
/// THEME PROVIDER — Dual Theme State Management
/// =====================================================
/// Manages System / Light / Dark theme selection.
/// Persists choice to SharedPreferences.
/// =====================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options
enum AppThemeMode {
  system('Sistem', Icons.brightness_auto),
  light('Açık', Icons.light_mode),
  dark('Koyu', Icons.dark_mode);

  final String label;
  final IconData icon;
  const AppThemeMode(this.label, this.icon);
}

/// Theme state
class ThemeState {
  final AppThemeMode mode;

  const ThemeState({this.mode = AppThemeMode.system});

  ThemeMode get themeMode {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  ThemeState copyWith({AppThemeMode? mode}) {
    return ThemeState(mode: mode ?? this.mode);
  }
}

/// Theme notifier
class ThemeNotifier extends Notifier<ThemeState> {
  static const String _storageKey = 'app_theme_mode';

  @override
  ThemeState build() {
    _loadTheme();
    return const ThemeState();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_storageKey);
      if (modeIndex != null && modeIndex < AppThemeMode.values.length) {
        state = state.copyWith(mode: AppThemeMode.values[modeIndex]);
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(mode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageKey, mode.index);
    } catch (_) {}
  }
}

/// Theme provider
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);

/// Convenience provider for ThemeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode;
});

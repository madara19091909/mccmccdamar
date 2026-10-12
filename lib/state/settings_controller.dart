import 'package:echo/data/repositories/memory_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  static const String themeKey = 'theme_mode';
  static const String lightEffectsKey = 'light_effects';

  final MemoryRepository _repository;

  ThemeMode _themeMode = ThemeMode.dark;
  bool _lightEffects = false;

  ThemeMode get themeMode => _themeMode;

  /// When true the home world is drawn without animation (low-end devices).
  bool get lightEffects => _lightEffects;

  Future<void> load() async {
    try {
      final mode = await _repository.getSetting(themeKey);
      final effects = await _repository.getSetting(lightEffectsKey);
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => ThemeMode.dark,
      );
      _lightEffects = effects == '1';
    } catch (error) {
      debugPrint('ECHO: settings load failed (${error.runtimeType})');
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      await _repository.setSetting(themeKey, mode.name);
    } catch (error) {
      debugPrint('ECHO: settings save failed (${error.runtimeType})');
    }
  }

  Future<void> setLightEffects(bool value) async {
    _lightEffects = value;
    notifyListeners();
    try {
      await _repository.setSetting(lightEffectsKey, value ? '1' : '0');
    } catch (error) {
      debugPrint('ECHO: settings save failed (${error.runtimeType})');
    }
  }
}

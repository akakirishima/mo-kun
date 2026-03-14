import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/app_appearance.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceController extends ChangeNotifier {
  AppearanceController({SharedPreferences? preferences})
    : _preferences = preferences;

  static const storageKey = 'app_appearance_preset';

  SharedPreferences? _preferences;
  AppAppearancePreset _preset = AppAppearancePreset.blossom;

  AppAppearancePreset get preset => _preset;
  AppAppearancePalette get palette => AppAppearancePalette.fromPreset(_preset);

  Future<void> load() async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    final storedPreset = AppAppearancePreset.fromStorageValue(
      preferences.getString(storageKey),
    );
    if (storedPreset == _preset) {
      return;
    }

    _preset = storedPreset;
    notifyListeners();
  }

  Future<void> selectPreset(AppAppearancePreset preset) async {
    if (_preset == preset) {
      return;
    }

    _preset = preset;
    notifyListeners();

    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.setString(storageKey, preset.storageValue);
  }
}

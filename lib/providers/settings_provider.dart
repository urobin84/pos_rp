import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_rp/themes/app_palettes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class SettingsProvider with ChangeNotifier {
  static const _nameKey = 'store_name';
  static const _addressKey = 'store_address';
  static const _phoneKey = 'store_phone';
  static const _websiteKey = 'store_website';
  static const _mottoKey = 'store_motto';
  static const _logoPathKey = 'store_logo_path';
  static const _themePaletteKey = 'theme_palette_name';
  static const _themeModeKey = 'theme_mode';

  String? _name;
  String? _address;
  String? _phone;
  String? _website;
  String? _motto;
  String? _logoPath;
  AppPalette _selectedPalette = appPalettes.first;
  ThemeMode _themeMode = ThemeMode.system;

  String? get name => _name;
  String? get address => _address;
  String? get phone => _phone;
  String? get website => _website;
  String? get motto => _motto;
  String? get logoPath => _logoPath;
  ThemeMode get themeMode => _themeMode;
  Color get themeColor => _selectedPalette.seedColor;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(_nameKey);
    _address = prefs.getString(_addressKey);
    _phone = prefs.getString(_phoneKey);
    _website = prefs.getString(_websiteKey);
    _motto = prefs.getString(_mottoKey);
    _logoPath = prefs.getString(_logoPathKey);
    final paletteName =
        prefs.getString(_themePaletteKey) ?? appPalettes.first.name;
    _selectedPalette = appPalettes.firstWhere(
      (p) => p.name == paletteName,
      orElse: () => appPalettes.first,
    );
    final themeModeIndex =
        prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeModeIndex];
    notifyListeners();
  }

  Future<void> setName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, newName);
    _name = newName;
    notifyListeners();
  }

  Future<void> setAddress(String newAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, newAddress);
    _address = newAddress;
    notifyListeners();
  }

  Future<void> setPhone(String newPhone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, newPhone);
    _phone = newPhone;
    notifyListeners();
  }

  Future<void> setWebsite(String newWebsite) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_websiteKey, newWebsite);
    _website = newWebsite;
    notifyListeners();
  }

  Future<void> setMotto(String newMotto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mottoKey, newMotto);
    _motto = newMotto;
    notifyListeners();
  }

  Future<void> setLogo(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(imageFile.path);
    final savedImage = await imageFile.copy('${appDir.path}/$fileName');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_logoPathKey, savedImage.path);
    _logoPath = savedImage.path;
    notifyListeners();
  }

  Future<void> removeLogo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logoPathKey);
    _logoPath = null;
    notifyListeners();
  }

  Future<void> setThemePalette(AppPalette palette) async {
    _selectedPalette = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePaletteKey, palette.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }
}

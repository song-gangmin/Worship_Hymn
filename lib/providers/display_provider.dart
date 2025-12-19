import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplayProvider with ChangeNotifier {
  static const String _keyShowRecent = 'display_show_recent';
  static const String _keyShowPopular = 'display_show_popular';
  static const String _keyThemeMode = 'display_theme_mode';

  bool _showRecent = true;
  bool _showPopular = true;
  ThemeMode _themeMode = ThemeMode.system;

  DisplayProvider() {
    _loadFromPrefs();
  }

  bool get showRecent => _showRecent;
  bool get showPopular => _showPopular;
  ThemeMode get themeMode => _themeMode;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _showRecent = prefs.getBool(_keyShowRecent) ?? true;
    _showPopular = prefs.getBool(_keyShowPopular) ?? true;
    
    final themeIndex = prefs.getInt(_keyThemeMode) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    
    notifyListeners();
  }

  Future<void> toggleRecent(bool value) async {
    _showRecent = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowRecent, _showRecent);
  }

  Future<void> togglePopular(bool value) async {
    _showPopular = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowPopular, _showPopular);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }
}

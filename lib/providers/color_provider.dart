import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorProvider with ChangeNotifier {
  static const String _keyThemeColor = 'app_theme_color';
  static const Color defaultColor = Color(0xFF673E38);

  Color _primaryColor = defaultColor;

  ColorProvider() {
    _loadFromPrefs();
  }

  Color get primaryColor => _primaryColor;

  final List<Color> availableColors = [
    Colors.pink,
    Colors.red,
    Colors.deepOrange,
    Colors.orange,
    Colors.amber,
    Colors.yellow,
    Colors.lime,
    Colors.lightGreen,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.lightBlue,
    Colors.indigo,
    Colors.deepPurple,
    Colors.purple,
    Colors.brown,
    const Color(0xFF673E38), // 기존 기본색
    Colors.black,
  ];

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final int? colorValue = prefs.getInt(_keyThemeColor);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }
    notifyListeners();
  }

  Future<void> setColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeColor, color.value);
  }
}

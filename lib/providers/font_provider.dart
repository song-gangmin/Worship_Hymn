import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider with ChangeNotifier {
  static const String _keyFontSize = 'font_size_step';
  static const String _keyFontWeight = 'font_weight_step';
  static const String _keyFontFamily = 'font_family';

  // 0 ~ 10 (Default 0)
  int _fontSizeStep = 0;
  // 0 ~ 5 (Default 0)
  int _fontWeightStep = 0;
  
  String _fontFamily = 'Pretendard';

  int get fontSizeStep => _fontSizeStep;
  int get fontWeightStep => _fontWeightStep;
  String get fontFamily => _fontFamily;

  FontProvider() {
    _loadSettings();
  }

  // 글자 크기 배율 (1.0 ~ 1.5)
  double get scaleFactor {
    // step당 0.05 (5%) 씩 증감
    // 0 => 1.0, 10 => 1.5
    return 1.0 + (_fontSizeStep * 0.05);
  }
  
  // 미리보기용 폰트 두께 조절 로직 (0일 때 Regular 기준)
  FontWeight get adjustedDisplayWeight {
     const weights = [
       FontWeight.w100, FontWeight.w200, FontWeight.w300, FontWeight.w400,
       FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800, FontWeight.w900
     ];
     int idx = 3 + _fontWeightStep; // 3 is w400(Regular)
     if (idx > 8) idx = 8;
     return weights[idx];
  }

  /// 특정 스타일의 fontSize에 scaleFactor를 적용한 값을 반환
  double applySize(double distinctSize) {
    return distinctSize * scaleFactor;
  }

  /// 특정 스타일에 대한 변환된 폰트 두께 계산
  FontWeight applyWeight(FontWeight original) {
    if (_fontWeightStep == 0) return original;

    const weights = [
      FontWeight.w100, FontWeight.w200, FontWeight.w300, FontWeight.w400,
      FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800, FontWeight.w900
    ];
    
    int currentIdx = weights.indexOf(original);
    if (currentIdx == -1) currentIdx = 3; // Default w400

    int newIdx = currentIdx + _fontWeightStep;
    if (newIdx > 8) newIdx = 8;
    if (newIdx < 0) newIdx = 0;
    
    return weights[newIdx];
  }

  Future<void> setFontSizeStep(int step) async {
    _fontSizeStep = step;
    notifyListeners();
    _saveSettings();
  }

  Future<void> setFontWeightStep(int step) async {
    _fontWeightStep = step;
    notifyListeners();
    _saveSettings();
  }
  
  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    notifyListeners();
    _saveSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    int size = prefs.getInt(_keyFontSize) ?? 0;
    int weight = prefs.getInt(_keyFontWeight) ?? 0;
    
    // 범위 체크 (0~10, 0~5)
    _fontSizeStep = size.clamp(0, 10);
    _fontWeightStep = weight.clamp(0, 5);
    _fontFamily = prefs.getString(_keyFontFamily) ?? 'Pretendard';
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFontSize, _fontSizeStep);
    await prefs.setInt(_keyFontWeight, _fontWeightStep);
    await prefs.setString(_keyFontFamily, _fontFamily);
  }
}

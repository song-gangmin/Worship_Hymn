import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider with ChangeNotifier {
  static const String _keyFontSize = 'font_size_step';
  static const String _keyFontWeight = 'font_weight_step';
  static const String _keyFontFamily = 'font_family';

  // -5 ~ +5 (Default 0)
  int _fontSizeStep = 0;
  // -2 ~ +2 (Default 0, Regular)
  int _fontWeightStep = 0;
  
  String _fontFamily = 'Pretendard';

  int get fontSizeStep => _fontSizeStep;
  int get fontWeightStep => _fontWeightStep;
  String get fontFamily => _fontFamily;

  FontProvider() {
    _loadSettings();
  }

  // 글자 크기 배율 (0.8 ~ 1.4)
  double get scaleFactor {
    // step당 0.05 (5%) 씩 증감
    // -5 => 0.75, 0 => 1.0, +5 => 1.25
    return 1.0 + (_fontSizeStep * 0.05);
  }
  
  // 폰트 두께 조절 로직
  // step이 0이면 변화 없음.
  // step이 높을수록 기본 두께 자체가 두꺼워짐.
  FontWeight get adjustedDisplayWeight {
     switch (_fontWeightStep) {
       case -2: return FontWeight.w200; // ExtraLight
       case -1: return FontWeight.w300; // Light
       case 0: return FontWeight.w400;  // Regular
       case 1: return FontWeight.w600;  // SemiBold
       case 2: return FontWeight.w700;  // Bold
       default: return FontWeight.w400;
     }
  }

  /// 특정 스타일의 fontSize에 scaleFactor를 적용한 값을 반환
  double applySize(double distinctSize) {
    return distinctSize * scaleFactor;
  }

  /// 특정 스타일에 대한 변환된 폰트 두께 계산
  /// 원래 스타일이 Bold(700)였다면, 설정이 +1일때 ExtraBold(800)가 되어야 함.
  FontWeight applyWeight(FontWeight original) {
    int delta = 0;
    // 매핑 전략: 
    // step -2: 두 단계 얇게
    // step -1: 한 단계 얇게
    // step 0: 그대로
    // step +1: 한 단계 두껍게 (400->600, 600->700)
    // step +2: 두 단계 두껍게
    
    // 단순화: 
    if (_fontWeightStep == 0) return original;

    // Flutter FontWeight values list (100,200,300,400,500,600,700,800,900)
    const weights = [
      FontWeight.w100, FontWeight.w200, FontWeight.w300, FontWeight.w400,
      FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800, FontWeight.w900
    ];
    
    int currentIdx = weights.indexOf(original);
    if (currentIdx == -1) currentIdx = 3; // Default w400

    // step이 +1 (조금 굵게) -> index +1 or +2 (Regular->SemiBold is a good jump)
    // 400(idx3) -> 600(idx5) 가 눈에 띔.
    // 600(idx5) -> 700(idx6)
    
    // 선형적으로 인덱스를 더하자. 
    // -2(-2), -1(-1), 0(0), 1(+1), 2(+2)
    int newIdx = currentIdx + _fontWeightStep;
    
    // 예외처리: Regular(400)에서 +1(굵게)하면 500(Medium)인데, Medium은 차이가 적음. 
    // 400에서 바로 600가고 싶을 수 있음. 하지만 일관성을 위해 일단 선형 이동.
    
    if (newIdx < 0) newIdx = 0;
    if (newIdx > 8) newIdx = 8;
    
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
    _fontSizeStep = prefs.getInt(_keyFontSize) ?? 0;
    _fontWeightStep = prefs.getInt(_keyFontWeight) ?? 0;
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

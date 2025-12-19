import 'package:flutter/material.dart';

class AppColors {
  // 브랜드 기본 색상
  // Primary color is now dynamic via Theme.of(context).primaryColor
  // static const Color primary = Color(0xFF673E38);
  // static const Color primaryText = Color(0xFF673E38);

  // 텍스트용 밝은 색상 (Splash 화면 텍스트 등에 사용)
  static const Color gold = Color(0xFF673E38);

  // 배경 색상
  static Color getBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  // 카드/섹션 배경 색상
  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
  }
}

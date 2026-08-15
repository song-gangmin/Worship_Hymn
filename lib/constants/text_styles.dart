import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:worship_hymn/providers/font_provider.dart';

class AppTextStyles {
  
  // 헬퍼: 컨텍스트를 통해 현재 설정된 폰트 반환
  static FontProvider font(BuildContext context) {
    return Provider.of<FontProvider>(context, listen: true);
  }

  // 제목 (홈 탭 상단 "홈", 섹션 제목 등)
  static TextStyle headline(BuildContext context) {
    final provider = font(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: provider.fontFamily,
      fontSize: provider.applySize(28),
      fontWeight: provider.applyWeight(FontWeight.w600),
      color: isDark ? Colors.white : Colors.black,
    );
  }

  // 중간 제목 (예: '최근 본 찬송가', '이달의 인기 찬송가' 등)
  static TextStyle sectionTitle(BuildContext context) {
    final provider = font(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: provider.fontFamily,
      fontSize: provider.applySize(20),
      fontWeight: provider.applyWeight(FontWeight.w600),
      color: isDark ? Colors.white : Colors.black,
    );
  }

  // 본문 (예: 찬송가 제목, 리스트 항목)
  static TextStyle body(BuildContext context) {
    final provider = font(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: provider.fontFamily,
      fontSize: provider.applySize(16),
      fontWeight: provider.applyWeight(FontWeight.w400),
      color: isDark ? Colors.white : Colors.black,
    );
  }

  // 회색 보조 본문 (예: ‘3번’, ‘가사를 기록’ 등 보조 정보)
  static TextStyle caption(BuildContext context) {
    final provider = font(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: provider.fontFamily,
      fontSize: provider.applySize(14),
      fontWeight: provider.applyWeight(FontWeight.w300),
      color: isDark ? Colors.grey[400] : Colors.grey[600],
    );
  }

  // 버튼 텍스트
  static TextStyle button(BuildContext context) {
    final provider = font(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: provider.fontFamily,
      fontSize: provider.applySize(16),
      fontWeight: provider.applyWeight(FontWeight.w500),
      color: isDark ? Colors.white : Colors.black,
    );
  }

  // 성경 구절 (요 4:24 등)
  static TextStyle verse(BuildContext context) {
    final provider = font(context);
    return TextStyle(
      fontFamily: provider.fontFamily,
      fontSize: provider.applySize(16),
      fontWeight: provider.applyWeight(FontWeight.w500),
      color: Theme.of(context).primaryColor,
      height: 1.5,
    );
  }
  
  static TextStyle basic(BuildContext context) {
    final provider = font(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: provider.fontFamily,
      fontWeight: provider.applyWeight(FontWeight.w400),
      color: isDark ? Colors.white : Colors.black,
    );
  }
}

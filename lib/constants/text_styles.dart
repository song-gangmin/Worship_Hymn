import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/font_provider.dart'; // Ensure correct path
import 'colors.dart';

class AppTextStyles {
  
  // 헬퍼: 컨텍스트를 통해 현재 설정된 폰트 반환
  static FontProvider _font(BuildContext context) {
    return Provider.of<FontProvider>(context, listen: true);
  }

  // 제목 (홈 탭 상단 "홈", 섹션 제목 등)
  static TextStyle headline(BuildContext context) {
    final font = _font(context);
    return TextStyle(
      fontFamily: font.fontFamily,
      fontSize: font.applySize(28),
      fontWeight: font.applyWeight(FontWeight.w600),
      color: Colors.black,
    );
  }

  // 중간 제목 (예: '최근 본 찬송가', '이달의 인기 찬송가' 등)
  static TextStyle sectionTitle(BuildContext context) {
    final font = _font(context);
    return TextStyle(
      fontFamily: font.fontFamily,
      fontSize: font.applySize(20),
      fontWeight: font.applyWeight(FontWeight.w600),
      color: Colors.black,
    );
  }

  // 본문 (예: 찬송가 제목, 리스트 항목)
  static TextStyle body(BuildContext context) {
    final font = _font(context);
    return TextStyle(
      fontFamily: font.fontFamily,
      fontSize: font.applySize(16),
      fontWeight: font.applyWeight(FontWeight.w400),
      color: Colors.black,
    );
  }

  // 회색 보조 본문 (예: ‘3번’, ‘가사를 기록’ 등 보조 정보)
  static TextStyle caption(BuildContext context) {
    final font = _font(context);
    return TextStyle(
      fontFamily: font.fontFamily,
      fontSize: font.applySize(14),
      fontWeight: font.applyWeight(FontWeight.w300),
      color: Colors.grey,
    );
  }

  // 버튼 텍스트
  static TextStyle button(BuildContext context) {
    final font = _font(context);
    return TextStyle(
      fontFamily: font.fontFamily,
      fontSize: font.applySize(16),
      fontWeight: font.applyWeight(FontWeight.w500),
      color: Colors.black,
    );
  }

  // 성경 구절 (요 4:24 등)
  static TextStyle verse(BuildContext context) {
    final font = _font(context);
    return TextStyle(
      fontFamily: font.fontFamily,
      fontSize: font.applySize(14),
      fontWeight: font.applyWeight(FontWeight.w400),
      color: AppColors.primary,
      height: 1.5,
    );
  }
  
  static TextStyle basic(BuildContext context) {
    final font = _font(context);
    return TextStyle(
      fontFamily: font.fontFamily,
      fontWeight: font.applyWeight(FontWeight.w400),
    );
  }
}

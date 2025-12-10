import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  // 제목 (홈 탭 상단 "홈", 섹션 제목 등)
  static const TextStyle headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  // 중간 제목 (예: '최근 본 찬송가', '이달의 인기 찬송가' 등)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  // 본문 (예: 찬송가 제목, 리스트 항목)
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  // 회색 보조 본문 (예: ‘3번’, ‘가사를 기록’ 등 보조 정보)
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: Colors.grey,
  );

  // 버튼 텍스트
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  // 성경 구절 (요 4:24 등)
  static const TextStyle verse = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.primary,
    height: 1.5,
  );
  static const TextStyle basic = TextStyle(
    fontWeight: FontWeight.w400,
  );
}

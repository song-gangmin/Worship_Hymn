/// 한글 초성 검색 유틸리티
///
/// - 초성 추출 (예: "예수님" → "ㅇㅅㄴ")
/// - 부분 문자열 + 초성 매칭 지원
/// - 가사 태그([1절], [후렴] 등) 제거

const List<String> _chosung = [
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

/// 단일 한글 문자의 초성을 반환합니다.
/// 한글이 아닌 문자는 그대로 반환합니다.
String _getChosung(String char) {
  final code = char.codeUnitAt(0);
  // 한글 유니코드 범위: 0xAC00 ~ 0xD7A3
  if (code >= 0xAC00 && code <= 0xD7A3) {
    final index = ((code - 0xAC00) / 588).floor();
    return _chosung[index];
  }
  // 자음 문자 자체인 경우 (ㄱ~ㅎ: 0x3131~0x314E)
  if (code >= 0x3131 && code <= 0x314E) {
    return char;
  }
  return char;
}

/// 문자열의 초성만 추출합니다.
/// 예: "예수님 그리스도" → "ㅇㅅㄴ ㄱㄹㅅㄷ"
String extractChosung(String text) {
  return text.split('').map(_getChosung).join();
}

/// 쿼리가 초성으로만 이루어져 있는지 확인합니다.
bool isChosungOnly(String query) {
  final chosungSet = <String>{
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
    'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  };
  for (final char in query.split('')) {
    if (char == ' ') continue;
    if (!chosungSet.contains(char)) return false;
  }
  return true;
}

/// 대상 텍스트(target)가 검색어(query)와 매칭되는지 확인합니다.
///
/// 매칭 규칙:
/// 1. 일반 부분 문자열 매칭 (공백 제거 후)
///    - "예수", "님그", "리스도" 등 모든 위치 매칭
/// 2. 초성 매칭
///    - 쿼리가 초성으로만 이루어진 경우, 타겟의 초성에서 부분 매칭
///    - 예: "ㅇㅅ" → "예수님"의 초성 "ㅇㅅㄴ"에서 매칭
bool matchesQuery(String target, String query) {
  if (query.isEmpty) return false;

  final normalizedTarget = target.toLowerCase().replaceAll(' ', '');
  final normalizedQuery = query.toLowerCase().replaceAll(' ', '');

  if (normalizedQuery.isEmpty) return false;

  // 1. 일반 부분 문자열 매칭
  if (normalizedTarget.contains(normalizedQuery)) {
    return true;
  }

  // 2. 초성 매칭 (쿼리가 초성으로만 구성된 경우)
  if (isChosungOnly(normalizedQuery)) {
    final targetChosung = extractChosung(normalizedTarget);
    if (targetChosung.contains(normalizedQuery)) {
      return true;
    }
  }

  // 3. 혼합 매칭: 쿼리에 한글+초성이 섞인 경우
  //    타겟의 각 위치에서 쿼리 문자를 하나씩 매칭 시도
  //    예: "님그" → "님"은 직접 매칭, "그"는 직접 매칭
  //    (이미 1번에서 처리됨. 추가로 초성 혼합 매칭 필요 없음)

  return false;
}

/// 일반 텍스트(부분 문자열) 매칭만 수행합니다. (초성 매칭 없음)
/// 가사 검색 시 사용 — 초성 검색은 제목에만 적용하기 위해 분리
bool matchesTextOnly(String target, String query) {
  if (query.isEmpty) return false;

  final normalizedTarget = target.toLowerCase().replaceAll(' ', '');
  final normalizedQuery = query.toLowerCase().replaceAll(' ', '');

  if (normalizedQuery.isEmpty) return false;

  return normalizedTarget.contains(normalizedQuery);
}

/// 가사 텍스트에서 검색 시 제외할 태그를 제거합니다.
/// 제거 대상: [1절], [2절], [3절], [4절], [5절], ..., [후렴]
String cleanLyrics(String lyrics) {
  // [숫자절] 패턴 및 [후렴] 제거
  return lyrics
      .replaceAll(RegExp(r'\[\d+절\]'), '')
      .replaceAll(RegExp(r'\[후렴\]'), '')
      .replaceAll(RegExp(r'\[간주\]'), '')
      .replaceAll(RegExp(r'\[코다\]'), '')
      .trim();
}

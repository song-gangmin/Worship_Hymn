import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/constants/text_styles.dart';
import 'package:worship_hymn/constants/title_hymns.dart'; // HymnInfo, allHymns
import 'package:worship_hymn/screens/score/score_detail_screen.dart';
import 'package:worship_hymn/utils/chosung_util.dart';

class SearchScreen extends StatefulWidget {
  final List<HymnInfo> hymns;

  const SearchScreen({
    super.key,
    required this.hymns,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  /// 찬송가 번호 → 가사 텍스트 캐시
  final Map<int, String> _lyricsCache = {};
  bool _lyricsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAllLyrics();
  }

  /// 모든 찬송가 가사 파일(assets/lyrics/page_N.txt)을 비동기로 로드
  Future<void> _loadAllLyrics() async {
    final futures = <Future<void>>[];
    for (final hymn in widget.hymns) {
      futures.add(
        rootBundle
            .loadString('assets/lyrics/page_${hymn.number}.txt')
            .then((text) {
          _lyricsCache[hymn.number] = text;
        }).catchError((_) {
          // 파일이 없으면 빈 문자열
          _lyricsCache[hymn.number] = '';
        }),
      );
    }
    await Future.wait(futures);
    if (mounted) {
      setState(() {
        _lyricsLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // ✅ 가운데 검색 아이콘만 표시
        title: Text(
          '검색',                              // ✅ 가운데에 "검색" 텍스트
          style: AppTextStyles.headline(context).copyWith(fontSize: 18)
        ),
      ),
      body: Column(
        children: [
          // 🔍 검색바
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: AppTextStyles.body(context).copyWith(fontSize: 16),
              decoration: InputDecoration(
                hintText: '장, 제목, 가사 등',
                hintStyle: AppTextStyles.caption(context),
                filled: true,
                fillColor: AppColors.getSurface(context),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // 📄 리스트 (악보 탭 스타일)
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, child) {
                final query = value.text.trim();

                if (query.isEmpty) {
                  // ✅ 처음엔 완전 빈 화면
                  return const SizedBox.shrink();
                }

                final isChosung = isChosungOnly(query.replaceAll(' ', ''));
                final filtered = widget.hymns.where((h) {
                  final numStr = h.number.toString();

                  // 1. 번호 매칭
                  if (numStr.contains(query)) return true;

                  // 2. 제목 매칭 (초성 포함)
                  if (matchesQuery(h.title, query)) return true;

                  // 3. 가사 매칭 — 초성이면 가사 검색 건너뛰기
                  if (!isChosung && _lyricsLoaded) {
                    final lyrics = _lyricsCache[h.number] ?? '';
                    if (lyrics.isNotEmpty) {
                      final cleaned = cleanLyrics(lyrics);
                      if (matchesTextOnly(cleaned, query)) return true;
                    }
                  }

                  return false;
                }).toList();

                if (filtered.isEmpty) {
                  // ✅ 검색어는 있는데 결과가 없을 때만 안내 문구
                  return const Center(
                    child: Text(
                      '검색 결과가 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Divider(
                      height: 0.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.black12,
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final hymn = filtered[index];
                    return _buildResultRow(hymn);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// score_screen 의 _buildEntry 디자인 그대로
  Widget _buildResultRow(HymnInfo hymn) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScoreDetailScreen(
              hymnNumber: hymn.number,
              hymnTitle: hymn.title,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 13),
        child: Row(
          children: [
            SizedBox(
              width: 40, // ← ScoreScreen과 동일한 숫자 컬럼 너비
              child: Text(
                '${hymn.number}',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()], // 숫자 폭 고정
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hymn.title,
                style: AppTextStyles.body(context).copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

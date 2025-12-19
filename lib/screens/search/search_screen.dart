import 'package:flutter/material.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/constants/text_styles.dart';
import 'package:worship_hymn/constants/title_hymns.dart'; // HymnInfo, allHymns
import 'package:worship_hymn/screens/score/score_detail_screen.dart';

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
  late List<HymnInfo> _filtered;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filtered = []; // ✅ 처음엔 아무 것도 안 보이게
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _controller.text.trim().toLowerCase();
    final qNormalized = q.replaceAll(' ', '');

    setState(() {
      _query = q;
      if (_query.isEmpty) {
        // ✅ 검색어가 없으면 리스트 비우기
        _filtered = [];
      } else {
        _filtered = widget.hymns.where((h) {
          final numStr = h.number.toString();
          final title = h.title.toLowerCase().replaceAll(' ', '');
          final lyrics = h.lyrics.toLowerCase().replaceAll(' ', '');
          return numStr.contains(q) ||
              title.contains(qNormalized) ||
              lyrics.contains(qNormalized);
        }).toList();
      }
    });
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
              decoration: InputDecoration(
                hintText: '장, 제목 등',
                hintStyle: AppTextStyles.caption(context),
                filled: true,
                fillColor: AppColors.getSurface(context),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),

          const SizedBox(height: 4),

          // 📄 리스트 (악보 탭 스타일)
          Expanded(
            child: _query.isEmpty
            // ✅ 처음엔 완전 빈 화면
                ? const SizedBox.shrink()
                : (_filtered.isEmpty
            // ✅ 검색어는 있는데 결과가 없을 때만 안내 문구
                ? const Center(
              child: Text(
                '검색 결과가 없습니다.',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.separated(
              padding:
              const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Divider(
                  height: 0.5,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12,
                ),
              ),
              itemBuilder: (context, index) {
                final hymn = _filtered[index];
                return _buildResultRow(hymn);
              },
            )),
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

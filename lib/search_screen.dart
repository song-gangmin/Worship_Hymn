import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/title_hymns.dart'; // HymnInfo, allHymns
import 'score_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _filtered = widget.hymns; // 처음엔 전체 1~588
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

    setState(() {
      if (q.isEmpty) {
        _filtered = widget.hymns;
      } else {
        _filtered = widget.hymns.where((h) {
          final numStr = h.number.toString();
          final title = h.title.toLowerCase();
          final lyrics = h.lyrics.toLowerCase();
          return numStr.contains(q) ||
              title.contains(q) ||
              lyrics.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('찬송가 검색', style: AppTextStyles.headline),
        centerTitle: false,
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
                hintText: '장, 제목, 가사 검색',
                hintStyle: AppTextStyles.caption,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.black),
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
            child: _filtered.isEmpty
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
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 0),
                child: Divider(
                  height: 1,
                  color: Colors.grey,
                ),
              ),
              itemBuilder: (context, index) {
                final hymn = _filtered[index];
                return _buildResultRow(hymn);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// score_screen 의 _buildEntry 디자인을 그대로 가져온 버전
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
        padding:
        const EdgeInsets.symmetric(horizontal: 0, vertical: 13),
        child: Row(
          children: [
            Text(
              '${hymn.number}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hymn.title,
                style: AppTextStyles.body.copyWith(
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

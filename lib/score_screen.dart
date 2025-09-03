import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/title_hymns.dart';
import '../constants/text_styles.dart';
import 'score_detail_screen.dart';

/// [grouped]이 true면 구간(1~100 …)별 카드 + 접/펼침.
/// false면 단일 리스트로 바로 출력 (장르별 진입 시 사용).
class ScoreScreen extends StatefulWidget {
  final String title;
  final List<int> hymnNumbers;
  final bool grouped;
  const ScoreScreen({
    super.key,
    required this.title,
    required this.hymnNumbers,
    this.grouped = true,
  });

  static ScoreScreenState? of(BuildContext ctx) =>
      ctx.findAncestorStateOfType<ScoreScreenState>();

  @override
  State<ScoreScreen> createState() => ScoreScreenState();
}

class ScoreScreenState extends State<ScoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // ★ 생성자 값(widget.*)을 복사해 상태로 운영 (장르모드 전환 반영)
  late String _title;
  late List<int> _nums;
  late bool _grouped;

  // 장르 헤더 확장 상태
  bool _genreExpanded = true;

  final List<Map<String, dynamic>> _sections = [
    {'start': 1, 'end': 100, 'isOpen': false},
    {'start': 101, 'end': 200, 'isOpen': false},
    {'start': 201, 'end': 300, 'isOpen': false},
    {'start': 301, 'end': 400, 'isOpen': false},
    {'start': 401, 'end': 500, 'isOpen': false},
    {'start': 501, 'end': 588, 'isOpen': false},
  ];

  @override
  void initState() {
    super.initState();
    // ★ 초기 상태는 생성자 값으로 세팅
    _title = widget.title;
    _nums = widget.hymnNumbers;
    _grouped = widget.grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('악보', style: AppTextStyles.headline),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          // ★ 이제부터는 widget.grouped가 아니라 _grouped(상태)를 본다
          Expanded(child: _grouped ? _buildGrouped() : _buildGenreMode()),
        ],
      ),
    );
  }
  /// 홈>장르 탭에서 호출됨: 장르 모드로 전환 + 상단 1개 박스만
  void applyGenre(String title, List<int> hymns) {
    setState(() {
      _title = title;       // 장르명
      _nums = hymns;        // 장르에 해당하는 번호들
      _grouped = false;     // ★ 장르모드 진입
      _genreExpanded = true;
      _query = '';
      _searchController.clear();
    });
  }
  void resetToDefault() {
    setState(() {
      _title = widget.title;               // '악보'
      _nums = widget.hymnNumbers;          // 1~588
      _grouped = widget.grouped;           // true
      _query = '';
      _searchController.clear();
    });
  }

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v.trim()),
      decoration: InputDecoration(
        hintText: '장, 제목, 가사 등',
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search, color: Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(fontSize: 14),
    ),
  );

  // 🔶 구간별(기존) -----------------------------
  Widget _buildGrouped() => ListView.builder(
    padding: const EdgeInsets.only(bottom: 16),
    itemCount: _sections.length,
    itemBuilder: (context, idx) {
      final sec = _sections[idx];
      final int start = sec['start'];
      final int end = sec['end'];
      final bool isOpen = sec['isOpen'] == true;

      final nums = _nums.where((n) => n >= start && n <= end).toList(); // ★ _nums 사용
      final filtered = _applyFilter(nums);
      if (filtered.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: PageStorageKey('${start}_$end'),
              initiallyExpanded: isOpen,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text('$start~$end',
                  style: AppTextStyles.sectionTitle),
              onExpansionChanged: (open) => setState(() => _sections[idx]['isOpen'] = open),
              children: _buildList(filtered),
            ),
          ),
        ),
      );
    },
  );

// 장르 모드(제목 + 리스트를 한 Card 안에, 접기 없음)
  Widget _buildGenreMode() {
    final filtered = _applyFilter(_nums);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      children: [
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목 영역
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    Expanded(child: Text(_title, style: AppTextStyles.sectionTitle)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      splashRadius: 18,
                      onPressed: resetToDefault, // ← 기본 모드로 복귀
                    ),
                  ],
                )
              ),
              // 리스트(항상 펼쳐진 상태)
              ..._buildList(filtered),
            ],
          ),
        ),
      ],
    );
  }


  // 🔧 공통 유틸 -------------------------------
  List<int> _applyFilter(List<int> nums) => nums.where((n) {
    if (_query.isEmpty) return true;
    return hymnTitles[n - 1].contains(_query);
  }).toList();

  List<Widget> _buildList(List<int> nums) {
    final List<Widget> items = [];
    for (var i = 0; i < nums.length; i++) {
      final n = nums[i];
      items.add(_buildEntry(n));
      if (i != nums.length - 1) {
        items.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Divider(height: 1, color: Colors.grey),
        ));
      }
    }
    return items;
  }

  Widget _buildEntry(int num) {
    final raw = hymnTitles[num - 1];
    final sp = raw.indexOf(' ');
    final numberPart = raw.substring(0, sp);
    final titlePart = raw.substring(sp + 1);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScoreDetailScreen(hymnNumber: num),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(numberPart, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(child: Text(titlePart, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }
}
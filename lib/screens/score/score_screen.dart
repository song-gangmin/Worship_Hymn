import 'package:flutter/material.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/constants/title_hymns.dart';
import 'package:worship_hymn/constants/text_styles.dart';
import 'package:worship_hymn/screens/score/score_detail_screen.dart';
import 'package:worship_hymn/screens/main/main_screen.dart';
import 'package:worship_hymn/screens/search/search_screen.dart';

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
  // 생성자 값(widget.*)을 복사해 상태로 운영 (장르모드 전환 반영)
  late String _title;
  late List<int> _nums;
  late bool _grouped;

  // 스크롤 맨 위로 버튼
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

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
    _title = widget.title;
    _nums = widget.hymnNumbers;
    _grouped = widget.grouped;

    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
        title: Text('악보', style: AppTextStyles.headline(context)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          Expanded(child: _grouped ? _buildGrouped() : _buildGenreMode()),
        ],
      ),
      floatingActionButton: _showScrollToTop && _grouped
          ? FloatingActionButton(
              mini: true,
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                );
              },
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  /// 홈>장르 탭에서 호출됨: 장르 모드로 전환 + 상단 1개 박스만
  void applyGenre(String title, List<int> hymns) {
    setState(() {
      _title = title;       // 장르명
      _nums = hymns;        // 장르에 해당하는 번호들
      _grouped = false;     // 장르모드 진입
    });
  }

  /// 악보 탭 초기 상태로 복귀
  void resetToDefault() {
    setState(() {
      _title = widget.title;          // '악보'
      _nums = widget.hymnNumbers;     // 1~588
      _grouped = widget.grouped;      // true
    });
  }

  // 🔍 ScoreScreen에서도 검색창 눌렀을 때 SearchScreen으로 이동
  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchScreen(
              hymns: allHymns, // 1~588 전체 리스트
            ),
          ),
        );
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black,
            ),
            const SizedBox(width: 8),
            Text(
              '장, 제목, 가사 등',
              style: AppTextStyles.caption(context),
            ),
          ],
        ),
      ),
    ),
  );

  // 🔶 구간별(기존)
  Widget _buildGrouped() => ListView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.only(bottom: 16),
    itemCount: _sections.length,
    itemBuilder: (context, idx) {
      final sec = _sections[idx];
      final int start = sec['start'];
      final int end = sec['end'];
      final bool isOpen = sec['isOpen'] == true;

      final nums =
      _nums.where((n) => n >= start && n <= end).toList();
      final filtered = _applyFilter(nums);
      if (filtered.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          color: AppColors.getSurface(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Theme(
            data: Theme.of(context)
                .copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: PageStorageKey('${start}_$end'),
              initiallyExpanded: isOpen,
              tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              title: Text('$start~$end',
                  style: AppTextStyles.sectionTitle(context)),
              onExpansionChanged: (open) =>
                  setState(() => _sections[idx]['isOpen'] = open),
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
          color: AppColors.getSurface(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목 영역
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _title,
                        style: AppTextStyles.sectionTitle(context),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black,
                      ),
                      splashRadius: 18,
                      onPressed: () {
                        // 1) 악보 탭 초기화
                        resetToDefault();

                        // 2) 홈 탭으로 이동
                        final main = MainScreen.of(context);
                        main?.goToTab(0);
                      },
                    ),
                  ],
                ),
              ),
              // 리스트(항상 펼쳐진 상태)
              ..._buildList(filtered),
            ],
          ),
        ),
      ],
    );
  }

  // 지금은 ScoreScreen 안에서는 검색 안 하니까 그대로 반환
  List<int> _applyFilter(List<int> nums) => nums;

  List<Widget> _buildList(List<int> nums) {
    final List<Widget> items = [];
    for (var i = 0; i < nums.length; i++) {
      final n = nums[i];
      items.add(_buildEntry(n));
      if (i != nums.length - 1) {
        items.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Divider(
            height: 0.5,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12,
          ),
        ));
      }
    }
    return items;
  }

  /// 찬송가 장, 제목
  Widget _buildEntry(int num) {
    final raw = hymnTitles[num - 1];
    final sp = raw.indexOf(' ');
    final numberPart = raw.substring(0, sp);   // "1", "10", "100" ...
    final titlePart = raw.substring(sp + 1);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScoreDetailScreen(
              hymnNumber: num,
              hymnTitle: titlePart,
            ),
          ),
        );
      },
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // 🔹 숫자 컬럼: 폭 고정 + 등폭 숫자 + 오른쪽 정렬
            SizedBox(
              width: 40, // 숫자 1~588까지 커버할 정도로 고정 폭
              child: Text(
                numberPart,
                textAlign: TextAlign.left,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w300,
                  // 숫자 폭을 동일하게 만드는 설정 (폰트가 지원하면 적용됨)
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 제목: 항상 같은 x좌표에서 시작
            Expanded(
              child: Text(
                titlePart,
                style: AppTextStyles.body(context).copyWith(
                  fontSize: AppTextStyles.font(context).applySize(17),
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

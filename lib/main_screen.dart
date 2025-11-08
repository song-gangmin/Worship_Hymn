import 'package:flutter/material.dart';
import 'constants/text_styles.dart';
import 'home_screen.dart';
import 'score_screen.dart';
import 'bookmark_screen.dart';
import 'setting_screen.dart';
import 'constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainScreen extends StatefulWidget {
  final String? name;
  final String? email;

  const MainScreen({
    Key? key,
    this.name,
    this.email,
  }) : super(key: key);

  static _MainScreenState? of(BuildContext ctx) =>
      ctx.findAncestorStateOfType<_MainScreenState>();

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 🔸 삭제 오버레이
  OverlayEntry? _deleteOverlay;

  // 🔸 BookmarkScreen 제어용 키
  final GlobalKey<BookmarkScreenState> _bookmarkKey = GlobalKey<BookmarkScreenState>();

  void goToTab(int index) => setState(() => _selectedIndex = index);

  final GlobalKey<ScoreScreenState> scoreKey = GlobalKey<ScoreScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      ScoreScreen(
        key: scoreKey,
        title: '악보',
        hymnNumbers: List.generate(588, (i) => i + 1),
        grouped: true,
      ),
      // ✅ BookmarkScreen에 콜백 전달
      BookmarkScreen(
        key: _bookmarkKey,
        onSelectionChanged: (hasSelection) {
          if (hasSelection) {
            _showDeleteOverlay();
          } else {
            _hideDeleteOverlay();
          }
        },
        onGoToTab: goToTab, // ✅ 추가: MainScreen의 goToTab 연결
      ),
      SettingScreen(
        name: widget.name ?? '',
        email: widget.email ?? '',
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    // 탭 전환 시 삭제바 정리
    if (index != 2) _hideDeleteOverlay();
  }
  // 🔹 삭제 오버레이 표시
  void _showDeleteOverlay() {
    if (_deleteOverlay != null) return; // 이미 떠 있으면 무시
    final overlay = Overlay.of(context);

    _deleteOverlay = OverlayEntry(
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).padding.bottom; // 홈바 높이
        return Positioned(
          left: 0, right: 0, bottom: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              // ⬇️ 바닥까지 채우기: 홈바 + 여백만큼 패딩
              padding: EdgeInsets.only(bottom: bottomInset + 10, top: 20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: InkWell(
                onTap: () => _bookmarkKey.currentState?.confirmDeleteSelected(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.white, size: 22),
                    SizedBox(width: 4),
                    Text('삭제', style: AppTextStyles.sectionTitle.copyWith(fontSize: 18, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_deleteOverlay!);
  }

  // 🔹 삭제 오버레이 숨김
  void _hideDeleteOverlay() {
    _deleteOverlay?.remove();
    _deleteOverlay = null;
  }

  @override
  void dispose() {
    _hideDeleteOverlay();
    super.dispose();
  }

  /// 바텀 navigation
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF673E38),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset('assets/icon/home.svg', width: 20, height: 20,
                  color: _selectedIndex == 0 ? const Color(0xFF673E38) : Colors.grey),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset('assets/icon/score.svg', width: 20, height: 20,
                  color: _selectedIndex == 1 ? const Color(0xFF673E38) : Colors.grey),
              label: '악보',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset('assets/icon/bookmark.svg', width: 20, height: 20,
                  color: _selectedIndex == 2 ? const Color(0xFF673E38) : Colors.grey),
              label: '즐겨찾기',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset('assets/icon/setting.svg', width: 20, height: 20,
                  color: _selectedIndex == 3 ? const Color(0xFF673E38) : Colors.grey),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'constants/text_styles.dart';
import 'home_screen.dart';
import 'score_screen.dart';
import 'bookmark_screen.dart';
import 'setting_screen.dart';
import 'score_detail_screen.dart';
import 'constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? initialPlaylistId;

  const MainScreen({
    Key? key,
    this.initialTabIndex = 0,
    this.initialPlaylistId,
  }) : super(key: key);

  static _MainScreenState? of(BuildContext ctx) =>
      ctx.findAncestorStateOfType<_MainScreenState>();

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 🔸 BookmarkScreen 제어용 키
  final GlobalKey<BookmarkScreenState> _bookmarkKey = GlobalKey<BookmarkScreenState>();
  final GlobalKey<ScoreScreenState> scoreKey = GlobalKey<ScoreScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // 🔥 ScoreDetailScreen에서 설정한 탭으로 바로 이동하도록
    _selectedIndex = widget.initialTabIndex;

    _screens = [
      const HomeScreen(),
      ScoreScreen(
        key: scoreKey,
        title: '악보',
        hymnNumbers: List.generate(588, (i) => i + 1),
        grouped: true,
      ),

      // 🔥 BookmarkScreen에 초기 playlistId도 전달
      BookmarkScreen(
        key: UniqueKey(),
        onSelectionChanged: (_) {},
        onGoToTab: goToTab,
        initialPlaylistId: widget.initialPlaylistId,
      ),

      const SettingScreen(),
    ];
  }

  void goToTab(int index) => setState(() => _selectedIndex = index);

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'score_screen.dart';
import 'bookmark_screen.dart';
import 'more_screen.dart';
import 'constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  static _MainScreenState? of(BuildContext ctx) =>
      ctx.findAncestorStateOfType<_MainScreenState>();

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

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
      const BookmarkScreen(),
      const MoreScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // 은은한 그림자
              blurRadius: 10,
              offset: const Offset(0, -2), // 위쪽 방향으로 그림자
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white, // 바텀 네비 배경
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
              icon: SvgPicture.asset(
                'assets/icon/home.svg',
                width: 20,
                height: 20,
                color: _selectedIndex == 0 ? const Color(0xFF673E38) : Colors.grey,
              ),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icon/score.svg',
                width: 20,
                height: 20,
                color: _selectedIndex == 1 ? const Color(0xFF673E38) : Colors.grey,
              ),
              label: '악보',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icon/bookmark.svg',
                width: 20,
                height: 20,
                color: _selectedIndex == 2 ? const Color(0xFF673E38) : Colors.grey,
              ),
              label: '즐겨찾기',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icon/more.svg',
                width: 20,
                height: 20,
                color: _selectedIndex == 3 ? const Color(0xFF673E38) : Colors.grey,
              ),
              label: '더보기',
            ),
          ],
        ),
      ),
    );
  }
}
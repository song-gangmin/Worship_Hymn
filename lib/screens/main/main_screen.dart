import 'package:flutter/material.dart';
import 'package:worship_hymn/screens/home/home_screen.dart';
import 'package:worship_hymn/screens/score/score_screen.dart';
import 'package:worship_hymn/screens/bookmark/bookmark_screen.dart';
import 'package:worship_hymn/screens/settings/setting_screen.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';     // 추가
import 'package:cloud_firestore/cloud_firestore.dart'; // 추가

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
  @override
  Widget build(BuildContext context) {
    // 1. 현재 로그인된 유저 ID 가져오기
    final user = FirebaseAuth.instance.currentUser;

    // (만약 로그아웃 상태라면 에러 방지를 위해 빈 화면 리턴)
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // 2. 여기서 Firestore 데이터 실시간 감지 (StreamBuilder)
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            selectedItemColor: const Color(0xFF673E38),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/icon/home.svg', width: 20, height: 20,
                    colorFilter: ColorFilter.mode(_selectedIndex == 0 ? const Color(0xFF673E38) : Colors.grey, BlendMode.srcIn)),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/icon/score.svg', width: 20, height: 20,
                    colorFilter: ColorFilter.mode(_selectedIndex == 1 ? const Color(0xFF673E38) : Colors.grey, BlendMode.srcIn)),
                label: '악보',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/icon/bookmark.svg', width: 20, height: 20,
                    colorFilter: ColorFilter.mode(_selectedIndex == 2 ? const Color(0xFF673E38) : Colors.grey, BlendMode.srcIn)),
                label: '즐겨찾기',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/icon/setting.svg', width: 20, height: 20,
                    colorFilter: ColorFilter.mode(_selectedIndex == 3 ? const Color(0xFF673E38) : Colors.grey, BlendMode.srcIn)),
                label: '설정',
              ),
            ],
          ),
        );
      },
    );
  }
}

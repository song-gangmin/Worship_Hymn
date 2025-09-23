// lib/main_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// TODO: 실제 화면들로 교체하세요
import 'home_screen.dart';
import 'setting_screen.dart';

class MainScreen extends StatefulWidget {
  final String? name;
  final String? email;

  const MainScreen({
    super.key,
    this.name,
    this.email,
  });

  // 다른 위젯에서 MainScreen의 state에 접근할 때 사용 (home_screen.dart에서 쓰고 있음)
  static _MainScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainScreenState>();

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // home_screen.dart에서 기대하는 키/메서드들
  final GlobalKey<State<StatefulWidget>> scoreKey = GlobalKey();

  late final TabController _tabController;

  void goToTab(int index) {
    if (index >= 0 && index < _tabController.length) {
      _tabController.index = index;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 예시: 2개 탭(홈/설정)
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // 로그인 상태가 아닌데 MainScreen에 들어온 경우 방어
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? <String, dynamic>{};
        final showName  = data['displayName'] ?? data['name']  ?? widget.name  ?? '로그인 하세요';
        final showEmail = data['email']       ?? widget.email  ?? '이메일 정보 없음';

        return Scaffold(
          appBar: AppBar(
            title: Text(showName),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.home), text: '홈'),
                Tab(icon: Icon(Icons.settings), text: '설정'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 실제 홈/스코어 화면으로 바꾸세요.
              // scoreKey는 필요시 두 번째/다른 탭에 달아 쓰도록 옮기면 됩니다.
              HomeScreen(), // 예시
              SettingScreen(name: showName, email: showEmail),
            ],
          ),
        );
      },
    );
  }
}

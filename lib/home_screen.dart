import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import 'genre_scroll.dart';
import 'main_screen.dart';
import 'score_detail_screen.dart';

// 🔥 서비스 import (반드시 추가!!)
import 'recent_service.dart';
import 'global_stats_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'RecentListScreen.dart';
import 'package:flutter_svg/flutter_svg.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late RecentService recentService;
  late GlobalStatsService globalService;
  late String uid;

  final statsRef = FirebaseFirestore.instance.collection('global_stats');


  @override
  void initState() {
    super.initState();

    uid = FirebaseAuth.instance.currentUser?.uid ?? "kakao:4424196142";

    recentService = RecentService(uid: uid);
    globalService = GlobalStatsService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('홈', style: AppTextStyles.headline),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            // 🔍 검색창 ------------------------
            TextField(
              decoration: InputDecoration(
                hintText: '장, 제목, 가사 등',
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

            const SizedBox(height: 16),

            // 🎧 장르별 ------------------------
            Text('장르별', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            GenreScroll(
              onTopicSelected: (topic, hymns) {
                final main = MainScreen.of(context);
                main?.goToTab(1);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  main?.scoreKey.currentState?.applyGenre(topic, hymns);
                });
              },
            ),

            const SizedBox(height: 26),

            // ⭐ 최근 본 찬송가 ------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('최근 본 찬송가', style: AppTextStyles.sectionTitle),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecentAllScreen(uid: uid),
                      ),
                    );
                  },
                  child: Text('모두 보기', style: AppTextStyles.caption),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRecent3(),    // 🔥 Firestore 연동

            const SizedBox(height: 32),

            // ⭐ 이번 주 가장 많이 찾은 찬송가 ------------------------
            Text('이번 주 제일 많이 찾은 찬송가', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            _buildWeeklyTop3(), // 🔥 Firestore 연동
          ],
        ),
      ),
    );
  }

  // 🔥 최근 본 찬송가 3개
  Widget _buildRecent3() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recent_views')
          .orderBy('viewedAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            final data = doc.data()!;
            return _buildSongTile(
              title: "${data['number']}장",
              subtitle: data['title'],
              number: data['number'],   // int
            );
          }).toList(),
        );
      },
    );
  }

  // 🔥 이번 주 인기 찬송 Top 3
  Widget _buildWeeklyTop3() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('global_stats')
          .orderBy('weeklyCount', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Text("이번 주 통계가 아직 없습니다.");
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data()!;
            return _buildSongTile(
              number: data['number'],               // 🔥 int
              title: data['title'],                 // 🔥 String
              subtitle: "조회수 ${data['weeklyCount']}", // 🔥 subtitle (String)
            );
          }).toList(),
        );
      },
    );
  }

  // 🎵 공통 Song Tile 위젯
  Widget _buildSongTile({
    required int number,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: SvgPicture.asset(
          'assets/icon/music.svg',
          width: 32,
          height: 32,
          colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
        ),
        title: Text("$number장", style: AppTextStyles.body),
        subtitle: Text(title),
        trailing: Text(subtitle, style: AppTextStyles.caption),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScoreDetailScreen(
                hymnNumber: number,
                hymnTitle: title,
              ),
            ),
          );
        },
      ),
    );
  }
}


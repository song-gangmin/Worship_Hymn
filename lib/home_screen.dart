import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import 'genre_scroll.dart';
import 'main_screen.dart';
import 'score_detail_screen.dart';
import 'search_screen.dart';
import 'constants/title_hymns.dart';

// 서비스
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('홈', style: AppTextStyles.headline),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            // 🔍 검색창
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(
                      hymns: allHymns, // 1~588 전체 리스트 넣어주기
                    ),
                  ),
                );
              },
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      '장, 제목, 가사 등',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🎧 장르별
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

            // ⭐ 최근 본 찬송가
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

            _buildRecent3(),

            const SizedBox(height: 32),

            // ⭐ 이번 주 제일 많이 찾은 찬송가
            Text('이번 주 제일 많이 찾은 찬송가', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),

            _buildWeeklyTop3(),
          ],
        ),
      ),
    );
  }

  // 🔥 최근 본 찬송가 Top 3
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
        if (snapshot.hasError) {
          // 디버깅용으로 한 번만 찍고, UI는 그냥 비워두는 게 좋음
          debugPrint('recent_views error: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            final data = doc.data()!;

            // number, title도 타입 안전하게
            final rawNumber = data['number'];
            final int number =
            rawNumber is int ? rawNumber : int.tryParse(rawNumber.toString()) ?? 0;

            final String title = (data['title'] ?? '').toString();

            // 🔥 viewedAt 안전 처리 (serverTimestamp() 때문에 null 가능)
            final rawViewedAt = data['viewedAt'];
            DateTime viewedAt;

            if (rawViewedAt is Timestamp) {
              viewedAt = rawViewedAt.toDate();
            } else {
              // 아직 서버에서 timestamp 안 채워졌으면 그냥 지금 시간으로 대체
              viewedAt = DateTime.now();
            }

            return _buildSongTile(
              number: number,
              title: title,
              trailingText: timeAgo(viewedAt),
            );
          }).toList(),
        );
      },
    );
  }


  // 🔥 이번 주 인기 찬송가 Top 3
  Widget _buildWeeklyTop3() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('global_stats')
          .orderBy('weeklyCount', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('global_stats error: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Text("이번 주 통계가 아직 없습니다.");
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data()!;
            final rawNumber = data['number'];
            final int number =
            rawNumber is int ? rawNumber : int.tryParse(rawNumber.toString()) ?? 0;

            final String title = (data['title'] ?? '').toString();
            final int weeklyCount = (data['weeklyCount'] ?? 0) as int;

            return _buildSongTile(
              number: number,
              title: title,
              trailingText: "조회수 $weeklyCount",
            );
          }).toList(),
        );
      },
    );
  }


  // 🎵 공통 Song Tile UI
  Widget _buildSongTile({
    required int number,
    required String title,
    String? subtitle,
    String? trailingText,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 20, right: 20),
        horizontalTitleGap: 20, // ← 이 값을 조절하면 아이콘과 텍스트 사이 간격이 줄어듦
        leading: SvgPicture.asset(
          'assets/icon/music.svg',
          width: 32,
          height: 32,
          colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
        ),
        title: Text("$number장", style: AppTextStyles.body),
        subtitle: Text(title),
        trailing: trailingText != null
            ? Text(trailingText, style: AppTextStyles.caption)
            : null,
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

  // 📌 시간 표시 함수
  String timeAgo(DateTime lastViewed) {
    final now = DateTime.now();
    final diff = now.difference(lastViewed);
    final minutes = diff.inMinutes;
    final hours = diff.inHours;
    final days = diff.inDays;

    if (minutes < 1) return "방금 전";
    if (minutes < 60) return "${minutes}분 전";

    if (hours < 24) return "${hours}시간 전";

    if (days == 1) return "1일 전";
    if (days == 2) return "2일 전";

    if (days < 7) return "${days}일 전";

    return "일주일 전";
  }
}

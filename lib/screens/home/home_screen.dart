import 'package:flutter/material.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/constants//text_styles.dart';
import 'package:worship_hymn/widget/genre_scroll.dart';
import 'package:worship_hymn/screens/main/main_screen.dart';
import 'package:worship_hymn/screens/score/score_detail_screen.dart';
import 'package:worship_hymn/screens/search/search_screen.dart';
import 'package:worship_hymn/constants/title_hymns.dart';
import 'package:worship_hymn/services/recent_service.dart';
import 'package:worship_hymn/services/global_stats_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:worship_hymn/screens/home/RecentAllScreen.dart';
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated');
    }
    uid = currentUser.uid;

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
                      '장, 제목 등',
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

            // ⭐ 이번 주 인기 찬송가
            Text('이번 주 인기 찬송가 TOP 3', style: AppTextStyles.sectionTitle),
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
      stream: RecentService(uid: uid).getRecent3(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final list = snapshot.data!;

        return Column(
          children: list.map((item) {
            final rawNumber = item['number'];
            final number = rawNumber is int
                ? rawNumber
                : int.tryParse(rawNumber.toString()) ?? 0;

            final String rawTitle = item['title'] ?? '';
            final String title = rawTitle.toString().trim();
            final ts = item['viewedAt'];

            DateTime viewedAt;
            if (ts is Timestamp) {
              viewedAt = ts.toDate();
            } else {
              viewedAt = DateTime.now();
            }

            return _buildSongTile(
              number: number,
              title: title,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeAgo(viewedAt),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
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

            final String title = (data['title'] ?? '').toString().trim();
            final int weeklyCount = (data['weeklyCount'] ?? 0) as int;

            return _buildSongTile(
              number: number,
              title: title,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.remove_red_eye,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "$weeklyCount",
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSongTile({
    required int number,
    required String title,
    Widget? trailing,
  }) {
    return InkWell(
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
      borderRadius: BorderRadius.circular(12),

      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🎵 왼쪽 아이콘
              SvgPicture.asset(
                'assets/icon/music.svg',
                width: 32,
                height: 32,
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 22),

              // 🔠 가운데: 번호 + 제목 (항상 왼쪽 정렬)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Text(
                      "$number장",
                      style: AppTextStyles.body.copyWith(
                        height: 1.2,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              ),

              // 🕒 / 👁 오른쪽 트레일링
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ],
            ],
          ),
        ),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worship_hymn/constants/text_styles.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/screens/score/score_detail_screen.dart';
import 'package:worship_hymn/services/recent_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RecentAllScreen extends StatelessWidget {
  final String uid;

  const RecentAllScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final recentService = RecentService(uid: uid);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '최근 본 찬송가 모두 보기',
          style: AppTextStyles.headline.copyWith(fontSize: 18),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: recentService.getRecentWithin7Days(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text("최근 7일 동안 본 기록이 없습니다."));
          }

          return ListView.builder(
            itemCount: list.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, i) {
              final item = list[i];
              final num = item["number"];
              final String title = (item["title"] ?? '').toString().trim();

              final ts = item["viewedAt"];
              DateTime viewedAt;
              if (ts is Timestamp) {
                viewedAt = ts.toDate();
              } else {
                viewedAt = DateTime.now();
              }

              final formatted = DateFormat("MM/dd HH:mm").format(viewedAt);

              return _buildSongTile(
                context: context,
                number: num,
                title: title,
                trailingText: formatted,
              );
            },
          );
        },
      ),
    );
  }

  // 📌 HomeScreen 카드 스타일 그대로 적용한 SongTile
  Widget _buildSongTile({
    required BuildContext context,
    required int number,
    required String title,
    String? trailingText,
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

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$number장",
                      style: AppTextStyles.body.copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: AppTextStyles.caption.copyWith(
                        height: 1.2,
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              if (trailingText != null) ...[
                const SizedBox(width: 12),
                Text(
                  trailingText,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

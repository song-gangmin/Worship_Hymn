import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import 'genre_scroll.dart';
import 'main_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            // 검색창
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

            const SizedBox(height: 8),

            // 장르별
            Text('장르별', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            GenreScroll(
              onTopicSelected: (topic, hymns) {
                final main = MainScreen.of(context);
                // 1) 먼저 탭 이동 (예: Score 탭이 1번 인덱스라고 가정)
                main?.goToTab(1);

                // 2) 다음 프레임에서 ScoreScreen이 빌드된 뒤 상태에 접근
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final score = main?.scoreKey.currentState;
                  score?.applyGenre(topic, hymns);
                });
              },
            ),

            const SizedBox(height: 32),

            // 최근 본 찬송가
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('최근 본 찬송가', style: AppTextStyles.sectionTitle),
                Text('모두 보기', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 12),
            _buildSongTile(title: '예배 찬송가 1장', subtitle: '가사를 기록', number: '3번'),
            _buildSongTile(title: '예배 찬송가 2장', subtitle: '가사를 기록', number: '8번'),
            _buildSongTile(title: '예배 찬송가 3장', subtitle: '가사를 기록', number: '14번'),

            const SizedBox(height: 32),

            // 인기 찬송가
            Text('이번 주 제일 많이 찾은 찬송가', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            _buildSongTile(title: '예배 찬송가 5장', subtitle: '가사를 기록', number: '1번'),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile({
    required String title,
    required String subtitle,
    required String number,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.music_note, color: AppColors.primary),
        title: Text(title, style: AppTextStyles.body),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: Text(number, style: AppTextStyles.caption),
      ),
    );
  }
}

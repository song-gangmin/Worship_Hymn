import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<String> playlists = ['전체']; // ✅ 기본 재생목록
  int selectedIndex = 0; // 현재 선택된 탭

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('즐겨찾기', style: AppTextStyles.headline),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              // TODO: 편집 모드로 진입하는 코드 추가
            },
            child: const Text(
              '편집',
              style: TextStyle(
                color: AppColors.primary, // AppColors.primary와 비슷한 갈색
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // 🔸 필터 영역 (상단 재생목록 탭)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(playlists.length, (index) {
                  final selected = selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          playlists[index],
                          style: TextStyle(
                            fontSize: 15,
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 60),

          // 🔸 중앙 안내 문구
          Expanded(
            child: Center(
              child: Text(
                selectedIndex == 0
                    ? '전체 즐겨찾기 목록이 여기에 표시됩니다'
                    : '"${playlists[selectedIndex]}" 재생목록이 비어 있습니다',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),

      // 🔸 오른쪽 하단 + 버튼
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () => _showAddPlaylistDialog(context),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  /// 🔹 새 재생목록 이름 입력 다이얼로그
  void _showAddPlaylistDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text(
            '새 재생목록',
            style: AppTextStyles.sectionTitle,
          ),

          // ✅ 크기 조절 추가 부분
          content: SizedBox(
            width: 300, // 가로 크기 조절 (원하는 값으로 조정 가능)
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '제목을 입력하세요',
                hintStyle: AppTextStyles.caption.copyWith(fontSize: 16),
                border: InputBorder.none,
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1),
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 60, // 버튼 너비 동일
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200, // 취소 버튼 배경
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      '취소',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 60, // 동일한 크기
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, // 진한 갈색
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty && !playlists.contains(name)) {
                        setState(() {
                          playlists.add(name);
                          selectedIndex = playlists.length - 1;
                        });
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      '추가',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

}

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({
    super.key,
    this.onSelectionChanged, // ✅ MainScreen 오버레이 트리거 콜백
  });

  final ValueChanged<bool>? onSelectionChanged;

  @override
  State<BookmarkScreen> createState() => BookmarkScreenState();
}

class BookmarkScreenState extends State<BookmarkScreen> {
  // ---- 재생목록 & 상태 ----
  final List<String> playlists = ['전체', '새벽기도', '예배', '캠프/수양회', '수요', '복음'];
  int selectedPlaylistIndex = 0;

  bool isEditing = false;
  Set<int> selectedItems = {};

  // 데모용 데이터
  final List<String> hymns = const [
    '내 주 되신 주를 더 사랑하고',
    '구주 예수 의지함이',
    '변찮는 주님의 사랑과',
    '예수로 나의 구주 삼고',
    '시온의 영광이 빛나는 아침',
    '나 같은 죄인 살리신',
    '아 하나님의 은혜로',
    '주 하나님 지으신 모든 세계',
    '주 하나님 독생자 예수',
    '예수 나를 위하여',
    '큰 영광 중에 계신 주',
    '예배드립니다',
  ];

  // ---- life-cycle ----
  void _notifySelection() {
    widget.onSelectionChanged?.call(selectedItems.isNotEmpty);
  }

  void _clearSelectionAndNotify() {
    selectedItems.clear();
    _notifySelection();
  }

  void confirmDeleteSelected() {
    if (selectedItems.isEmpty) return; // 아무것도 선택 안 됐으면 무시
    _confirmDeleteSelected(); // 내부 다이얼로그 실행
  }

  /// 즐겨찾기한 노래 삭제 함수
  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('선택한 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                hymns.removeWhere(
                      (item) => selectedItems.contains(hymns.indexOf(item)),
                );
                selectedItems.clear();
              });
              Navigator.pop(ctx);
              widget.onSelectionChanged?.call(false); // 선택 해제 알림
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 재생목록 삭제 함수
  void _confirmDeletePlaylist() {
    final currentName = playlists[selectedPlaylistIndex];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('재생목록 삭제'),
        content: Text('‘$currentName’을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                playlists.removeAt(selectedPlaylistIndex);
                selectedPlaylistIndex = 0; // 전체로 이동
              });
              Navigator.pop(ctx);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: isEditing
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () {
            setState(() => isEditing = false);
            _clearSelectionAndNotify();
          },
        )
            : null,
        title: isEditing
            ? const SizedBox.shrink()
            : const Text('즐겨찾기', style: AppTextStyles.headline),
        centerTitle: false,
        actions: [
          if (isEditing && playlists[selectedPlaylistIndex] != '전체') // ✅ 전체가 아닐 때만 표시
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 0), // 👉 여백 조절
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.black87),
                tooltip: '재생목록 삭제',
                onPressed: _confirmDeletePlaylist,
              ),
            ),
          TextButton(
            onPressed: () {
              setState(() => isEditing = !isEditing);
              _clearSelectionAndNotify();
            },
            child: Text(
              isEditing ? '완료' : '편집',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 4), // ✅ 전체 오른쪽 끝에도 살짝 여백
        ],
      ),
      body: isEditing ? _buildEditMode() : _buildNormalMode(),
      floatingActionButton: isEditing ? null : FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () => _showCreateDialog(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ---------------- Normal mode ----------------
  Widget _buildNormalMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlaylistChips(),            // ✅ 재생목록 칩 + 새 재생목록
        const SizedBox(height: 6),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: hymns.length,
            itemBuilder: (_, i) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  title: Text(hymns[i], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
                  trailing: const Icon(Icons.drag_handle, color: Colors.black54, size: 20),
                  onTap: () {
                    // TODO: 곡 상세/재생 등
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- Edit mode ----------------
  Widget _buildEditMode() {
    final title = playlists[selectedPlaylistIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 연필(이름수정)
          Row(
            children: [
              Text(title, style: AppTextStyles.headline),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showRenameDialog(currentName: title, index: selectedPlaylistIndex),
                child: const Icon(Icons.edit, size: 20, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 전체 선택
          GestureDetector(
            onTap: () {
              setState(() {
                if (selectedItems.length == hymns.length) {
                  selectedItems.clear();
                } else {
                  selectedItems = Set.from(List<int>.generate(hymns.length, (i) => i));
                }
              });
              _notifySelection();
            },
            child: Row(
              children: [
                Icon(
                  selectedItems.length == hymns.length ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 20,
                  color: Colors.black,
                ),
                const SizedBox(width: 6),
                const Text('전체 선택', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 리스트 (선택/해제)
          Expanded(
            child: ListView.builder(
              itemCount: hymns.length,
              itemBuilder: (_, i) {
                final selected = selectedItems.contains(i);
                return InkWell(
                  onTap: () {
                    setState(() {
                      selected ? selectedItems.remove(i) : selectedItems.add(i);
                    });
                    _notifySelection();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? Colors.black54 : Colors.white,
                      border: const Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${i + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      title: Text(hymns[i], style: const TextStyle(fontSize: 15)),
                      trailing: const Icon(Icons.drag_handle, color: Colors.black54, size: 20),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- UI parts ----------------
  Widget _buildPlaylistChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...List.generate(playlists.length, (i) {
              final selected = selectedPlaylistIndex == i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => selectedPlaylistIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [if (!selected) BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 2, offset: const Offset(1, 2))],
                    ),
                    child: Text(
                      playlists[i],
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: selected ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ---------------- Dialogs ----------------
  void _showCreateDialog() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _playlistDialog(
        ctx,
        title: '새 재생목록',
        confirmText: '추가',
        controller: c,
        onConfirm: () {
          final name = c.text.trim();
          if (name.isNotEmpty && !playlists.contains(name)) {
            setState(() {
              playlists.add(name);
              selectedPlaylistIndex = playlists.length - 1;
            });
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showRenameDialog({required String currentName, required int index}) {
    final c = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => _playlistDialog(
        ctx,
        title: '재생목록 이름 수정',
        confirmText: '저장',
        controller: c,
        onConfirm: () {
          final name = c.text.trim();
          if (name.isNotEmpty) {
            setState(() => playlists[index] = name);
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _playlistDialog(
      BuildContext ctx, {
        required String title,
        required String confirmText,
        required TextEditingController controller,
        required VoidCallback onConfirm,
      }) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: Text(title, style: AppTextStyles.sectionTitle),
      content: SizedBox(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 4),
              hintText: '제목을 입력하세요',
              hintStyle: AppTextStyles.caption.copyWith(fontSize: 16),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _dialogBtn(ctx, '취소', Colors.grey.shade200, Colors.black, () => Navigator.pop(ctx)),
            const SizedBox(width: 10),
            _dialogBtn(ctx, confirmText, AppColors.primary, Colors.white, onConfirm),
          ],
        ),
      ],
    );
  }

  Widget _dialogBtn(BuildContext ctx, String text, Color bg, Color fg, VoidCallback onPressed) {
    return SizedBox(
      width: 74, height: 38,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onPressed,
        child: Text(text, style: AppTextStyles.body.copyWith(fontSize: 14, color: fg, fontWeight: FontWeight.w500)),
      ),
    );
  }

  // ---------------- External actions (MainScreen에서 호출) ----------------
  void deleteSelected() {
    if (selectedItems.isEmpty) return;
    setState(() {
      hymns.removeWhere((h) => selectedItems.contains(hymns.indexOf(h)));
      selectedItems.clear();
    });
    _notifySelection();
  }
}

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import 'dart:async';

import 'services/playlist_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  int selectedPlaylistIndex = 0;

  bool isEditing = false;
  Set<int> selectedItems = {};

  late PlaylistService playlistService;
  String uid = 'test_user'; // 나중에 FirebaseAuth.instance.currentUser!.uid 로 변경

  List<Map<String, dynamic>> originalPlaylists = [];
  List<Map<String, dynamic>> editingPlaylists = [];
  Set<int> originalSelectedItems = {};

  // 데모용 데이터
  final List<String> hymns = const [];

  StreamSubscription? _playlistSub;


  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      uid = currentUser.uid;
      createUserIfNotExists(uid); // ✅ Firestore 사용자 문서 자동 생성
    }
    playlistService = PlaylistService(uid: uid);
  }

  @override
  void dispose() {
    _playlistSub?.cancel();
    super.dispose();
  }

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

  Future<void> createUserIfNotExists(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userSnap = await userRef.get();

    if (!userSnap.exists) {
      await userRef.set({
        'createdAt': FieldValue.serverTimestamp(),
      });

      await userRef.collection('playlists').add({
        'name': '전체',
        'createdAt': FieldValue.serverTimestamp(),
        'default': true,
      });
    }
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
  Future<void> _confirmDeletePlaylist(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('재생목록 삭제'),
        content: const Text('이 재생목록을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await playlistService.deletePlaylist(id);
    }
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
          onPressed: _showDiscardChangesDialog,
        )
            : null,
        title: isEditing
            ? const SizedBox.shrink()
            : const Text('즐겨찾기', style: AppTextStyles.headline),
        centerTitle: false,
        actions: [
          if (isEditing && editingPlaylists.isNotEmpty && editingPlaylists[selectedPlaylistIndex]['name'] != '전체')
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 0),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.black87),
                tooltip: '재생목록 삭제',
                onPressed: () {
                  final id = editingPlaylists[selectedPlaylistIndex]['id'];
                  final name = editingPlaylists[selectedPlaylistIndex]['name'];
                  _showDeletePlaylistDialog(id, name);
                },
              ),
            ),
          TextButton(
            onPressed: () async {
              // ✅ 편집 중이 아닐 때 → 편집모드 진입
              if (!isEditing) {
                setState(() => isEditing = true);
                return;
              }

              // ✅ 편집 중일 때 → 편집 완료
              setState(() => isEditing = false);
              _clearSelectionAndNotify();

              // Firestore에 실제 저장
              for (final p in editingPlaylists) {
                if (p['id'] != 'all') {
                  await playlistService.renamePlaylist(p['id'], p['name']);
                }
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('변경사항이 저장되었습니다.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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
    if (editingPlaylists.isEmpty || selectedPlaylistIndex >= editingPlaylists.length) {
      return const Center(child: Text('재생목록이 없습니다.'));
    }
    final title = editingPlaylists[selectedPlaylistIndex]['name'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 연필(이름수정)
          Row(
            children: [
              Text(
                editingPlaylists[selectedPlaylistIndex]['name'] ?? '',
                style: AppTextStyles.headline,
              ),
              const SizedBox(width: 6),
              if (editingPlaylists[selectedPlaylistIndex]['name'] != '전체')
                GestureDetector(
                  onTap: () {
                    final id = editingPlaylists[selectedPlaylistIndex]['id'] as String;
                    final currentName = editingPlaylists[selectedPlaylistIndex]['name'] as String;
                    _showRenameDialog(id, currentName);
                  },
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: playlistService.getPlaylists(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Firestore에서 받은 데이터
        final data = [
          {'id': 'all', 'name': '전체'},
          ...snapshot.data!,
        ];

        // ✅ Firestore에서 새로 들어온 데이터를 원본으로 저장
        originalPlaylists = List<Map<String, dynamic>>.from(data);

        // ✅ 편집모드 아닐 때는 항상 editingPlaylists 동기화
        if (!isEditing) {
          editingPlaylists = List<Map<String, dynamic>>.from(originalPlaylists);
        }

        // ✅ 현재 화면에서는 editingPlaylists로 표시
        final playlists = editingPlaylists;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: playlists.map((p) {
              final name = p['name'];
              final selected = name == playlists[selectedPlaylistIndex]['name'];
              return GestureDetector(
                onTap: () {
                  setState(() => selectedPlaylistIndex = playlists.indexOf(p));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      if (!selected)
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(1, 2),
                        ),
                    ],
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
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
        onConfirm: () async {
          final name = c.text.trim();

          if (name.isEmpty) {
            Navigator.pop(ctx);
            return;
          }

          // ✅ 중복 검사
          final exists = editingPlaylists.any((p) => p['name'] == name);
          if (exists) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미 "$name" 재생목록이 존재합니다.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.black87,
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }
          Navigator.pop(ctx);
          // ✅ Firestore 추가
          await playlistService.addPlaylist(name);

          setState(() {}); // 🔹 즉시 반영

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$name" 재생목록이 추가되었습니다.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showRenameDialog(String id, String currentName) {
    final c = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => _playlistDialog(
        ctx,
        title: '재생목록 이름 수정',
        confirmText: '저장',
        controller: c,
        onConfirm: () {
          final newName = c.text.trim();
          if (newName.isEmpty) {
            Navigator.pop(ctx);
            return;
          }

          Navigator.pop(ctx);
          setState(() {
            final index = editingPlaylists.indexWhere((p) => p['id'] == id);
            if (index != -1) {
              editingPlaylists[index]['name'] = newName;
            }
          });
        },
      ),
    );
  }

  Future<void> _showDiscardChangesDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _playlistDialog(
        ctx,
        title: '변경사항을 취소할까요?',
        confirmText: '예',
        showTextField: false, // ✅ 입력창 숨김
        onConfirm: () {
          Navigator.pop(ctx, true);
        },
      ),
    );

    if (confirmed == true) {
      setState(() {
        isEditing = false;
        editingPlaylists = List<Map<String, dynamic>>.from(originalPlaylists);
      });
      _clearSelectionAndNotify();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('변경사항이 취소되었습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showDeletePlaylistDialog(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _playlistDialog(
        ctx,
        title: '재생목록을 삭제할까요?',
        confirmText: '삭제',
        showTextField: false, // ✅ 입력창 숨김
        onConfirm: () {
          Navigator.pop(ctx, true);
        },
      ),
    );

    if (confirmed == true) {
      await playlistService.deletePlaylist(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" 재생목록이 삭제되었습니다.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }



  Widget _playlistDialog(
      BuildContext ctx, {
        required String title,
        required String confirmText,
        TextEditingController? controller, // ✅ optional 로 변경
        VoidCallback? onConfirm,
        bool showTextField = true,         // ✅ 새 파라미터 추가
      }) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: Text(title, style: AppTextStyles.sectionTitle),
      content: SizedBox(
        width: 300,
        child: showTextField
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: TextField(
            controller: controller,
            autofocus: true,
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
        )
            : const SizedBox.shrink(), // ✅ 입력창이 필요 없을 때 비움
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _dialogBtn(ctx, '취소', Colors.grey.shade200, Colors.black,
                    () => Navigator.pop(ctx, false)),
            const SizedBox(width: 10),
            _dialogBtn(ctx, confirmText, AppColors.primary, Colors.white, () {
              onConfirm?.call();
            }),
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

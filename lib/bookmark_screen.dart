import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import 'widget/playlist_dialog.dart';
import 'dart:async';

import 'services/playlist_service.dart';
import 'widget/playlist_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({
    super.key,
    this.onSelectionChanged, // ✅ MainScreen 오버레이 트리거 콜백
    this.onGoToTab,               // ✅ 추가
    this.initialPlaylistId, // ✅ 추가
  });

  final ValueChanged<bool>? onSelectionChanged;
  final ValueChanged<int>? onGoToTab; // ✅ 추가
  final String? initialPlaylistId; // ✅ 추가

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
    } else {
      uid = 'kakao:4424196142';
    }

    playlistService = PlaylistService(uid: uid);

    // 🔹 Firestore 초기화 완료 후 UI 갱신
    createUserIfNotExists(uid).then((_) {
      if (!mounted) return; // ✅ 이미 화면이 사라졌으면 아무것도 하지 않음
      setState(() {});
    });
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
      await userRef.set({'createdAt': FieldValue.serverTimestamp()});
      print('✅ [Firestore] User created: $uid');
    }

    // 🔹 "전체" 재생목록이 없으면 자동 생성
    final playlists = await userRef.collection('playlists')
        .where('name', isEqualTo: '전체')
        .limit(1)
        .get();

    if (playlists.docs.isEmpty) {
      await userRef.collection('playlists').add({
        'name': '전체',
        'songsCount': 0,
        'default': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ [Firestore] Default playlist created: 전체');
    } else {
      print('⚠️ [Firestore] Default playlist already exists');
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isEditing) ...[
            _buildPlaylistChips(),
            const Divider(height: 1, color: Color(0xFFEAEAEA)),
          ],
          Expanded(
            child: isEditing ? _buildEditMode() : _buildNormalMode(),
          ),
        ],
      ),
      floatingActionButton: isEditing ? null : FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () => _showCreatePlaylistDialog(context, playlistService),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ---------------- Normal mode ----------------
  Widget _buildNormalMode() {
    // 선택된 재생목록 ID 가져오기
    final playlists = editingPlaylists;
    if (playlists.isEmpty) {
      return const Center(child: Text('재생목록이 없습니다.'));
    }

    final selectedPlaylist = playlists[selectedPlaylistIndex];
    final selectedPlaylistId = selectedPlaylist['id'];

    // "전체" 선택 시 전체 곡 불러오기 (선택적)
    final songCollection = (selectedPlaylistId == 'all')
        ? FirebaseFirestore.instance.collectionGroup('songs')
        : FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(selectedPlaylistId)
        .collection('songs');

    return StreamBuilder<QuerySnapshot>(
      stream: songCollection.orderBy('addedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final songs = snapshot.data!.docs;
        if (songs.isEmpty) {
          return const Center(child: Text('곡이 없습니다.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: songs.length,
          itemBuilder: (_, i) {
            final title = songs[i]['title'];
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Text('${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                title: Text(title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
                trailing: const Icon(Icons.drag_handle, color: Colors.black54, size: 20),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- Edit mode ----------------
  Widget _buildEditMode() {
    if (editingPlaylists.isEmpty || selectedPlaylistIndex >= editingPlaylists.length) {
      return const Center(child: Text('재생목록이 없습니다.'));
    }

    final playlistId = editingPlaylists[selectedPlaylistIndex]['id'] as String;
    final playlistName = editingPlaylists[selectedPlaylistIndex]['name'] ?? '(이름없음)';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 제목 + 연필(이름수정)
          Row(
            children: [
              Text(playlistName, style: AppTextStyles.headline),
              const SizedBox(width: 6),
              if (playlistName != '전체') GestureDetector(
                onTap: () {
                  final currentName = playlistName;
                  _showRenameDialog(playlistId, currentName);
                },
                child: const Icon(Icons.edit, size: 20, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 🔹 Firestore에서 실시간으로 곡 불러오기
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('playlists')
                  .doc(playlistId)
                  .collection('songs')
                  .orderBy('addedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final songs = snapshot.data!.docs;
                if (songs.isEmpty) {
                  return const Center(child: Text('곡이 없습니다.'));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 전체 선택
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selectedItems.length == songs.length) {
                            selectedItems.clear();
                          } else {
                            selectedItems = Set.from(
                              List<int>.generate(songs.length, (i) => i),
                            );
                          }
                        });
                        _notifySelection();
                      },
                      child: Row(
                        children: [
                          Icon(
                            selectedItems.length == songs.length
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 20,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 6),
                          Text('전체 선택', style: AppTextStyles.button.copyWith(fontSize: 15)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🔹 리스트 (선택/해제)
                    Expanded(
                      child: ListView.builder(
                        itemCount: songs.length,
                        itemBuilder: (_, i) {
                          final data = songs[i].data() as Map<String, dynamic>? ?? {};
                          final title = data['title'] ?? '(제목 없음)';
                          final selected = selectedItems.contains(i);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                selected
                                    ? selectedItems.remove(i)
                                    : selectedItems.add(i);
                              });
                              _notifySelection();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.black12
                                    : Colors.white,
                                border: const Border(
                                    bottom:
                                    BorderSide(color: Color(0xFFEAEAEA))
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${i + 1}', style: AppTextStyles.button.copyWith(fontSize: 14)),
                                  ],
                                ),
                                title: Text(title, style:AppTextStyles.body.copyWith(fontSize: 17, fontWeight:FontWeight.w500)),
                                trailing: const Icon(Icons.drag_handle, color: Colors.black54, size: 20),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 🔹 선택된 항목 삭제 버튼 (선택 시만 표시)
          if (selectedItems.isNotEmpty)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FloatingActionButton.extended(
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: Text('삭제 (${selectedItems.length})',
                      style: const TextStyle(color: Colors.white)),
                  onPressed: () async {
                    // 🔸 PlaylistDialog 형식으로 삭제 확인
                    showDialog(
                      context: context,
                      builder: (ctx) => PlaylistDialog(
                        title: '선택한 ${selectedItems.length}곡을 삭제하시겠습니까?',
                        confirmText: '삭제',
                        showTextField: false, // ✅ 입력창 숨김
                        onConfirm: () async {
                          Navigator.pop(ctx); // 다이얼로그 닫기

                          final collection = FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('playlists')
                              .doc(playlistId)
                              .collection('songs');

                          final docs = await collection.get();
                          for (final i in selectedItems) {
                            if (i < docs.docs.length) {
                              await docs.docs[i].reference.delete();
                            }
                          }

                          setState(() => selectedItems.clear());
                          _notifySelection();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('선택한 곡이 삭제되었습니다.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
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

        // ✅ Firestore에서 받은 원본 데이터
        final data = snapshot.data!;

        // ✅ "전체"를 항상 맨 앞으로 정렬
        data.sort((a, b) {
          if (a['name'] == '전체') return -1;
          if (b['name'] == '전체') return 1;
          return a['name'].compareTo(b['name']);
        });

        // ✅ Firestore에서 새로 들어온 데이터를 원본으로 저장
        originalPlaylists = List<Map<String, dynamic>>.from(data);

        // ✅ 편집모드 아닐 때는 항상 editingPlaylists 동기화
        if (!isEditing) {
          editingPlaylists = List<Map<String, dynamic>>.from(originalPlaylists);
        }

        final playlists = editingPlaylists;

        if (widget.initialPlaylistId != null) {
          final idx = playlists.indexWhere((p) => p['id'] == widget.initialPlaylistId);
          if (idx != -1 && idx != selectedPlaylistIndex) {
            // 🔥 StreamBuilder가 이미 빌드 도중일 수 있으므로
            //   빌드 직후 setState를 예약해야 색상 반영이 안전하게 된다.
            Future.microtask(() {
              if (mounted) {
                setState(() => selectedPlaylistIndex = idx);
              }
            });
          }
        }

        if (selectedPlaylistIndex >= playlists.length) {
          selectedPlaylistIndex = playlists.isEmpty ? 0 : playlists.length - 1;
        }

        if (widget.initialPlaylistId != null) {
          final idx = playlists.indexWhere((p) => p['id'] == widget.initialPlaylistId);
          if (idx != -1 && idx != selectedPlaylistIndex) {
            selectedPlaylistIndex = idx;
          }
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: playlists.map((p) {
              final name = p['name'];
              final selected = name == playlists[selectedPlaylistIndex]['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPlaylistIndex = playlists.indexOf(p);
                  });
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
  void _showCreatePlaylistDialog(BuildContext context, PlaylistService playlistService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => PlaylistDialog(
        title: '새 재생목록',
        confirmText: '추가',
        controller: controller,
        showTextField: true, // ✅ 새 재생목록은 입력 필드 필요
        onConfirm: () async {
          final name = controller.text.trim();
          if (name.isEmpty) return;

          Navigator.pop(ctx);

          await playlistService.addPlaylist(name);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$name" 재생목록이 추가되었습니다.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary,
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
      builder: (ctx) => PlaylistDialog(
        title: '재생목록 이름 수정',
        confirmText: '저장',
        controller: c,
        showTextField: true, // ✅ 이름 수정도 입력창 필요
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
      builder: (ctx) => PlaylistDialog(
        title: '변경사항을 취소할까요?',
        confirmText: '예',
        controller: TextEditingController(),
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
      builder: (ctx) => PlaylistDialog(
        title: '재생목록을 삭제할까요?',
        confirmText: '삭제',
        controller: TextEditingController(),
        showTextField: false,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );

    if (confirmed == true) {
      // ✅ 1. Firestore 삭제 요청은 비동기로 던져두고
      playlistService.deletePlaylist(id); // await 제거

      // ✅ 2. UI를 먼저 일반 모드로 강제 전환
      if (mounted) {
        setState(() {
          isEditing = false;
          selectedPlaylistIndex = 0;
          selectedItems.clear();
        });
      }

      // ✅ 3. Firestore 반영되면 StreamBuilder가 알아서 다시 렌더
      // (이 타이밍은 몇백 ms 늦어도 무관)

      // ✅ 4. 필요시 탭 전환 (MainScreen 콜백)
      widget.onGoToTab?.call(2);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" 재생목록이 삭제되었습니다.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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

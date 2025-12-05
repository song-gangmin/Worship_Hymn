import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import 'widget/playlist_dialog.dart';
import 'dart:async';
import 'score_detail_screen.dart';

import 'services/playlist_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({
    super.key,
    this.onSelectionChanged, // ✅ MainScreen 오버레이 트리거 콜백
    this.onGoToTab,          // ✅ 탭 이동 콜백
    this.initialPlaylistId,  // ✅ 처음에 열 즐겨찾기 ID
  });

  final ValueChanged<bool>? onSelectionChanged;
  final ValueChanged<int>? onGoToTab;
  final String? initialPlaylistId;

  @override
  State<BookmarkScreen> createState() => BookmarkScreenState();
}

class BookmarkScreenState extends State<BookmarkScreen> {
  int selectedPlaylistIndex = 0;

  bool _initialPlaylistApplied = false;

  bool isEditing = false;
  Set<int> selectedItems = {};

  late PlaylistService playlistService;
  String uid = 'test_user';

  List<Map<String, dynamic>> originalPlaylists = [];
  List<Map<String, dynamic>> editingPlaylists = [];

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

    // 🔹 유저별 "전체" 즐겨찾기 보장
    playlistService.ensureDefaultPlaylist();
  }

  // ---- life-cycle ----
  void _notifySelection() {
    widget.onSelectionChanged?.call(selectedItems.isNotEmpty);
  }

  void _clearSelectionAndNotify() {
    selectedItems.clear();
    _notifySelection();
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
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.black),
          onPressed: () {
            setState(() {
              isEditing = false;
              selectedItems.clear();
            });
            _notifySelection();
          },
        )
            : null,
        title: isEditing
            ? const SizedBox.shrink()
            : const Text('즐겨찾기', style: AppTextStyles.headline),
        centerTitle: false,
        actions: [
          if (isEditing &&
              editingPlaylists.isNotEmpty &&
              editingPlaylists[selectedPlaylistIndex]['name'] != '전체')
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 0),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.black87),
                tooltip: '즐겨찾기 삭제',
                onPressed: () {
                  final id = editingPlaylists[selectedPlaylistIndex]['id'];
                  final name = editingPlaylists[selectedPlaylistIndex]['name'];
                  _showDeletePlaylistDialog(id, name);
                },
              ),
            ),
          TextButton(
            onPressed: () {
              // ✅ 편집 중이 아닐 때 → 편집모드 진입
              if (!isEditing) {
                setState(() => isEditing = true);
                return;
              }

              // ✅ 편집 중일 때 → 편집 완료
              setState(() => isEditing = false);
              _clearSelectionAndNotify();

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
          const SizedBox(width: 4),
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
      floatingActionButton: isEditing
          ? null
          : FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () => _showCreatePlaylistDialog(context, playlistService),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ---------------- Normal mode ----------------
  Widget _buildNormalMode() {
    // 즐겨찾기 자체를 Firestore에서 직접 보고 판단
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: playlistService.getPlaylists(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Firestore에서 가져온 즐겨찾기들
        final playlists = List<Map<String, dynamic>>.from(snapshot.data!);

        // "전체"를 항상 맨 앞으로
        playlists.sort((a, b) {
          if (a['name'] == '전체') return -1;
          if (b['name'] == '전체') return 1;
          return (a['name'] as String).compareTo(b['name'] as String);
        });

        // 진짜로 즐겨찾기가 하나도 없을 때만 이 문구
        if (playlists.isEmpty) {
          return const Center(child: Text('즐겨찾기가 없습니다.'));
        }

        // ScoreDetailScreen 에서 넘어온 initialPlaylistId 처리 (처음 한 번만)
        if (!_initialPlaylistApplied && widget.initialPlaylistId != null) {
          final idx =
          playlists.indexWhere((p) => p['id'] == widget.initialPlaylistId);
          if (idx != -1) {
            selectedPlaylistIndex = idx;
          }
          _initialPlaylistApplied = true;
        }

        // 인덱스 범위 보정
        if (selectedPlaylistIndex >= playlists.length) {
          selectedPlaylistIndex = 0;
        }

        final selectedPlaylist = playlists[selectedPlaylistIndex];
        final selectedPlaylistId = selectedPlaylist['id'] as String;

        // 선택된 즐겨찾기의 곡들 가져오기
        final songCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('playlists')
            .doc(selectedPlaylistId)
            .collection('songs');

        return StreamBuilder<QuerySnapshot>(
          stream: songCollection.orderBy('addedAt', descending: true).snapshots(),
          builder: (context, songSnap) {
            if (!songSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final songs = songSnap.data!.docs;
            if (songs.isEmpty) {
              return const Center(child: Text('곡이 없습니다.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: songs.length,
              itemBuilder: (_, i) {
                final data = songs[i].data() as Map<String, dynamic>;
                final title = data['title'] ?? '(제목 없음)';
                final number = (data['number'] ?? 0) as int;

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Text(
                      number.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w400),
                    ),
                    trailing: const Icon(Icons.drag_handle,
                        color: Colors.black54, size: 20),
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
              },
            );
          },
        );
      },
    );
  }

  // ---------------- Edit mode ----------------
  Widget _buildEditMode() {
    if (editingPlaylists.isEmpty ||
        selectedPlaylistIndex >= editingPlaylists.length) {
      return const Center(child: Text('즐겨찾기가 없습니다.'));
    }

    final playlistId = editingPlaylists[selectedPlaylistIndex]['id'] as String;
    final playlistName =
        editingPlaylists[selectedPlaylistIndex]['name'] ?? '(이름없음)';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 연필(이름수정)
          Row(
            children: [
              Text(playlistName, style: AppTextStyles.headline),
              const SizedBox(width: 6),
              if (playlistName != '전체')
                GestureDetector(
                  onTap: () {
                    final currentName = playlistName;
                    _showRenameDialog(playlistId, currentName);
                  },
                  child: const Icon(Icons.edit,
                      size: 20, color: Colors.black54),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Firestore에서 실시간으로 곡 불러오기
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
                    // 전체 선택
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
                          Text('전체 선택',
                              style: AppTextStyles.button
                                  .copyWith(fontSize: 15)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 리스트 (선택/해제)
                    Expanded(
                      child: ListView.builder(
                        itemCount: songs.length,
                        itemBuilder: (_, i) {
                          final data = songs[i].data() as Map<String, dynamic>? ??
                              {};
                          final number = data['number'] as int? ?? 0;
                          final title =
                              data['title'] as String? ?? '(제목 없음)';
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
                                color:
                                selected ? Colors.black12 : Colors.white,
                                border: const Border(
                                  bottom:
                                  BorderSide(color: Color(0xFFEAEAEA)),
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      number.toString(),
                                      style: AppTextStyles.button
                                          .copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  title,
                                  style: AppTextStyles.body.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500),
                                ),
                                trailing: const Icon(Icons.drag_handle,
                                    color: Colors.black54, size: 20),
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

          // 선택된 항목 삭제 버튼
          if (selectedItems.isNotEmpty)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FloatingActionButton.extended(
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: Text(
                    '삭제 (${selectedItems.length})',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (ctx) => PlaylistDialog(
                        title: '선택한 ${selectedItems.length}곡을 삭제하시겠습니까?',
                        confirmText: '삭제',
                        showTextField: false,
                        onConfirm: () async {
                          Navigator.pop(ctx); // 다이얼로그 닫기

                          final collection = FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('playlists')
                              .doc(playlistId)
                              .collection('songs');

                          final docsSnap = await collection.get();
                          final docs = docsSnap.docs;

                          final targets = selectedItems
                              .where((i) => i < docs.length)
                              .map((i) => docs[i])
                              .toList();

                          for (final doc in targets) {
                            final data =
                            doc.data() as Map<String, dynamic>;
                            final number =
                            (data['number'] ?? 0) as int;

                            await playlistService.deleteSongFromPlaylist(
                              playlistId: playlistId,
                              hymnNumber: number,
                            );
                          }

                          setState(() {
                            selectedItems.clear();
                          });
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

        final data = snapshot.data!;

        // "전체"를 항상 맨 앞으로 정렬
        data.sort((a, b) {
          if (a['name'] == '전체') return -1;
          if (b['name'] == '전체') return 1;
          return a['name'].compareTo(b['name']);
        });

        originalPlaylists = List<Map<String, dynamic>>.from(data);

        if (!isEditing) {
          editingPlaylists =
          List<Map<String, dynamic>>.from(originalPlaylists);
        }

        final playlists = editingPlaylists;

        if (widget.initialPlaylistId != null &&
            !_initialPlaylistApplied) {
          final idx =
          playlists.indexWhere((p) => p['id'] == widget.initialPlaylistId);

          if (idx != -1) {
            Future.microtask(() {
              if (mounted) {
                setState(() {
                  selectedPlaylistIndex = idx;
                });
              }
            });
          }
          _initialPlaylistApplied = true;
        }

        if (selectedPlaylistIndex >= playlists.length) {
          selectedPlaylistIndex =
          playlists.isEmpty ? 0 : playlists.length - 1;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: playlists.map((p) {
              final name = p['name'];
              final selected =
                  name == playlists[selectedPlaylistIndex]['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPlaylistIndex = playlists.indexOf(p);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
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
  void _showCreatePlaylistDialog(
      BuildContext context, PlaylistService playlistService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => PlaylistDialog(
        title: '새 즐겨찾기',
        confirmText: '추가',
        controller: controller,
        showTextField: true,
        onConfirm: () async {
          final name = controller.text.trim();
          if (name.isEmpty) return;

          Navigator.pop(ctx);

          await playlistService.addPlaylist(name);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$name" 즐겨찾기가 추가되었습니다.'),
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
        title: '즐겨찾기 이름 수정',
        confirmText: '저장',
        controller: c,
        showTextField: true,
        onConfirm: () async {
          final newName = c.text.trim();
          if (newName.isEmpty) {
            Navigator.pop(ctx);
            return;
          }

          Navigator.pop(ctx);

          await playlistService.renamePlaylist(id, newName);

          if (!mounted) return;
          setState(() {
            final index =
            editingPlaylists.indexWhere((p) => p['id'] == id);
            if (index != -1) {
              editingPlaylists[index]['name'] = newName;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('즐겨찾기 제목이 변경되었습니다.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }


  Future<void> _showDeletePlaylistDialog(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PlaylistDialog(
        title: '즐겨찾기를 삭제할까요?',
        confirmText: '삭제',
        controller: TextEditingController(),
        showTextField: false,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );

    if (confirmed == true) {
      await playlistService.deletePlaylist(id);

      if (mounted) {
        setState(() {
          isEditing = false;
          selectedPlaylistIndex = 0;
          selectedItems.clear();
        });
      }

      widget.onGoToTab?.call(2);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" 즐겨찾기가 삭제되었습니다.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ---------------- External actions (MainScreen에서 호출 가능) ----------------
  /// MainScreen에서 overlay 삭제 버튼으로 사용할 수도 있는 메서드
  Future<void> deleteSelected() async {
    if (!isEditing || selectedItems.isNotEmpty == false) return;
    if (editingPlaylists.isEmpty ||
        selectedPlaylistIndex >= editingPlaylists.length) return;

    final playlistId = editingPlaylists[selectedPlaylistIndex]['id'] as String;

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistId)
        .collection('songs');

    final docsSnap = await collection.get();
    final docs = docsSnap.docs;

    final targets = selectedItems
        .where((i) => i < docs.length)
        .map((i) => docs[i])
        .toList();

    for (final doc in targets) {
      final data = doc.data() as Map<String, dynamic>;
      final number = (data['number'] ?? 0) as int;

      await playlistService.deleteSongFromPlaylist(
        playlistId: playlistId,
        hymnNumber: number,
      );
    }

    if (!mounted) return;
    setState(() {
      selectedItems.clear();
    });
    _notifySelection();
  }
}

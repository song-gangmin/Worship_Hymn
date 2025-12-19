import 'package:flutter/material.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/constants/text_styles.dart';
import 'package:worship_hymn/widget/playlist_dialog.dart';
import 'dart:async';
import 'package:worship_hymn/screens/score/score_detail_screen.dart';
import 'dart:ui' show FontFeature;


import 'package:worship_hymn/services/playlist_service.dart';
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
  final Set<String> _deletingSongIds = {};
  int selectedPlaylistIndex = 0;

  bool _initialPlaylistApplied = false;

  bool isEditing = false;
  Set<int> selectedItems = {};

  late PlaylistService playlistService;
  late String uid;

  List<Map<String, dynamic>> originalPlaylists = [];
  List<Map<String, dynamic>> editingPlaylists = [];

  // 🔥 순서 변경 시 부드러운 UI 연출을 위한 로컬 버퍼
  List<QueryDocumentSnapshot>? _reorderedSongs;
  Timer? _reorderTimer;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated');
    }
    uid = currentUser.uid;

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
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: isEditing
            ? IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 20, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
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
            : Text('즐겨찾기', style: AppTextStyles.headline(context)),
        centerTitle: false,
        actions: [
          if (isEditing &&
              editingPlaylists.isNotEmpty &&
              editingPlaylists[selectedPlaylistIndex]['name'] != '전체')
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 0),
              child: IconButton(
                icon: Icon(Icons.delete_outline, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
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

              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('변경사항이 저장되었습니다.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                });
              }
            },
            child: Text(
              isEditing ? '완료' : '편집',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: AppTextStyles.font(context).applySize(14),
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
            const SizedBox(height: 16),
          ],
          Expanded(
            child: isEditing ? _buildEditMode() : _buildNormalMode(),
          ),
        ],
      ),
      floatingActionButton: isEditing
          ? null
          : FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
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
          // 🔥 모든 곡을 가져온 뒤 로컬에서 정렬 (order 필드가 없는 데이터가 누락되는 것 방지)
          stream: songCollection.snapshots(),
          builder: (context, songSnap) {
            if (!songSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // 1. 원본 데이터 가져오기 및 정렬
            List<QueryDocumentSnapshot> rawDocs;

            if (_reorderedSongs != null) {
              // 🔥 사용자가 방금 순서를 바꿨다면 로컬 버퍼 데이터를 우선 사용 (snapping 방지)
              rawDocs = List<QueryDocumentSnapshot>.from(_reorderedSongs!);
            } else {
              rawDocs = List<QueryDocumentSnapshot>.from(songSnap.data!.docs);
              // 🔥 로컬 정렬: order 기준, 없으면 addedAt 기준
              rawDocs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aOrder = aData['order'] ?? (aData['addedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                final bOrder = bData['order'] ?? (bData['addedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                return aOrder.compareTo(bOrder);
              });
            }

            // 2. 삭제 중인 ID(_deletingSongIds) 제외
            final songs = rawDocs
                .where((doc) => !_deletingSongIds.contains(doc.id))
                .toList();

            if (songs.isEmpty) {
              return const Center(child: Text('곡이 없습니다.'));
            }

            return ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: songs.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;

                // 🔥 1. 로컬 상태 즉시 업데이트 (프레임워크 애니메이션과 동기화)
                setState(() {
                  final list = List<QueryDocumentSnapshot>.from(songs);
                  final moved = list.removeAt(oldIndex);
                  list.insert(newIndex, moved);
                  _reorderedSongs = list;

                  // 4초 동안은 서버 스트림보다 로컬 데이터를 우선시함 (안정성)
                  _reorderTimer?.cancel();
                  _reorderTimer = Timer(const Duration(seconds: 4), () {
                    if (mounted) {
                      setState(() {
                        _reorderedSongs = null;
                      });
                    }
                  });
                });

                // 🔥 2. Firestore Batch 저장 (비동기로 백그라운드에서 실행)
                final listToSave = List<QueryDocumentSnapshot>.from(_reorderedSongs!);
                Future.microtask(() async {
                  try {
                    final batch = FirebaseFirestore.instance.batch();
                    for (int i = 0; i < listToSave.length; i++) {
                      batch.update(listToSave[i].reference, {'order': i});
                    }
                    await batch.commit();
                    debugPrint(">>> 즐겨찾기 순서 변경 Firestore 반영 완료");
                  } catch (e) {
                    debugPrint(">>> 즐겨찾기 순서 변경 Firestore 반영 에러: $e");
                  }
                });
              },
              itemBuilder: (_, i) {
                final doc = songs[i]; // 현재 문서 객체
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? '(제목 없음)';
                final number = (data['number'] ?? 0) as int;
                final docId = doc.id; // 문서 ID

                return ReorderableDelayedDragStartListener(
                  key: ValueKey(docId),
                  index: i,
                  child: Dismissible(
                    key: ValueKey("dismiss_$docId"),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      setState(() {
                        _deletingSongIds.add(docId);
                      });
                      try {
                        if (selectedPlaylist['name'] == '전체') {
                          await _deleteSongFromAllPlaylists(number);
                        } else {
                          await playlistService.deleteSongFromPlaylist(
                            playlistId: selectedPlaylistId,
                            hymnNumber: number,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _deletingSongIds.remove(docId);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('삭제 중 오류가 발생했습니다.')),
                          );
                        }
                      }
                    },
                    child: Container(
                      key: ValueKey("tile_$docId"),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: SizedBox(
                          width: 40,
                          child: Text(
                            number.toString(),
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: AppTextStyles.font(context).applySize(16),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        title: Text(
                          title,
                          style: AppTextStyles.body(context).copyWith(
                            fontSize: AppTextStyles.font(context).applySize(17),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(Icons.drag_handle,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54, size: 20),
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
                    ),
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
              Text(playlistName, style: AppTextStyles.headline(context)),
              const SizedBox(width: 6),
              if (playlistName != '전체')
                GestureDetector(
                  onTap: () {
                    final currentName = playlistName;
                    _showRenameDialog(playlistId, currentName);
                  },
                  child: Icon(Icons.edit,
                      size: 20, color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54),
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
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: 6),
                          Text('전체 선택',
                              style: AppTextStyles.button(context)
                                  .copyWith(fontSize: AppTextStyles.font(context).applySize(15))),
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
                                selected 
                                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12) 
                                    : AppColors.getSurface(context),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12,
                                    width: 0.5,
                                  ),
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
                                      style: AppTextStyles.button(context)
                                          .copyWith(fontSize: AppTextStyles.font(context).applySize(14)),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  title,
                                  style: AppTextStyles.body(context).copyWith(
                                      fontSize: AppTextStyles.font(context).applySize(17),
                                      fontWeight: FontWeight.w500),
                                ),
                                trailing: Icon(Icons.drag_handle,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54, size: 20),
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
                  backgroundColor: Theme.of(context).primaryColor,
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
                            final data = doc.data() as Map<String, dynamic>;
                            final number = (data['number'] ?? 0) as int;

                            // ✅ '전체' 재생목록에서 삭제할 때는
                            //    모든 재생목록에서 해당 곡을 같이 삭제
                            if (playlistName == '전체') {
                              await _deleteSongFromAllPlaylists(number);
                            } else {
                              // ✅ 일반 재생목록에서는 기존처럼 해당 리스트에서만 삭제
                              await playlistService.deleteSongFromPlaylist(
                                playlistId: playlistId,
                                hymnNumber: number,
                              );
                            }
                          }

                          setState(() {
                            selectedItems.clear();
                          });
                          _notifySelection();

                          if (mounted) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('선택한 곡이 삭제되었습니다.'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            });
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
                    color: selected ? Theme.of(context).primaryColor : AppColors.getSurface(context),
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
                      color: selected 
                          ? Colors.white 
                          : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.w500,
                      fontSize: AppTextStyles.font(context).applySize(15),
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

          try {
            await playlistService.addPlaylist(name);

            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$name" 즐겨찾기가 추가되었습니다.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                );
              });
            }
          } on StateError catch (e) {
            // 🔥 중복 이름일 때
            if (e.message == 'DUPLICATE_PLAYLIST_NAME') {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('이미 같은 이름의 즐겨찾기가 있습니다.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                });
              }
            }
          }
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

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$name" 즐겨찾기가 삭제되었습니다.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        });
      }
    }
  }

  // ---------------- External actions (MainScreen에서 호출 가능) ----------------
  /// MainScreen에서 overlay 삭제 버튼으로 사용할 수도 있는 메서드
  Future<void> deleteSelected() async {
    if (!isEditing || selectedItems.isNotEmpty == false) return;
    if (editingPlaylists.isEmpty ||
        selectedPlaylistIndex >= editingPlaylists.length) return;

    final playlist = editingPlaylists[selectedPlaylistIndex];
    final playlistId   = playlist['id'] as String;
    final playlistName = (playlist['name'] ?? '') as String;

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

      if (playlistName == '전체') {
        // 🔥 전체에서 지우면 모든 재생목록 + count도 같이 정리
        await _deleteSongFromAllPlaylists(number);
      } else {
        // 🔥 일반 재생목록에서만 지울 때
        await playlistService.deleteSongFromPlaylist(
          playlistId: playlistId,
          hymnNumber: number,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      selectedItems.clear();
    });
    _notifySelection();
  }

  Future<void> _deleteSongFromAllPlaylists(int hymnNumber) async {
    final playlistsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('playlists');

    // 1) 유저의 모든 플레이리스트 가져오기
    final playlistsSnap = await playlistsRef.get();

    for (final plDoc in playlistsSnap.docs) {
      final songsRef = plDoc.reference.collection('songs');

      // 2) 해당 번호(hymnNumber)를 가진 곡 찾기
      final toDeleteSnap = await songsRef
          .where('number', isEqualTo: hymnNumber)
          .get();

      if (toDeleteSnap.docs.isEmpty) continue;

      // 3) 곡 문서 삭제
      for (final songDoc in toDeleteSnap.docs) {
        await songDoc.reference.delete();
      }

      // 4) 🔥 실제 남아 있는 곡 개수를 다시 세서 count에 그대로 넣기
      final afterSnap = await songsRef.get();
      await plDoc.reference.update({
        'count': afterSnap.size,   // <= 여기서 정확히 맞춰준다
      });
    }
  }

}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:worship_hymn/services/playlist_service.dart';
import 'package:worship_hymn/screens/main/main_screen.dart';
import 'package:worship_hymn/constants/text_styles.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/widget/playlist_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:worship_hymn/services/recent_service.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:worship_hymn/services/global_stats_service.dart';
import 'package:worship_hymn/constants/title_hymns.dart';

class ScoreDetailScreen extends StatefulWidget {
  final int hymnNumber;
  final String hymnTitle;

  const ScoreDetailScreen({
    super.key,
    required this.hymnNumber,
    required this.hymnTitle,
  });

  @override
  State<ScoreDetailScreen> createState() => _ScoreDetailScreenState();
}

class _ScoreDetailScreenState extends State<ScoreDetailScreen> {
  static const int _minHymn = 1;
  static const int _maxHymn = 588;

  late int _current;
  late PageController _pageController;

  bool _controlsVisible = true;
  bool _isFullscreen = false;
  bool _isBookmarked = false;

  String? _defaultPlaylistId; // ✅ '전체' 플레이리스트 id


  late String uid;
  late PlaylistService playlistService;
  late RecentService recentService;
  late GlobalStatsService globalService;

  String get _assetPath => 'assets/scores/page_$_current.webp';

  String get hymnNumberLabel => '${_current}장';

  String get _currentHymnTitle {
    // 1. 전체 문자열 가져오기 (예: "1장 만복의 근원 하나님")
    final raw = hymnTitles[_current - 1];

    // 2. 첫 번째 공백 찾기
    final splitIndex = raw.indexOf(' ');

    // 3. 공백 다음부터 끝까지 자르기 (예: "만복의 근원 하나님")
    return raw.substring(splitIndex + 1);
  }
  @override
  void initState() {
    super.initState();
    _current = widget.hymnNumber.clamp(_minHymn, _maxHymn);
    _pageController = PageController(initialPage: _current - 1);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated');
    }
    uid = currentUser.uid;
    playlistService = PlaylistService(uid: uid);
    recentService = RecentService(uid: uid);
    globalService = GlobalStatsService();

    _loadBookmarkState();

    _recordView();

    _recordUserRecent();
  }

  Future<void> _loadBookmarkState() async {
    try {
      // 1) 플레이리스트 목록에서 '전체' 찾기
      final playlists = await playlistService.getPlaylists().first;
      Map<String, dynamic>? defaultPlaylist;

      for (final p in playlists) {
        if (p['name'] == '전체') {
          defaultPlaylist = p;
          break;
        }
      }

      if (defaultPlaylist == null) return;

      _defaultPlaylistId = defaultPlaylist['id'] as String;

      // 2) '전체' 플레이리스트의 songs 에 현재 곡이 있는지 확인
      final songsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('playlists')
          .doc(_defaultPlaylistId)
          .collection('songs')
          .where('number', isEqualTo: _current)
          .limit(1)
          .get();

      if (!mounted) return;

      setState(() {
        _isBookmarked = songsSnap.docs.isNotEmpty;
      });
    } catch (_) {
      // 에러는 조용히 무시 (아이콘만 회색으로 두면 됨)
    }
  }
  Future<void> _removeFromDefaultBookmark() async {
    try {
      final playlistsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('playlists');

      // 1) 유저의 모든 플레이리스트 가져오기
      final playlistsSnap = await playlistsRef.get();

      for (final plDoc in playlistsSnap.docs) {
        final songsRef = plDoc.reference.collection('songs');

        // 2) 이 플레이리스트 안에서 현재 곡(_current) 찾아서
        final toDeleteSnap =
        await songsRef.where('number', isEqualTo: _current).get();

        if (toDeleteSnap.docs.isEmpty) continue;

        // 3) 곡 문서 삭제
        for (final songDoc in toDeleteSnap.docs) {
          await songDoc.reference.delete();
        }

        // 4) 남아 있는 곡 개수 다시 세서 count에 정확히 반영
        final afterSnap = await songsRef.get();
        await plDoc.reference.update({
          'count': afterSnap.size,
        });
      }

      if (!mounted) return;

      setState(() => _isBookmarked = false);

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('즐겨찾기에서 삭제되었습니다.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('즐겨찾기 삭제 중 오류가 발생했습니다.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    }
  }

  Future<void> _askGoToBookmark(String playlistId) async {
    final shouldMove = await showDialog<bool>(
      context: context,
      builder: (ctx) => PlaylistDialog(
        title: '즐겨찾기로 이동할까요?',
        confirmText: '이동',
        controller: TextEditingController(),
        showTextField: false,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );

    if (shouldMove == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(
            initialTabIndex: 2,
            initialPlaylistId: playlistId,
          ),
        ),
            (route) => false,
      );
    }
  }

  Future<void> _recordUserRecent() async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recent_views')
        .doc(_current.toString());

    await ref.set({
      'number': _current,
      'title': _currentHymnTitle,
      'viewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _recordView() async {
    final today = DateTime.now();
    final dateKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final ref = FirebaseFirestore.instance
        .collection('global_stats')
        .doc(_current.toString());

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        txn.set(ref, {
          'number': _current,
          'title': _currentHymnTitle,
          'weeklyCount': 1,
          'dailyHistory': {dateKey: 1},
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        final data = snap.data()!;
        final daily = Map<String, dynamic>.from(data['dailyHistory'] ?? {});

        daily[dateKey] = (daily[dateKey] ?? 0) + 1;

        txn.update(ref, {
          'weeklyCount': FieldValue.increment(1),
          'dailyHistory': daily,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }


  void _toggleControls() => setState(() => _controlsVisible = !_controlsVisible);

  void _onPageChanged(int index) {
    setState(() {
      _current = index + 1;
    });
    _loadBookmarkState();
    _recordView();
    _recordUserRecent();
  }

  void _nextPage() {
    if (_current < _maxHymn) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_current > _minHymn) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  ///  🎵  곡을 선택한 즐겨찾기 + 전체 즐겨찾에 추가하는 메인 로직
  Future<void> _addSongSmart(String playlistId, String playlistName) async {
    try {
      await playlistService.addSongSmart(
        playlistId: playlistId,
        hymnNumber: _current,
        title: _currentHymnTitle,
      );

      if (!mounted) return;

      setState(() => _isBookmarked = true);

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$playlistName"에 곡이 추가되었습니다.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).primaryColor,
            ),
          );
        });
      }
      await _askGoToBookmark(playlistId);
    } on StateError catch (e) {
      if (!mounted) return;
      if (e.message == 'DUPLICATE_SONG_IN_PLAYLIST') {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이미 즐겨찾기에 포함되어 있습니다.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          });
        }
      } else {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('곡 추가 실패: ${e.message}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('곡 추가 중 오류가 발생했습니다.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    }
  }

  /// 즐겨찾기 선택 bottom sheet (전체는 선택지에서 제거)
  void _showBookmarkBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: playlistService.getPlaylists().first,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final playlists = snapshot.data!
                .where((p) => p['name'] != '전체')
                .toList();

            // 👇 1개당 예상 높이
            const tileHeight = 60.0;
            const headerHeight = 120.0; // 상단 타이틀 + 패딩
            const bottomButtonHeight = 70.0;

            // 🔥 바텀시트가 차지할 실제 높이 계산
            double totalHeight =
                headerHeight + (playlists.length * tileHeight) + bottomButtonHeight;

            // 🔥 최대 높이 제한 (예: 화면의 60%)
            final maxHeight = MediaQuery.of(context).size.height * 0.6;

            if (totalHeight > maxHeight) {
              totalHeight = maxHeight;
            }

            return Container(
              height: totalHeight,
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // ===== 상단 바 =====
                  const SizedBox(height: 16),
                  Container(
                    width: 100,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '즐겨찾기에 1곡 추가',
                        style: AppTextStyles.sectionTitle(context).copyWith(fontSize: 22),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ===== 목록 부분 =====
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: playlists.length,
                      itemBuilder: (_, i) {
                        final p = playlists[i];
                        return ListTile(
                          title: Text(
                            p['name'],
                            style: AppTextStyles.body(context).copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${p['count'] ?? 0}곡',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            await _addSongSmart(p['id'], p['name']);
                          },
                        );
                      },
                    ),
                  ),

                  // ===== 새 즐겨찾기 버튼 =====
                  Padding(
                    padding: const EdgeInsets.only(right: 20, bottom: 20),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showCreatePlaylistDialog();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, color: Colors.white, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '새 즐겨찾기',
                                style: AppTextStyles.sectionTitle(context).copyWith(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  ///  🔧 새 즐겨찾기 생성
  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => PlaylistDialog(
        title: '새 즐겨찾기',
        confirmText: '추가',
        controller: controller,
        onConfirm: () async {
          final name = controller.text.trim();
          if (name.isEmpty) return;

          Navigator.pop(ctx);

          try {
            final newId = await playlistService.addPlaylist(name.trim());
            await _addSongSmart(newId, name);
          } on StateError catch (e) {
            if (e.message == 'DUPLICATE_PLAYLIST_NAME') {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('이미 동일한 즐겨찾기가 있습니다.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              rethrow;
            }
          }
          catch (e) {
            // 그 외 에러
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('오류가 발생했습니다.')),
            );
          }
        },
      ),
    );
  }


  /// UI
  @override
  Widget build(BuildContext context) {
    final appBar = _isFullscreen
        ? null
        : AppBar(
          backgroundColor: AppColors.getSurface(context),
          elevation: 0,
          centerTitle: true,
          // 🔹 제목: "302장" 형식
          title: Text(hymnNumberLabel, style: AppTextStyles.sectionTitle(context)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isBookmarked 
                    ? Theme.of(context).primaryColor 
                    : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
              ),
              onPressed: () async {
                if (_isBookmarked) {
                  // ✅ 이미 북마크인 경우 → 다시 누르면 삭제
                  await _removeFromDefaultBookmark();
                } else {
                  // ✅ 아직 북마크가 아닌 경우 → 바텀시트 열어서 플레이리스트 선택
                  _showBookmarkBottomSheet(context);
                }
              },
            ),
          ],
        );

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: appBar,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _toggleControls, // 🔥 화면 어디든 탭하면 토글 온/오프
        child: Stack(
          children: [
            // 🔍 확대 가능한 악보 (갤러리 형태)
            Positioned.fill(
              child: PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: AssetImage('assets/scores/page_${index + 1}.webp'),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.contained * 4.0,
                  );
                },
                itemCount: _maxHymn,
                loadingBuilder: (context, event) => const Center(
                  child: CircularProgressIndicator(),
                ),
                backgroundDecoration: BoxDecoration(
                  color: AppColors.getBackground(context),
                ),
                pageController: _pageController,
                onPageChanged: _onPageChanged,
              ),
            ),

            // ⬅️ 왼쪽 화살표
            if (_controlsVisible)
              Positioned(
                left: 6,
                top: MediaQuery.of(context).size.height * 0.45,
                child: _arrowButton(
                  icon: Icons.chevron_left,
                  onTap: _prevPage,
                ),
              ),

            // ➡️ 오른쪽 화살표
            if (_controlsVisible)
              Positioned(
                right: 6,
                top: MediaQuery.of(context).size.height * 0.45,
                child: _arrowButton(
                  icon: Icons.chevron_right,
                  onTap: _nextPage,
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _arrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
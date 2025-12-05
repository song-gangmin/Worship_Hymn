import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/playlist_service.dart';
import 'bookmark_screen.dart';
import 'main_screen.dart';
import 'constants/text_styles.dart';
import 'constants/colors.dart';
import 'widget/playlist_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'recent_service.dart';
import 'global_stats_service.dart';

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
  final TransformationController _controller = TransformationController();

  bool _canPan = false; // 🔥 기본 상태: 드래그 불가

  static const int _minHymn = 1;
  static const int _maxHymn = 588;

  late int _current;

  bool _controlsVisible = true;
  bool _isFullscreen = false;
  bool _isBookmarked = false;

  late String uid;
  late PlaylistService playlistService;
  late RecentService recentService;
  late GlobalStatsService globalService;

  late Offset _doubleTapPosition;

  String get _assetPath => 'assets/scores/page_$_current.png';

  String get hymnNumberLabel => '${_current}장';

  String get hymnTitle => widget.hymnTitle;

  @override
  void initState() {
    super.initState();
    _current = widget.hymnNumber.clamp(_minHymn, _maxHymn);

    final currentUser = FirebaseAuth.instance.currentUser;
    uid = currentUser?.uid ?? 'kakao:4424196142';
    playlistService = PlaylistService(uid: uid);
    recentService = RecentService(uid: uid);
    globalService = GlobalStatsService();

    _recordView();

    _recordUserRecent();

    _controller.addListener(() {
      final scale = _controller.value.getMaxScaleOnAxis();

      // 🔥 확대 상태 → 드래그 가능
      if (scale > 1.0 && !_canPan) {
        setState(() {
          _canPan = true;
        });
      }

      // 🔥 다시 축소되어 1.0 이하 → 드래그 금지 + 원위치 복귀
      if (scale <= 1.0 && _canPan) {
        setState(() {
          _canPan = false;
          _resetPosition();
        });
      }
    });
  }

  Future<void> _recordUserRecent() async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recent_views')
        .doc(_current.toString());

    await ref.set({
      'number': _current,
      'title': hymnTitle,
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
          'title': hymnTitle,
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

  void _zoomInAt(Offset position) {
    final zoom = 2.2; // 원하는 확대 비율

    final x = -position.dx * (zoom - 1);
    final y = -position.dy * (zoom - 1);

    setState(() {
      _controller.value = Matrix4.identity()
        ..translate(x, y)
        ..scale(zoom);
    });
  }

  void _resetPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.value = Matrix4.identity(); // 원래 위치 & 크기
    });
  }

  void _nextPage() {
    if (_current < _maxHymn) {
      setState(() => _current++);
    }
  }

  void _prevPage() {
    if (_current > _minHymn) {
      setState(() => _current--);
    }
  }

  ///  🎵  곡을 선택한 즐겨찾기 + 전체 즐겨찾에 추가하는 메인 로직
  Future<void> _addSongSmart(String playlistId, String playlistName) async {
    try {
      await playlistService.addSongSmart(
        playlistId: playlistId,
        hymnNumber: _current,
        title: hymnTitle,
      );

      if (!mounted) return;

      setState(() => _isBookmarked = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$playlistName"에 곡이 추가되었습니다.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );

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
    } on StateError catch (e) {
      if (!mounted) return;
      if (e.message == 'DUPLICATE_SONG_IN_PLAYLIST') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미 즐겨찾기에 포함되어 있습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('곡 추가 실패: ${e.message}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('곡 추가 중 오류가 발생했습니다.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        style: AppTextStyles.sectionTitle.copyWith(fontSize: 22),
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
                            style: AppTextStyles.body.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${p['count'] ?? 0}곡',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
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
                          _showCreatePlaylistDialog(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
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
                                style: AppTextStyles.sectionTitle.copyWith(
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
  void _showCreatePlaylistDialog(BuildContext context) {
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
            final newId = await playlistService.addPlaylist(name);
            await _addSongSmart(newId, name);
          } on StateError catch (e) {
            if (e.message == 'DUPLICATE_PLAYLIST_NAME') {
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
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          // 🔹 제목: "302장" 형식
          title: Text(hymnNumberLabel, style: AppTextStyles.sectionTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isBookmarked ? AppColors.primary : Colors.black87,
              ),
              onPressed: () => _showBookmarkBottomSheet(context),
            ),
          ],
        );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _toggleControls, // 🔥 화면 어디든 탭하면 토글 온/오프
        onDoubleTapDown: (details) {
          _doubleTapPosition = details.localPosition;
        },
        onDoubleTap: () {
          final scale = _controller.value.getMaxScaleOnAxis();

          if (scale > 1.0) {
            // 🔹 이미 확대 상태 → 다시 기본으로 초기화
            _controller.value = Matrix4.identity();
          } else {
            // 🔹 기본 상태 → 더블탭한 지점을 중심으로 확대
            _zoomInAt(_doubleTapPosition);
          }
        },
        child: Stack(
          children: [
            // 🔍 확대 가능한 악보
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _controller,   // 🔥 추가
                panEnabled: _canPan,
                scaleEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(80),
                child: Image.asset(
                  'assets/scores/page_$_current.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('악보 이미지를 찾을 수 없습니다.'),
                  ),
                ),
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

            // 🖥 전체화면 토글 버튼 (오른쪽 하단)
            if (_controlsVisible)
              Positioned(
                right: 20,
                top: kToolbarHeight + 16,
                child: _fullscreenButton(),
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
  Widget _fullscreenButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFullscreen = !_isFullscreen;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
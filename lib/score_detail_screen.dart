import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/playlist_service.dart';
import 'bookmark_screen.dart';
import 'constants/text_styles.dart';
import 'constants/colors.dart';
import 'widget/playlist_dialog.dart';

class ScoreDetailScreen extends StatefulWidget {
  final int hymnNumber;
  const ScoreDetailScreen({super.key, required this.hymnNumber});

  @override
  State<ScoreDetailScreen> createState() => _ScoreDetailScreenState();
}

class _ScoreDetailScreenState extends State<ScoreDetailScreen> {
  static const int _minHymn = 1;
  static const int _maxHymn = 588;

  late int _current;
  bool _chromeVisible = true;
  bool _overlayVisible = false;
  bool _isBookmarked = false;

  final String uid = 'test_user'; // 나중에 Auth UID 교체
  late PlaylistService playlistService;

  String get _assetPath => 'assets/scores/page_$_current.png';
  String get hymnTitle => '$_current장';

  @override
  void initState() {
    super.initState();
    _current = widget.hymnNumber.clamp(_minHymn, _maxHymn);
    playlistService = PlaylistService(uid: uid);
  }

  void _toggleOverlay() => setState(() => _overlayVisible = !_overlayVisible);
  void _toggleFullscreen() => setState(() => _chromeVisible = !_chromeVisible);
  void _goPrev() => setState(() => _current > _minHymn ? _current-- : _current);
  void _goNext() => setState(() => _current < _maxHymn ? _current++ : _current);

  /// ✅ BottomSheet (재생목록 선택)
  void showBookmarkBottomSheet(BuildContext context, String hymnTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: playlistService.getPlaylists().first,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final playlists = [
              {'id': 'all', 'name': '전체'},
              ...snapshot.data!,
            ];

            // ✅ 높이 동적 계산
            final itemHeight = 60.0;
            final maxHeight = MediaQuery.of(context).size.height * 0.8;
            final desiredHeight = (playlists.length * itemHeight) + 160;
            final sheetHeight = desiredHeight.clamp(250.0, maxHeight);

            return FractionallySizedBox(
              heightFactor: sheetHeight / MediaQuery.of(context).size.height,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 16, 60),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 100,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '즐겨찾기에 1곡 추가',
                              style: AppTextStyles.sectionTitle.copyWith(fontSize: 22),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ✅ 재생목록 리스트
                          Flexible(
                            child: ListView.builder(
                              itemCount: playlists.length,
                              itemBuilder: (_, i) {
                                final p = playlists[i];
                                return ListTile(
                                  dense: true,
                                  title: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: p['name'],
                                          style: AppTextStyles.body.copyWith(
                                            color: Colors.black,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const WidgetSpan(child: SizedBox(width: 4)),
                                        TextSpan(
                                          text: '${p['count'] ?? 0}곡',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () async {
                                    if (p['id'] != 'all') {
                                      await _addSongToPlaylist(p['id'], hymnTitle);
                                      setState(() => _isBookmarked = true);
                                    }

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      // ✅ BookmarkScreen으로 이동 (선택한 재생목록 보여주기)
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BookmarkScreen(),
                                        ),
                                      );
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('"${p['name']}"에 추가되었습니다.'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: AppColors.primary,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ 오른쪽 하단 새 재생목록 버튼
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 20),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showCreatePlaylistDialog(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              ),
            );
          },
        );
      },
    );
  }

  /// ✅ 새 재생목록 생성 다이얼로그
  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => PlaylistDialog(
        title: '새 재생목록',
        confirmText: '추가',
        controller: controller,
        onConfirm: () async {
          final name = controller.text.trim();
          if (name.isEmpty) return;

          Navigator.pop(ctx);

          try {
            // ⬇️ 새 재생목록 문서 id를 받음
            final newId = await playlistService.addPlaylist(name);

            // ⬇️ 방금 만든 재생목록에 현재 곡 추가
            await playlistService.addSongToPlaylist(newId, hymnTitle);

            setState(() => _isBookmarked = true);

            if (!mounted) return;
            // (원하시면 선택된 재생목록 id를 넘겨서 바로 그 탭을 선택하게 만들 수 있어요)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BookmarkScreen()),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"$name" 재생목록이 생성되고 곡이 추가되었습니다.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.primary,
              ),
            );
          } on StateError catch (e) {
            if (e.message == 'DUPLICATE_PLAYLIST_NAME') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('이미 동일한 재생목록이 있습니다.'),
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


  @override
  Widget build(BuildContext context) {
    final appBar = _chromeVisible
        ? AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: true,
      title: Text('$_current장', style: AppTextStyles.sectionTitle),
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
          onPressed: () => showBookmarkBottomSheet(context, hymnTitle),
        ),
      ],
    )
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      body: Center(
        child: Image.asset(
          _assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('악보 이미지를 찾을 수 없습니다.'),
          ),
        ),
      ),
    );
  }
}

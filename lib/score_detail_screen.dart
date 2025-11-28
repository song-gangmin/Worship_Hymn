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
  bool _chromeVisible = true;
  bool _isBookmarked = false;

  late String uid;
  late PlaylistService playlistService;

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
  }

  void _toggleFullscreen() => setState(() => _chromeVisible = !_chromeVisible);

  ///  🎵  곡을 선택한 재생목록 + 전체 재생목록에 추가하는 메인 로직
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



  /// 재생목록 선택 bottom sheet (전체는 선택지에서 제거)
  void _showBookmarkBottomSheet(BuildContext context) {
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

            // "전체" 제거
            final playlists = snapshot.data!
                .where((p) => p['name'] != '전체')
                .toList();

            return FractionallySizedBox(
              heightFactor: 0.6,
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

                          Flexible(
                            child: ListView.builder(
                              itemCount: playlists.length,
                              itemBuilder: (_, i) {
                                final p = playlists[i];

                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    p['name'],
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${p['count'] ?? 0}곡',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await _addSongSmart(p['id'], p['name']);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

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

  ///  🔧 새 재생목록 생성
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
            final newId = await playlistService.addPlaylist(name);
            await _addSongSmart(newId, name);
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


  /// UI
  @override
  Widget build(BuildContext context) {
    final appBar = _chromeVisible
        ? AppBar(
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
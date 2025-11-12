import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/playlist_service.dart';
import 'bookmark_screen.dart';
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
  String get hymnTitle => widget.hymnTitle.isNotEmpty ? widget.hymnTitle : '$_current장';

  @override
  void initState() {
    super.initState();
    _current = widget.hymnNumber.clamp(_minHymn, _maxHymn);

    final currentUser = FirebaseAuth.instance.currentUser;
    uid = currentUser?.uid ?? 'kakao:4424196142'; // ✅ 실제 Firestore UID와 맞추기
    playlistService = PlaylistService(uid: uid);
  }

  void _toggleFullscreen() => setState(() => _chromeVisible = !_chromeVisible);

  // ✅ Firestore에 곡 추가 로직
  Future<void> _addSongToPlaylist(String playlistId, String playlistName) async {
    try {
      await playlistService.addSongToPlaylist(playlistId, hymnTitle);

      // ✅ "전체" 재생목록도 함께 추가
      final allList = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('playlists')
          .where('name', isEqualTo: '전체')
          .limit(1)
          .get();
      if (allList.docs.isNotEmpty && allList.docs.first.id != playlistId) {
        await playlistService.addSongToPlaylist(allList.docs.first.id, hymnTitle);
      }

      if (!mounted) return;
      setState(() => _isBookmarked = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${playlistName}"에 곡이 추가되었습니다.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );

      // ✅ BookmarkScreen으로 이동 (그 재생목록 선택 상태로)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookmarkScreen(initialPlaylistId: playlistId),
        ),
      );
    } catch (e) {
      debugPrint('❌ 곡 추가 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('곡 추가 중 오류가 발생했습니다.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ✅ 재생목록 목록 BottomSheet
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

            final playlists = snapshot.data!;
            playlists.sort((a, b) {
              if (a['name'] == '전체') return -1;
              if (b['name'] == '전체') return 1;
              return a['name'].compareTo(b['name']);
            });

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

                          // ✅ 재생목록 리스트
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

                                    // ✅ 이미 존재하는 재생목록: 이동 없이 메시지만
                                    await playlistService.addSongToPlaylist(p['id'], hymnTitle);
                                    setState(() => _isBookmarked = true);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('"${p['name']}"에 곡이 추가되었습니다.'),
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
                            _showCreatePlaylistDialog(context); // 👈 새 재생목록은 이동 포함
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


  /// ✅ 새 재생목록 생성
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

          Navigator.pop(ctx); // 다이얼로그 닫기

          try {
            final newId = await playlistService.addPlaylist(name);
            await playlistService.addSongToPlaylist(newId, hymnTitle);
            setState(() => _isBookmarked = true);

            // ✅ 다이얼로그 닫은 뒤에는 microtask로 다음 frame에서 pushReplacement 실행
            Future.microtask(() {
              if (!mounted) return;
              Navigator.pushReplacement(
                this.context, // ⚠️ ctx가 아닌! ScoreDetailScreen의 context 사용
                MaterialPageRoute(
                  builder: (_) => BookmarkScreen(initialPlaylistId: newId),
                ),
              );
            });

            ScaffoldMessenger.of(this.context).showSnackBar(
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
      title: Text(hymnTitle, style: AppTextStyles.sectionTitle),
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

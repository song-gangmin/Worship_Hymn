import 'dart:io';
import 'dart:ui'; // 블러 효과용 ImageFilter 지원 추가
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:provider/provider.dart';
import 'package:worship_hymn/providers/font_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

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

class _ScoreDetailScreenState extends State<ScoreDetailScreen>
    with SingleTickerProviderStateMixin {
  static const int _minHymn = 1;
  static const int _maxHymn = 588;

  late int _current;
  late PageController _pageController;

  bool _controlsVisible = false;
  bool _isFullscreen = false;
  bool _isBookmarked = false;

  // 탭 컨트롤러 (악보 / 가사)
  late TabController _tabController;
  String? _lyricsText;
  bool _lyricsLoading = true;

  // 가사 탭 독립 글자 크기 (FontProvider와 별개)
  double _lyricsFontSize = 17.0;

  String? _defaultPlaylistId; // ✅ '전체' 플레이리스트 id


  late String uid;
  late PlaylistService playlistService;
  late RecentService recentService;
  late GlobalStatsService globalService;

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

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

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
    _loadLyrics();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// 탭 전환 리스너 (불필요한 동기화 제거, _goToPage가 알아서 함)
  void _onTabChanged() {
    // 탭 전환 시 화면 갱신만 처리 (UI 강제 업데이트)
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  /// 가사 파일 로드 (race condition 방지)
  Future<void> _loadLyrics() async {
    final target = _current; // 현재 페이지 캐프처
    setState(() => _lyricsLoading = true);
    try {
      final text = await rootBundle.loadString('assets/lyrics/page_$target.txt');
      // 로드 완료 시 여전히 같은 페이지일 때만 적용
      if (mounted && _current == target) {
        setState(() { _lyricsText = text; _lyricsLoading = false; });
      }
    } catch (_) {
      if (mounted && _current == target) {
        setState(() { _lyricsText = null; _lyricsLoading = false; });
      }
    }
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
          'songsCount': afterSnap.size,
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

  /// 장 이동 통합 메서드
  void _goToPage(int newPage) {
    final clamped = newPage.clamp(_minHymn, _maxHymn);
    if (clamped == _current) return;
    setState(() => _current = clamped);
    
    // 악보 탭이 현재 보이면 즉시 점프, 아니면 PageController 재성성
    if (_pageController.hasClients) {
      _pageController.jumpToPage(clamped - 1);
    } else {
      _pageController.dispose();
      _pageController = PageController(initialPage: clamped - 1);
    }

    _loadBookmarkState();
    _recordView();
    _recordUserRecent();
    _loadLyrics();
  }

  /// PhotoViewGallery의 사용자 스와이프에 의한 페이지 변경
  void _onPageChanged(int index) {
    // 악보 탭이 아닐 때 발생하는 onPageChanged는 
    // TabBarView 빌드 시 발생하는 고스트 이벤트이므로 무시!
    if (_tabController.index != 0) return; 
    
    final newPage = index + 1;
    if (newPage == _current) return;
    
    setState(() => _current = newPage);
    _loadBookmarkState();
    _recordView();
    _recordUserRecent();
    _loadLyrics();
  }

  void _nextPage() => _goToPage(_current + 1);
  void _prevPage() => _goToPage(_current - 1);

  /// 악보 이미지 공유
  Future<void> _shareScore() async {
    try {
      final byteData = await rootBundle.load('assets/scores/page_$_current.webp');
      final buffer = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/score_${_current}.webp');
      await file.writeAsBytes(buffer);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/webp')],
        text: '$_current장 $_currentHymnTitle',
        subject: '$_current장 $_currentHymnTitle',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('악보 공유 중 오류가 발생했습니다.'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  /// 가사 텍스트 공유
  Future<void> _shareLyrics() async {
    final text = _lyricsText;
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유할 가사가 없습니다.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    await Share.share(
      '$_current장 $_currentHymnTitle\n\n$text',
      subject: '$_current장 $_currentHymnTitle',
    );
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
                                color: Colors.black.withValues(alpha: 0.1),
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

  /// 점진적 블러 처리를 위해 층(Strip)을 생성하는 헬퍼 메서드
  Widget _buildBlurStrip({required double height, required double sigma}) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          height: height,
          color: Colors.transparent,
        ),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBar = _isFullscreen
        ? null
        : AppBar(
          backgroundColor: AppColors.getSurface(context),
          elevation: 0,
          centerTitle: true,
          title: Text(hymnNumberLabel, style: AppTextStyles.sectionTitle(context)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // 공유 버튼 (임시 숨김 처리)
            /*
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return IconButton(
                  iconSize: 20.0,
                  icon: Icon(
                    Icons.share_outlined,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  tooltip: '공유',
                  onPressed: () {
                    if (_tabController.index == 0) {
                      _shareScore();
                    } else {
                      _shareLyrics();
                    }
                  },
                );
              },
            ),
            */
            // 북마크 버튼
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isBookmarked 
                    ? Theme.of(context).primaryColor 
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              onPressed: () async {
                if (_isBookmarked) {
                  await _removeFromDefaultBookmark();
                } else {
                  _showBookmarkBottomSheet(context);
                }
              },
            ),
          ],
        );

    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      appBar: appBar,
      body: Column(
        children: [
          // 탭 바 (악보 / 가사)
          if (!_isFullscreen)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: AppColors.getSurface(context),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: isDark
                        ? (Theme.of(context).primaryColor == Colors.black ||
                                Theme.of(context).primaryColor == const Color(0xFF673E38)
                            ? Colors.white
                            : Theme.of(context).primaryColor)
                        : Theme.of(context).primaryColor,
                    unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                    indicatorColor: isDark
                        ? (Theme.of(context).primaryColor == Colors.black ||
                                Theme.of(context).primaryColor == const Color(0xFF673E38)
                            ? Colors.white
                            : Theme.of(context).primaryColor)
                        : Theme.of(context).primaryColor,
                    indicatorWeight: 1.0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                    tabs: const [
                      Tab(text: '악보'),
                      Tab(text: '가사'),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 0.2,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ],
            ),
          // 탭 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(), // 탭 간 스와이프 방지 (가사 탭에서 장 넘기기 위해)
              children: [
                // 탭 0: 악보
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleControls,
                  child: Stack(
                    children: [
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
                            color: AppColors.getSurface(context),
                          ),
                          pageController: _pageController,
                          onPageChanged: _onPageChanged,
                        ),
                      ),
                      // 이전 화살표 (중앙 고정)
                      if (_controlsVisible)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _arrowButton(icon: Icons.chevron_left, onTap: _prevPage),
                          ),
                        ),
                      // 다음 화살표 (중앙 고정)
                      if (_controlsVisible)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _arrowButton(icon: Icons.chevron_right, onTap: _nextPage),
                          ),
                        ),
                    ],
                  ),
                ),
                // 탭 1: 가사
                _buildLyricsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 가사 탭 위젯
  Widget _buildLyricsTab() {
    if (_lyricsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lyricsText == null || _lyricsText!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 48,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white30
                  : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              '가사 준비 중입니다.',
              style: AppTextStyles.body(context).copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<FontProvider>(
      builder: (context, font, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Stack(
          key: ValueKey('lyrics_$_current'),
          children: [
            // 1. 가사 본문 및 스크롤 영역 (전체 화면 차지)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleControls,
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v < -300) {
                    _goToPage(_current + 1);
                  } else if (v > 300) {
                    _goToPage(_current - 1);
                  }
                },
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      // 하단 블러 바 뒤로 가사가 스크롤되므로 넉넉한 하단 패딩(110 + 기기 안전영역) 부여
                      padding: EdgeInsets.fromLTRB(
                        24, 
                        20, 
                        24, 
                        MediaQuery.of(context).padding.bottom + 110,
                      ),
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          _lyricsText!,
                          textAlign: TextAlign.left,
                          style: AppTextStyles.body(context).copyWith(
                            fontSize: _lyricsFontSize,
                            fontWeight: font.applyWeight(FontWeight.w400),
                            height: 1.9,
                          ),
                        ),
                      ),
                    ),
                    // 이전 화살표 (Stack 중앙 고정)
                    if (_controlsVisible)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _arrowButton(icon: Icons.chevron_left, onTap: _prevPage),
                        ),
                      ),
                    // 다음 화살표 (Stack 중앙 고정)
                    if (_controlsVisible)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _arrowButton(icon: Icons.chevron_right, onTap: _nextPage),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // 2. 하단 애플(Apple) 스타일 찐 프로그레시브 블러 (Progressive Glass Blur)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              // 지금 높이(80)에서 10을 더 올려 90으로 설정
              height: 90 + MediaQuery.of(context).padding.bottom,
              child: IgnorePointer(
                child: Stack(
                  children: [
                    // 1) 블러 강도가 점진적으로 강해지는 스트립(Strips) 구조 (고스트 현상 제거)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 시그마 0.5부터 5.0까지 0.5 단계로 세분화 (총 10단계, 각 높이 5.5 = 총 55px)
                        ...List.generate(10, (index) {
                          return _buildBlurStrip(
                            height: 3.5,
                            sigma: (index + 1) * 0.5, // 0.5, 1.0 ... 5.0
                          );
                        }),
                        _buildBlurStrip(
                          height: 35 + MediaQuery.of(context).padding.bottom,
                          sigma: 2.0, // 최종 maximum 5
                        ),
                      ],
                    ),
                    // 2) 애플 특유의 글라스(Glass) 질감을 위한 은은한 그라데이션 틴트
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isDark
                                ? Colors.black.withValues(alpha: 0.0)
                                : Colors.white.withValues(alpha: 0.0),
                            isDark
                                ? Colors.black.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.25),
                            isDark
                                ? Colors.black.withValues(alpha: 0.75)
                                : Colors.white.withValues(alpha: 0.75),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. 플로팅 텍스트 크기 조절 바 (블러 위에 따로 독립적으로 띄움)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: _buildFontSizeBar(context),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 가사 탭 하단 폰트 크기 조절 바 (플로팅 입체 필 스타일 + 가가 - [Slider] + 구성)
  Widget _buildFontSizeBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16), // 공중에 둥둥 떠 있는 마진 설정 (플로팅 입체감 극대화)
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white, // 다크모드는 어두운 회색, 라이트모드는 밝은 흰색
        borderRadius: BorderRadius.circular(100), // 완벽한 타원 알약(Pill) 모양으로 플로팅 느낌 구현
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6), // 세련된 입체 그림자 효과로 플로팅 느낌 완벽화
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. '가가' 텍스트 인디케이터 (큰 가가 앞에 오고 작은 가가 뒤에 오도록 배치)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '가',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '가',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // 2. 마이너스 (-) 버튼
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              setState(() {
                _lyricsFontSize = (_lyricsFontSize - 1.0).clamp(12.0, 28.0);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.remove,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 20,
              ),
            ),
          ),
          // 3. 슬라이더 영역
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                activeTrackColor: primaryColor,
                inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                thumbColor: primaryColor,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: Slider(
                value: _lyricsFontSize,
                min: 12.0,
                max: 28.0,
                onChanged: (val) {
                  setState(() {
                    _lyricsFontSize = val;
                  });
                },
              ),
            ),
          ),
          // 4. 플러스 (+) 버튼
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              setState(() {
                _lyricsFontSize = (_lyricsFontSize + 1.0).clamp(12.0, 28.0);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.add,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 20,
              ),
            ),
          ),
        ],
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
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
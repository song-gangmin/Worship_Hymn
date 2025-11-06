import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/text_styles.dart';

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
  bool _chromeVisible = true;   // AppBar/하단바 표시 여부(=전체화면 아님)
  bool _overlayVisible = false; // 이미지 위 오버레이 컨트롤 표시

  String get _assetPath => 'assets/scores/page_$_current.png';

  @override
  void initState() {
    super.initState();
    _current = widget.hymnNumber.clamp(_minHymn, _maxHymn);
  }

  void _toggleOverlay() {
    setState(() => _overlayVisible = !_overlayVisible);
  }

  void _toggleFullscreen() {
    setState(() => _chromeVisible = !_chromeVisible);
    // 시스템 UI까지 숨기고 싶으면 주석 해제:
    // if (_chromeVisible) {
    //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // } else {
    //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // }
  }

  void _goPrev() {
    if (_current > _minHymn) {
      setState(() => _current--);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _goNext() {
    if (_current < _maxHymn) {
      setState(() => _current++);
    } else {
      HapticFeedback.selectionClick();
    }
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
          icon: const Icon(Icons.bookmark_border),
          onPressed: () {
            // TODO: 즐겨찾기 토글
          },
        ),
      ],
    )
        : null;

    final bottomBar = _chromeVisible
        ? SafeArea(
      top: false,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.play_arrow), onPressed: () {}),
            Expanded(child: Slider(value: 0, onChanged: (_) {}, min: 0, max: 1)),
            IconButton(icon: const Icon(Icons.stop_rounded), onPressed: () {}),
          ],
        ),
      ),
    )
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      body: SafeArea(
        top: _chromeVisible,   // 풀스크린일 때 이미지가 최상단까지
        bottom: _chromeVisible,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 이미지 (탭하면 오버레이 토글)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleOverlay,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Center(
                  child: Image.asset(
                    _assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('악보 이미지를 찾을 수 없습니다.'),
                    ),
                  ),
                ),
              ),
            ),

            // ===== 오버레이 컨트롤들 (이미지 위에 뜸) =====
            if (_overlayVisible) ...[
              // 우상단 전체화면 토글 아이콘
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea( // ← 안전영역 보장!
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: _OverlayIconButton(
                      icon: _chromeVisible ? Icons.fullscreen : Icons.fullscreen_exit,
                      onTap: _toggleFullscreen,
                    ),
                  ),
                ),
              ),

              // 가운데 왼쪽: 이전
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _OverlayCircleButton(
                          icon: Icons.chevron_left,
                          onTap: _goPrev,
                          disabled: _current <= _minHymn,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _OverlayCircleButton(
                          icon: Icons.chevron_right,
                          onTap: _goNext,
                          disabled: _current >= _maxHymn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}

// 우상단 네모(전체화면 토글) - 살짝 반투명 배경
class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _OverlayIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// 가운데 좌우 원형 버튼
class _OverlayCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;
  const _OverlayCircleButton({
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Colors.black.withOpacity(disabled ? 0.15 : 0.35);
    final fg = Colors.white.withOpacity(disabled ? 0.4 : 0.95);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, color: fg, size: 30),
        ),
      ),
    );
  }
}

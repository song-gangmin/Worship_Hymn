import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/constants/text_styles.dart';

/// Firestore `app_settings/notice` 문서에서 공지를 읽어와
/// "다시 보지 않기"를 체크하지 않은 사용자에게만 팝업을 띄우는 유틸리티.
///
/// Firestore 문서 구조:
/// ```
/// app_settings/notice
///   ├─ id: "lyrics_v1"            (공지 고유 ID — 바꾸면 새 공지로 인식)
///   ├─ title: "📢 가사 기능 업데이트"
///   ├─ body: "가사 작업이 완료되었습니다! ..."
///   └─ enabled: true              (false로 바꾸면 공지 비활성화)
/// ```
class NoticeService {
  static const String _prefKeyPrefix = 'notice_dismissed_';

  /// 앱 시작 시 호출. 조건에 맞으면 공지 다이얼로그를 띄운다.
  static Future<void> checkAndShow(BuildContext context) async {
    try {
      debugPrint('>>> NoticeService: checkAndShow() called');
      final doc = await FirebaseFirestore.instance
          .collection('notice')
          .doc('notice')
          .get();

      if (!doc.exists) {
        debugPrint('>>> NoticeService: Document does not exist at notice/notice');
        return;
      }

      final data = doc.data()!;
      debugPrint('>>> NoticeService: Raw data = $data');
      
      final bool enabled = data['enabled'] == true; // string "true" 방어
      if (!enabled) {
        debugPrint('>>> NoticeService: Notice is disabled (enabled = false)');
        return;
      }

      final String noticeId = data['id']?.toString() ?? '';
      final String title = data['title']?.toString() ?? '';
      final String body = data['body']?.toString() ?? '';

      if (noticeId.isEmpty || body.isEmpty) {
        debugPrint('>>> NoticeService: Missing required fields (id: $noticeId, body: $body)');
        return;
      }

      // "다시 보지 않기"를 눌렀는지 확인
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool('$_prefKeyPrefix$noticeId') ?? false;
      debugPrint('>>> NoticeService: Dismissed status for $noticeId = $dismissed');
      
      if (dismissed) {
        debugPrint('>>> NoticeService: User already dismissed this notice.');
        return;
      }

      // 컨텍스트가 아직 유효한지 확인
      if (!context.mounted) {
        debugPrint('>>> NoticeService: Context is no longer mounted');
        return;
      }

      debugPrint('>>> NoticeService: Showing dialog!');
      _showNoticeDialog(context, noticeId, title, body);
    } catch (e, stack) {
      debugPrint('>>> NoticeService error: $e\n$stack');
    }
  }

  static void _showNoticeDialog(
    BuildContext context,
    String noticeId,
    String title,
    String body,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _NoticeDialog(
          noticeId: noticeId,
          title: title,
          body: body,
        );
      },
    );
  }
}

class _NoticeDialog extends StatefulWidget {
  final String noticeId;
  final String title;
  final String body;

  const _NoticeDialog({
    required this.noticeId,
    required this.title,
    required this.body,
  });

  @override
  State<_NoticeDialog> createState() => _NoticeDialogState();
}

class _NoticeDialogState extends State<_NoticeDialog> {
  bool _dontShowAgain = false;

  Future<void> _dismiss() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        'notice_dismissed_${widget.noticeId}',
        true,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.getSurface(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75, // 최대 높이를 화면의 75%로 제한
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘 + 타이틀
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTextStyles.sectionTitle(context).copyWith(
                        fontSize: AppTextStyles.font(context).applySize(18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 본문 (내용이 길면 스크롤 가능하게 처리)
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    widget.body,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: AppTextStyles.font(context).applySize(15),
                      height: 1.65,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 다시 보지 않기 체크박스
              GestureDetector(
                onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _dontShowAgain,
                        onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
                        activeColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white38 : Colors.black38,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '다시 보지 않기',
                      style: AppTextStyles.caption(context).copyWith(
                        fontSize: AppTextStyles.font(context).applySize(14),
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _dismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      fontSize: AppTextStyles.font(context).applySize(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

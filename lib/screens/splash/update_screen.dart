import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:worship_hymn/utils/version_checker.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/constants/text_styles.dart';


class UpdateScreen extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback onSkip;

  const UpdateScreen({
    super.key,
    required this.updateInfo,
    required this.onSkip,
  });

  Future<void> _launchStore() async {
    final Uri url = Uri.parse(updateInfo.storeUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch ${updateInfo.storeUrl}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isForce = updateInfo.type == UpdateType.forceUpdate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // App Icon / Image
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset('assets/icon/app_icon.png'),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Title
              Text(
                '업데이트 알림',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline(context).copyWith(
                  fontSize: AppTextStyles.font(context).applySize(24),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                updateInfo.latestVersion.startsWith('DB_ERROR')
                  ? '🚨 [Firebase 오류] 🚨\n\n${updateInfo.latestVersion}\n\nFirestore 설정 및 앱 권한, 인터넷 연결을 확인해주세요.'
                  : isForce 
                    ? '안정적인 서비스 이용을 위해\n최신 버전(${updateInfo.latestVersion})으로 업데이트가 필요합니다.'
                    : '새로운 기능이 추가된 최신 버전(${updateInfo.latestVersion})이\n출시되었습니다. 지금 업데이트 하시겠어요?',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(
                  height: 1.5,
                  color: updateInfo.latestVersion.startsWith('DB_ERROR') ? Colors.red : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              
              const Spacer(),

              // Update Button
              ElevatedButton(
                onPressed: _launchStore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '지금 업데이트 하기',
                  style: TextStyle(
                    fontSize: AppTextStyles.font(context).applySize(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Skip Button (only for soft update)
              if (!isForce)
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: isDark ? Colors.white54 : Colors.black45,
                  ),
                  child: Text(
                    '다음에 하기',
                    style: TextStyle(
                      fontSize: AppTextStyles.font(context).applySize(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                const SizedBox(height: 50), // Balance spacing when skip button is hidden
                
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

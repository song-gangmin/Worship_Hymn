import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import 'section1_screen.dart';
import 'auth/logout_helper.dart';


class SettingScreen extends StatelessWidget {
  final String name;
  final String email;

  const SettingScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    // 전달받은 값이 있으면 로그인 상태
    final bool signedIn = name.isNotEmpty && name != '로그인 하세요';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('설정', style: AppTextStyles.headline),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 프로필 카드 ───
          Padding(
            padding: const EdgeInsets.all(14),
            child: Card(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.background,
                      radius: 28,
                      child: Icon(Icons.person, size: 34),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signedIn ? name : '로그인 하세요',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          signedIn ? email : '이메일 정보 없음',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── 메뉴 리스트 ─────────────────────
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  _SettingItem(title: '프로필', onTap: () {}),
                  _SettingItem(title: '계정', onTap: () {}),
                  _SettingItem(title: '화면', onTap: () {}),
                  const SizedBox(height: 20),
                  _SettingItem(title: '문의', onTap: () {}),
                  const _SettingItem(
                    title: '버전',
                    trailing: Text(
                      '1.1.1',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  _SettingItem(
                    title: signedIn ? '로그아웃' : '로그인',
                    isDestructive: signedIn,
                    onTap: () async {
                      if (signedIn) {
                        await appLogout(context);
                      } else {
                        // 로그인 → Section1Screen으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Section1Screen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingItem({
    required this.title,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = isDestructive
        ? const TextStyle(fontSize: 16, color: Colors.red)
        : const TextStyle(fontSize: 16, color: Colors.black);

    return ListTile(
      title: Text(title, style: textStyle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      dense: true,
    );
  }
}

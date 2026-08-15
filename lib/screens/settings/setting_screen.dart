import 'package:flutter/material.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/constants/text_styles.dart';
import 'package:worship_hymn/screens/login/section1_screen.dart';
import 'package:worship_hymn/auth/logout_helper.dart';
import 'package:worship_hymn/screens/settings/inquiry_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:worship_hymn/widget/playlist_dialog.dart';
import 'package:worship_hymn/screens/settings/display_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:worship_hymn/screens/settings/account_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key,});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isGuest = (user == null) || (user.isAnonymous);
    debugPrint(">>> SettingScreen: user=${user?.uid}, isAnonymous=${user?.isAnonymous}");

    // 🔹 게스트(익명)인 경우: 스트림 안 타고 바로 "로그인 하세요" UI
    if (isGuest) {
      return _buildScreen(
        name: '로그인 하세요',
        email: '이메일 정보 없음',
        signedIn: false, // 🔥 로그인 안 된 상태로 취급
        context: context,
      );
    }

    // Firestore에서 users/{uid} 문서 실시간 읽기
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data!.data() ?? {};
        debugPrint(">>> SettingScreen Firestore data: $data");
        final name = data['name'] ?? user.displayName ?? '이름 없음';
        final email = data['email'] ?? user.email ?? '이메일 정보 없음';

        return _buildScreen(
          name: name,
          email: email,
          signedIn: true,
          context: context,
        );
      },
    );
  }
  @override
  Widget _buildScreen({
    required String name,
    required String email,
    required bool signedIn,
    required BuildContext context,
  }) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
        title: Text('설정', style: AppTextStyles.headline(context)),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

        // 🔹 상단 프로필 섹션 (카드 뷰 복구 + 터치 그림자 제거)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Card(
            color: AppColors.getSurface(context),
            surfaceTintColor: Colors.transparent,
            elevation: 0.5, // 은은한 그림자 유지
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            clipBehavior: Clip.antiAlias, // 카드 모서리에 맞춰 클릭 효과 제한
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                if (signedIn) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Section1Screen()),
                  );
                }
              },
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.person, color: AppColors.gold, size: 30),
                ),
                title: Text(name, style: AppTextStyles.headline(context).copyWith(fontSize: 18)),
                subtitle: Text(email, style: AppTextStyles.body(context).copyWith(fontSize: 13, color: Colors.grey)),
              ),
            ),
          ),
        ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 10),
                // 🔹 설정 그룹 1 (화면, 글자)
                Container(
                  color: AppColors.getSurface(context),
                  child: Column(
                    children: [
                      _SettingItem(title: '화면', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DisplayScreen()),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🔹 설정 그룹 2 (문의, 버전, 로그인/로그아웃)
                Container(
                  color: AppColors.getSurface(context),
                  child: Column(
                    children: [
                      _SettingItem(title: '문의', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InquiryScreen()),
                        );
                      }),
                      const SizedBox(height:4),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          String versionText = '...';
                          if (snapshot.hasData) versionText = snapshot.data!.version;
                          return _SettingItem(
                            title: '버전',
                            trailing: Text(versionText, style: TextStyle(fontSize: AppTextStyles.font(context).applySize(16), color: Colors.grey)),
                          );
                        },
                      ),
                      const SizedBox(height:4),
                      _SettingItem(
                        title: signedIn ? '로그아웃' : '로그인',
                        isDestructive: signedIn,
                        onTap: () async {
                          if (signedIn) {
                            await _showLogoutDialog(context);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const Section1Screen()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // 🔥 로그아웃 다이얼로그 함수
  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PlaylistDialog(
        title: '로그아웃 하시겠습니까?',
        confirmText: '확인',
        controller: TextEditingController(), // 사용 안하지만 필수 파라미터면 유지
        showTextField: false,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );

    if (confirmed == true) {
      await appLogout();
    }
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
        ? TextStyle(fontSize: AppTextStyles.font(context).applySize(16), color: Colors.red)
        : TextStyle(
            fontSize: AppTextStyles.font(context).applySize(16),
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          );

    return ListTile(
      title: Text(title, style: textStyle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      dense: true,
    );
  }
}

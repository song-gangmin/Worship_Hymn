import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import 'section1_screen.dart';
import 'auth/logout_helper.dart';
import 'inquiry_screen.dart';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'widget/playlist_dialog.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key,});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // 로그인 안된 상태
      return _buildScreen(
        name: '로그인 하세요',
        email: '이메일 정보 없음',
        signedIn: false,
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
        final name = data['name'] ?? user.displayName ?? '';
        final email = data['email'] ?? user.email ?? '';

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

          // ─── 기존 네 UI 100% 그대로 붙여넣기 ───
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
                        Text(name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
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

          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  //_SettingItem(title: '프로필', onTap: () {}),
                  //_SettingItem(title: '계정', onTap: () {}),
                  //_SettingItem(title: '화면', onTap: () {}),
                  const SizedBox(height: 20),
                  _SettingItem(title: '문의', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InquiryScreen(),
                      ),
                    );
                  }),
                  const _SettingItem(
                    title: '버전',
                    trailing: Text('1.1.1', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
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
                  )
                ],
              ),
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
      await appLogout(context);
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

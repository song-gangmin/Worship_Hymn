import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/constants/text_styles.dart';
import 'package:worship_hymn/services/account_service.dart';
import 'package:worship_hymn/widget/playlist_dialog.dart';
import 'package:worship_hymn/auth/logout_helper.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return Scaffold(
        appBar: AppBar(title: const Text('계정')),
        body: const Center(child: Text('로그인이 필요합니다.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() ?? {};
        final email = data['email'] ?? user.email ?? '이메일 없음';
        var name = data['name'] ?? user.displayName ?? '';
        final provider = data['provider'] ?? '알 수 없음';
        
        // 🔹 Fallback name logic
        if (name.isEmpty || name == '이름 없음') {
           if (provider == 'apple') {
             name = 'Apple 회원';
           }
        }
        
        String iconPath = '';
        IconData? iconData;

        switch (provider) {
          case 'google':
            iconPath = 'assets/icon/google.png';
            break;
          case 'kakao':
            iconPath = 'assets/icon/kakao.png';
            break;
          case 'naver':
            iconPath = 'assets/icon/naver.png';
            break;
          case 'apple':
            iconData = Icons.apple;
            break;
        }

        return Scaffold(
          backgroundColor: AppColors.getBackground(context),
          appBar: AppBar(
            backgroundColor: AppColors.getBackground(context),
            elevation: 0,
            title: Text('계정 설정', style: AppTextStyles.headline(context).copyWith(fontSize: 18)),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),
              // Name is not displayed in the design, only email? 
              // Verify user request: "apple logo... and call name also"
              // The previous design only had email. 
              // If the user wants name, I should add it.
              // I'll add name above email if it's available.
              _buildInfoSection(context, provider, iconPath, iconData, name, email),
              const SizedBox(height: 40),
              _buildActionItem(
                context,
                title: '데이터 초기화',
                description: '즐겨찾기 및 최근 본 목록이 삭제됩니다.',
                onTap: () => _confirmResetData(context, user.uid),
              ),
              const SizedBox(height: 4),
              _buildActionItem(
                context,
                title: '계정 삭제',
                description: '모든 데이터와 계정이 영구적으로 삭제됩니다.',
                isDestructive: true,
                onTap: () => _confirmDeleteAccount(context, user.uid),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context, String provider, String iconPath, IconData? iconData, String name, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '로그인 정보',
            style: AppTextStyles.caption(context),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPlatformIcon(context, provider, iconPath, iconData),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (name.isNotEmpty && name != '이름 없음' && name != 'Apple 회원') // Show name if it's a real name? Or always?
                   // User said "call name also". Let's show it if it exists.
                    Text(
                      name,
                      style: AppTextStyles.body(context).copyWith(
                        fontSize: AppTextStyles.font(context).applySize(14),
                        color: Colors.grey,
                      ),
                    ),
                  Text(
                    email,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: AppTextStyles.font(context).applySize(17),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformIcon(BuildContext context, String provider, String iconPath, IconData? iconData) {
    Color? bgColor;
    double padding = 2; // 기본 패딩
    BoxBorder? border;

    switch (provider) {
      case 'naver':
        bgColor = const Color(0xFF1EC800);
        padding = 4;
        break;
      case 'kakao':
        bgColor = const Color(0xFFFFE812);
        padding = 4;
        break;
      case 'google':
        bgColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF333333) : Colors.white;
        border = Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade300);
        padding = 4;
        break;
      case 'apple':
         bgColor = Colors.white; // Apple usually white or black. Let's stick to white for icon contrast if using black icon
         // In dark mode, maybe different?
         // Let's use standard handling
         bgColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black; 
         // If bg is black, icon should be white. If bg is white, icon black.
         // Wait, Icon(Icons.apple) color needs to be set.
         break;
    }

    return Container(
      width: 28,
      height: 28,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: border,
      ),
      child: iconData != null 
          ? Icon(iconData, size: 20, color: (provider == 'apple' && bgColor == Colors.black) ? Colors.white : Colors.black)
          : Image.asset(iconPath, fit: BoxFit.contain),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: AppColors.getSurface(context),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive 
                          ? Colors.red 
                          : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.caption(context).copyWith(fontSize: AppTextStyles.font(context).applySize(13)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmResetData(BuildContext context, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PlaylistDialog(
        title: '데이터를 초기화하시겠습니까?',
        confirmText: '확인',
        controller: TextEditingController(),
        showTextField: false,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );

    if (confirmed == true) {
      try {
        await AccountService().resetUserData(uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('데이터가 초기화되었습니다.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PlaylistDialog(
        title: '계정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
        confirmText: '삭제',
        controller: TextEditingController(),
        showTextField: false,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );

    if (confirmed == true) {
      try {
        await AccountService().deleteAccount(uid);
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('계정이 삭제되었습니다.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          if (e.toString().contains('requires-recent-login')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('보안을 위해 다시 로그인 후 시도해주세요.')),
            );
            await appLogout();
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('오류가 발생했습니다: $e')),
            );
          }
        }
      }
    }
  }
}

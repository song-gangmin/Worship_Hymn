import 'package:flutter/material.dart';
import '/constants/colors.dart';
import 'home_screen.dart';
import 'main_screen.dart';
import 'auth/kakao_auth.dart';
import 'main_screen.dart';

class Section1Screen extends StatelessWidget {
  const Section1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 80),
              // 로고 + 텍스트
              Image.asset(
                'assets/image/login_screen.png',
                width: 380,
              ),
              const SizedBox(height: 32),
              const Text(
                '"하나님은 영이시니 예배하는 자가 영과 진리로 예배할 지니라"\n- 요 4:24 -',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 3),
                child: Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 0.8,
                        endIndent: 12,
                      ),
                    ),
                    const Text(
                      '로그인 / 회원가입',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 0.8,
                        indent: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              _loginButton(
                text: '카카오로 계속하기',
                iconPath: 'assets/icon/kakao.png',
                backgroundColor: const Color(0xFFFFE812),
                textColor: Colors.black,
                onTap: () async {
                  try {
                    final user = await KakaoAuth.signIn();   // ← 기존 함수 그대로 사용
                    if (!context.mounted) return;

                    if (user != null) {
                      // ✅ 성공: 로그인 화면 스택 제거하고 메인으로
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                            (_) => false,
                      );
                    } else {
                      // 사용자가 취소한 케이스
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('로그인이 취소되었습니다.')),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('카카오 로그인 실패: $e')),
                    );
                  }
                },
              ),
              const SizedBox(height: 18),
              _loginButton(
                text: '네이버로 계속하기',
                iconPath: 'assets/icon/naver.png',
                backgroundColor: const Color(0xFF1EC800),
                textColor: Colors.white,
                onTap: () {},
              ),
              const SizedBox(height: 18),
              _loginButton(
                text: 'Google로 계속하기',
                iconPath: 'assets/icon/google.png',
                backgroundColor: Colors.white,
                textColor: Colors.black87,
                border: BorderSide(color: Colors.grey.shade400),
                onTap: () {},
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 3),
                child: Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 0.8,
                        endIndent: 12,
                      ),
                    ),
                    const Text(
                      '또는',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 0.8,
                        indent: 12,
                      ),
                    ),
                  ],
                ),
              ),

              _primaryCTA(
                text: '로그인 없이 계속하기',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                },
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginButton({
    required String text,
    required String iconPath,
    required Color backgroundColor,
    required Color textColor,
    VoidCallback? onTap,
    BorderSide? border,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Stack(
          alignment: Alignment.center, // 텍스트는 정확히 중앙
          children: [
            // 왼쪽 로고(고정 간격)
            Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(iconPath, width: 20, height: 20),
            ),
            // 중앙 텍스트
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _primaryCTA({
    required String text,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // 0xFF673E38
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16
          ),
        ),
      ),
    );
  }
}

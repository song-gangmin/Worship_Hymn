import 'package:flutter/material.dart';
import '/constants/colors.dart';
import 'main_screen.dart';
import 'auth/kakao_auth.dart';
import 'auth/naver_auth.dart';
import 'auth/google_auth.dart';
import 'auth/resualt_auth.dart';

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

              // ─────────── 로그인 버튼 헤더 ───────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 3),
                child: Row(
                  children: const [
                    Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 0.8,
                        endIndent: 12,
                      ),
                    ),
                    Text(
                      '로그인 / 회원가입',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
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

              // ─────────── 카카오 로그인 ───────────
              _loginButton(
                text: '카카오로 계속하기',
                iconPath: 'assets/icon/kakao.png',
                backgroundColor: const Color(0xFFFFE812),
                textColor: Colors.black,
                onTap: () => handleSignIn(context: context, service: KakaoAuth()),
              ),

              const SizedBox(height: 18),

              _loginButton(
                text: '네이버로 계속하기',
                iconPath: 'assets/icon/naver.png',
                backgroundColor: const Color(0xFF1EC800),
                textColor: Colors.white,
                onTap: () => handleSignIn(context: context, service: NaverAuth()),
              ),

              const SizedBox(height: 18),

              _loginButton(
                text: 'Google로 계속하기',
                iconPath: 'assets/icon/google.png',
                backgroundColor: Colors.white,
                textColor: Colors.black87,
                border: BorderSide(color: Colors.grey.shade400),
                onTap: () => handleSignIn(context: context, service: GoogleAuth()),
              ),


              // ─────────── 구분선 ───────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 3),
                child: Row(
                  children: const [
                    Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 0.8,
                        endIndent: 12,
                      ),
                    ),
                    Text(
                      '또는',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 0.8,
                        indent: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // ─────────── 로그인 없이 계속하기 ───────────
              _primaryCTA(
                text: '로그인 없이 계속하기',
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => MainScreen(
                        name: '로그인 하세요',
                        email: '이메일 정보 없음',
                      ),
                    ),
                    (_) => false,
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

  // ─────────── 버튼 위젯 ───────────
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
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(iconPath, width: 20, height: 20),
            ),
            Text(
              text,
              style: TextStyle(color: textColor, fontSize: 16),
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
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
Future<void> handleSignIn({
  required BuildContext context,
  required AuthService service,
}) async {
  try {
    final user = await service.signIn();

    // ✅ Firestore 저장
    await UserRepository().upsertUser(user);

    // ✅ 로그인 성공 후 라우팅
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.name ?? '사용자'}님 환영합니다!')),
    );

    Navigator.pushReplacementNamed(context, '/home');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('로그인 실패: $e')),
    );
  }
}

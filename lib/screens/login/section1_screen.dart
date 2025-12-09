import 'package:flutter/material.dart';
import '/constants/colors.dart';
import 'package:worship_hymn/repositories/UserRepository.dart';
import 'package:worship_hymn/screens/main/main_screen.dart';
import 'package:worship_hymn/auth/kakao_auth.dart';
import 'package:worship_hymn/auth/naver_auth.dart';
import 'package:worship_hymn/auth/google_auth.dart';
import 'package:worship_hymn/auth/result_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
              Image.asset('assets/image/login_screen.png', width: 380,),
              const SizedBox(height: 32),
              const Text('"하나님은 영이시니 예배하는 자가 영과 진리로 예배할 지니라"\n- 요 4:24 -',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.gold, fontSize: 13, height: 1.5),
              ),
              const Spacer(),

              // ─────────── 로그인 버튼 헤더 ───────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 3),
                child: Row(
                  children: const [
                    Expanded(child: Divider(color: Colors.grey, thickness: 0.8, endIndent: 12),),
                    Text('로그인 / 회원가입', style: TextStyle(color: Colors.black54, fontSize: 13),),
                    Expanded(child: Divider(color: Colors.grey, thickness: 0.8, indent: 12),
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
              // ─────────── 네이버 로그인 ───────────
              _loginButton(
                text: '네이버로 계속하기',
                iconPath: 'assets/icon/naver.png',
                backgroundColor: const Color(0xFF1EC800),
                textColor: Colors.white,
                onTap: () => handleSignIn(context: context, service: NaverAuth()),
              ),
              const SizedBox(height: 18),
              // ─────────── 구글 로그인 ───────────
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
                    Expanded(child: Divider(color: Colors.grey, thickness: 0.8, endIndent: 12,),),
                    Text('또는', style: TextStyle(color: Colors.black54, fontSize: 13),),
                    Expanded(child: Divider(color: Colors.grey, thickness: 0.8, indent: 12),),
                  ],
                ),
              ),

              // ─────────── 로그인 없이 계속하기 ───────────
              _primaryCTA(
                text: '로그인 없이 계속하기',
                onTap: () async {
                  try {
                    final auth = FirebaseAuth.instance;
                    // 이미 로그인 되어있는지 체크 (방어 코드)
                    if (auth.currentUser == null) {
                      // ⏳ 로딩 표시가 필요하다면 여기서 setState로 loading = true 처리
                      await auth.signInAnonymously();
                      debugPrint('✅ 익명 로그인 성공');
                    }
                    // 성공하면 main.dart의 StreamBuilder가 감지하여 자동으로 화면 전환됨

                  } on FirebaseAuthException catch (e) {
                    // Firebase 관련 에러 (대부분 네트워크 문제)
                    if (!context.mounted) return;

                    String message = "일시적인 오류가 발생했습니다.";

                    // 대표적인 네트워크 에러 코드들 확인
                    if (e.code == 'network-request-failed' || e.code == 'unavailable') {
                      message = "네트워크 연결을 확인해주세요.";
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.redAccent, // 에러 느낌을 주기 위해 빨간색 추천
                      ),
                    );
                  } catch (e) {
                    // 그 외 알 수 없는 에러
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('네트워크 연결 상태를 확인해주세요.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
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
    try {
      await UserRepository().upsertUser(user);
    } catch (e) {}
    if (!context.mounted) return;
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('로그인 실패: $e')),
    );
  }
}




import 'package:flutter/material.dart';
import '/constants/colors.dart';
import 'package:worship_hymn/repositories/UserRepository.dart';
import 'package:worship_hymn/screens/main/main_screen.dart';
import 'package:worship_hymn/auth/kakao_auth.dart';
import 'package:worship_hymn/auth/naver_auth.dart';
import 'package:worship_hymn/auth/google_auth.dart';
import 'package:worship_hymn/auth/result_auth.dart';
import 'package:worship_hymn/auth/apple_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Section1Screen extends StatefulWidget {
  const Section1Screen({super.key});

  @override
  State<Section1Screen> createState() => _Section1ScreenState();
}

class _Section1ScreenState extends State<Section1Screen> {
  bool _isLoading = false;

  void _setLoading(bool val) {
    if (mounted) setState(() => _isLoading = val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            const SizedBox(height: 80),
                            // 로고 + 텍스트
                            Image.asset('assets/image/login_screen.png', width: 380,),
                            const SizedBox(height: 32),
                            const Text('"하나님은 영이시니 예배하는 자가 영과 진리로 예배할지니라"\n- 요 4:24 -',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.gold, fontSize: 13, height: 1.5),
                            ),
                            const SizedBox(height: 40),

                            // ─────────── 로그인 버튼 헤더 ───────────
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 3),
                              child: Row(
                                children: [
                                  Expanded(child: Divider(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey, thickness: 0.8, endIndent: 12)),
                                  Text('로그인 / 회원가입', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54, fontSize: 13)),
                                  Expanded(child: Divider(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey, thickness: 0.8, indent: 12)),
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
                              onTap: _isLoading ? null : () => handleSignIn(context: context, service: KakaoAuth(), setLoading: _setLoading),
                            ),
                            const SizedBox(height: 18),
                            // ─────────── 네이버 로그인 ───────────
                            _loginButton(
                              text: '네이버로 계속하기',
                              iconPath: 'assets/icon/naver.png',
                              backgroundColor: const Color(0xFF1EC800),
                              textColor: Colors.white,
                              onTap: _isLoading ? null : () => handleSignIn(context: context, service: NaverAuth(), setLoading: _setLoading),
                            ),
                            const SizedBox(height: 18),
                            // ─────────── 구글 로그인 ───────────
                            _loginButton(
                              text: 'Google로 계속하기',
                              iconPath: 'assets/icon/google.png',
                              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF333333) : Colors.white,
                              textColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                              border: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade400),
                              onTap: _isLoading ? null : () => handleSignIn(context: context, service: GoogleAuth(), setLoading: _setLoading),
                            ),

                            const SizedBox(height: 18),
                            // ─────────── 애플 로그인 ───────────
                            FutureBuilder<bool>(
                              future: SignInWithApple.isAvailable(),
                              builder: (context, snapshot) {
                                if (snapshot.data == true) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 18), // Google 아래 간격 유지 대신 여기서 처리? 아니면 SizedBox?
                                    child: _loginButton(
                                      text: 'Apple로 계속하기',
                                      iconData: Icons.apple, // Apple Icon
                                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                      textColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                                      onTap: _isLoading ? null : () => handleSignIn(context: context, service: AppleAuth(), setLoading: _setLoading),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),


                            // ─────────── 구분선 ───────────
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 3),
                              child: Row(
                                children: [
                                  Expanded(child: Divider(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey, thickness: 0.8, endIndent: 12)),
                                  Text('또는', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54, fontSize: 13)),
                                  Expanded(child: Divider(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey, thickness: 0.8, indent: 12)),
                                ],
                              ),
                            ),

                            // ─────────── 로그인 없이 계속하기 ───────────
                            _primaryCTA(
                              context: context,
                              text: '로그인 없이 계속하기',
                              onTap: _isLoading ? null : () async {
                                try {
                                  _setLoading(true);
                                  final auth = FirebaseAuth.instance;
                                  // 이미 로그인 되어있는지 체크 (방어 코드)
                                  if (auth.currentUser == null) {
                                    // ⏳ 로딩 표시가 필요하다면 여기서 setState로 loading = true 처리
                                    await auth.signInAnonymously();
                                    debugPrint('✅ 익명 로그인 성공');
                                  }
                                  _setLoading(false);
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }

                                } on FirebaseAuthException catch (e) {
                                  _setLoading(false);
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
                                  _setLoading(false);
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
                  ),
                ),
              );
            },
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.2),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────── 버튼 위젯 ───────────
  Widget _loginButton({
    required String text,
    String? iconPath,
    IconData? iconData,
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
              child: iconPath != null 
                  ? Image.asset(iconPath, width: 20, height: 20)
                  : Icon(iconData, size: 24, color: textColor), // IconData fallback
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
    required BuildContext context,
    required String text,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
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
  required Function(bool) setLoading,
}) async {
  try {
    setLoading(true);
    debugPrint(">>> handleSignIn 시작 (${service.runtimeType})");
    await service.signIn();
    debugPrint(">>> service.signIn() 완료");
    setLoading(false);

    if (!context.mounted) return;

    if (Navigator.canPop(context)) {
      debugPrint(">>> Section1Screen 닫기 (Navigator.pop)");
      Navigator.pop(context);
    }
  } catch (e) {
    debugPrint(">>> handleSignIn 에러 발생: $e");
    setLoading(false);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('로그인 실패: $e')),
    );
  }
}

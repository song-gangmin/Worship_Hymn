import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Kakao
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';

// 필요시 SharedPreferences/Hive/secure storage 등 로컬캐시도 지울 수 있어요
import 'package:shared_preferences/shared_preferences.dart';

Future<void> appLogout() async {
  // 1) 소셜 먼저 끊기
  try { await GoogleSignIn.instance.disconnect(); } catch (_) {}
  try { await GoogleSignIn.instance.signOut();     } catch (_) {}

  try {
    await UserApi.instance.unlink(); // ✅ 가장 확실 (앱-계정 연결 해제)
  } catch (_) {
    try { await UserApi.instance.logout(); } catch (_) {}
    try { await TokenManagerProvider.instance.manager.clear(); } catch (_) {}
  }

  // 2) Firebase 세션 종료
  try { await FirebaseAuth.instance.signOut(); } catch (_) {}

  // 3) 로컬 캐시 초기화 (처음 설치 상태처럼)
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  } catch (_) {}
}

// lib/auth/logout_helper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../section1_screen.dart';

Future<void> appLogout(BuildContext context) async {
  // 1) 소셜 먼저 끊기
  try { await GoogleSignIn.instance.disconnect(); } catch (_) {}
  try { await GoogleSignIn.instance.signOut();     } catch (_) {}

  try { await UserApi.instance.unlink(); } catch (_) {
    try { await UserApi.instance.logout(); } catch (_) {}
    try { await TokenManagerProvider.instance.manager.clear(); } catch (_) {}
  }

  // 2) Firebase 세션 종료
  try { await FirebaseAuth.instance.signOut(); } catch (_) {}

  // 3) 로컬 캐시 정리 (필요 키만 제거)
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_uid');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_photo');
    // 필요 시 await prefs.clear();
  } catch (_) {}

  // 4) 라우팅 초기화 (authStateChanges 쓰면 생략 가능하지만 보조로 유지)
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Section1Screen()),
          (_) => false,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuth {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      // 필요 시 'https://www.googleapis.com/auth/userinfo.profile' 등 추가
    ],
    // serverClientId: 'YOUR_BACKEND_WEB_CLIENT_ID', // 서버에서 ID 토큰 검증할 때 사용(옵션)
  );

  static Future<GoogleSignInAccount?> signIn(BuildContext context) async {
    try {
      // 이미 로그인되어 있으면 그 계정 반환
      final current = await _googleSignIn.signInSilently();
      if (current != null) return current;

      // 로그인 플로우 시작
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // 사용자가 취소
        return null;
      }

      // 필요하면 인증 토큰/ID 토큰 얻기
      final auth = await account.authentication; // accessToken / idToken
      debugPrint('Google ID Token: ${auth.idToken}');
      debugPrint('Google Access Token: ${auth.accessToken}');

      // TODO: 서버 검증이 필요하면 auth.idToken을 백엔드로 전송
      return account;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google 로그인 실패: $e')),
      );
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  static Future<GoogleSignInAccount?> get currentUser async {
    return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  }
}

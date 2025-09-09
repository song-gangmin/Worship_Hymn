// kakao_auth.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../UserRepository.dart';
import '../auth/resualt_auth.dart';

class KakaoAuth implements AuthService {
  @override
  Future<AuthUser> signIn() async {
    // 1) 카카오 로그인 (앱이 설치되어 있으면 우선)
    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } catch (_) {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    // 2) Firebase Custom Token 발급 (Cloud Functions)
    final resp = await http.post(
      Uri.parse('https://asia-northeast3-worship-hymn.cloudfunctions.net/kakaoLogin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': token.accessToken}),
    );
    if (resp.statusCode != 200) {
      throw Exception('카카오 커스텀 토큰 발급 실패: ${resp.body}');
    }
    final firebaseCustomToken = jsonDecode(resp.body)['firebaseToken'] as String;

    // 3) Firebase 로그인
    final fbUserCred =
    await fb.FirebaseAuth.instance.signInWithCustomToken(firebaseCustomToken);
    final fb.User firebaseUser = fbUserCred.user!;

    // 4) 변환
    final authUser = AuthUser(
      uid: firebaseUser.uid,
      provider: AuthProvider.kakao,
      name: firebaseUser.displayName,
      email: firebaseUser.email,
      photoUrl: firebaseUser.photoURL,
    );

    await UserRepository().upsertUser(authUser);
    return authUser;
  }

  @override
  Future<void> signOut() async {
    try {
      await UserApi.instance.logout(); // 카카오 로그아웃
    } catch (_) {}
    await fb.FirebaseAuth.instance.signOut();
  }
}

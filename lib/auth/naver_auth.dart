import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';

import '../UserRepository.dart';
import '../auth/resualt_auth.dart'; // AuthUser, AuthService, AuthProvider 정의

class NaverAuth implements AuthService {
  @override
  Future<AuthUser> signIn() async {
    // 1) 네이버 로그인
    final res = await FlutterNaverLogin.logIn();
    if (res.status != NaverLoginStatus.loggedIn) {
      throw Exception('사용자가 네이버 로그인을 취소했습니다.');
    }

    // 2) 토큰 조회
    final token = await FlutterNaverLogin.getCurrentAccessToken();

    // 3) 서버(Cloud Functions)로 accessToken 전달 → Firebase Custom Token 받기
    // ※ 아래 URL은 본인 프로젝트/리전에 맞게 교체하세요.
    //    (Functions v1: https://<region>-<project>.cloudfunctions.net/naverLogin)
    //    (Functions v2 HTTPS: https://<region>-<project>.cloudfunctions.net/naverLogin 또는 run.app 형태)
    final resp = await http.post(
      Uri.parse('https://asia-northeast3-worship-hymn.cloudfunctions.net/naverLogin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': token.accessToken}),
    );
    if (resp.statusCode != 200) {
      throw Exception('커스텀 토큰 발급 실패: ${resp.body}');
    }
    final firebaseCustomToken = jsonDecode(resp.body)['firebaseToken'] as String;

    // 4) Firebase Auth 로그인
    final fbUserCred =
    await fb.FirebaseAuth.instance.signInWithCustomToken(firebaseCustomToken);
    final fb.User firebaseUser = fbUserCred.user!;

    // 5) Firebase User -> 우리 앱 공통 모델(AuthUser)로 변환
    final authUser = AuthUser(
      uid: firebaseUser.uid,
      provider: AuthProvider.naver,
      name: firebaseUser.displayName,
      email: firebaseUser.email,
      photoUrl: firebaseUser.photoURL,
    );

    // 6) Firestore upsert
    await UserRepository().upsertUser(authUser);

    return authUser;
  }

  @override
  Future<void> signOut() async {
    try {
      await FlutterNaverLogin.logOutAndDeleteToken(); // 네이버 토큰도 정리
    } catch (_) {}
    await fb.FirebaseAuth.instance.signOut();
  }
}

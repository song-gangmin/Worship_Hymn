// kakao_auth.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';

import '../services/user_data_migrator.dart';
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

    // 🔥 1) 기존(익명) 유저 보관
    final authInstance = fb.FirebaseAuth.instance;
    final prevUser = authInstance.currentUser;
    final String? anonUid =
    (prevUser != null && prevUser.isAnonymous) ? prevUser.uid : null;

    // 2) Firebase 로그인
    final fbUserCred =
    await authInstance.signInWithCustomToken(firebaseCustomToken);
    final fb.User firebaseUser = fbUserCred.user!;

    // 🔥 3) 익명 데이터 → 새 계정으로 마이그레이션
    if (anonUid != null && anonUid != firebaseUser.uid) {
      await UserDataMigrator().migrateAnonymousData(
        fromUid: anonUid,
        toUid: firebaseUser.uid,
      );
    }

    final kakaoUser = await UserApi.instance.me();
    final account = kakaoUser.kakaoAccount;

    // 4) 변환
    final authUser = AuthUser(
      uid: firebaseUser.uid,
      provider: AuthProvider.kakao,
      name: account?.profile?.nickname ?? '이름 없음',
      email: account?.email ?? '이메일 없음',
      photoUrl: account?.profile?.profileImageUrl,
    );

    await UserRepository().upsertUser(authUser);
    return authUser;
  }

  @override
  Future<void> signOut() async {
    try {
      // ✅ 가장 확실: 앱-계정 연결 자체 해제 (다음 로그인은 항상 새로)
      await UserApi.instance.unlink();
    } catch (_) {
      // unlink 실패 시: 로그아웃 + 토큰 캐시 비우기
      try { await UserApi.instance.logout(); } catch (_) {}
      try { await TokenManagerProvider.instance.manager.clear(); } catch (_) {}
    }
  }
}

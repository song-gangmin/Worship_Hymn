import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';

import 'package:worship_hymn/repositories//UserRepository.dart';
import '../auth/result_auth.dart';
import '../services/user_data_migrator.dart';

class NaverAuth implements AuthService {
  @override
  Future<AuthUser> signIn() async {
    // 1) 네이버 로그인
    final res = await FlutterNaverLogin.logIn();
    if (res.status != NaverLoginStatus.loggedIn) {
      throw Exception('사용자가 네이버 로그인을 취소했습니다.');
    }

    // ✅ account는 null 아님 (loggedIn 보장됨)
    final account = res.account!;
    print("NAVER ACCOUNT = id:${account.id}, "
        "email:${account.email}, "
        "name:${account.name}, "
        "nickname:${account.nickname}, "
        "profile:${account.profileImage}");

    // 2) 토큰 조회
    final token = await FlutterNaverLogin.getCurrentAccessToken();

    // 3) 서버(Cloud Functions)로 accessToken 전달 → Firebase Custom Token 발급
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
    // 🔥 1) 기존(익명) 유저 보관
    final authInstance = fb.FirebaseAuth.instance;
    final prevUser = authInstance.currentUser;
    final String? anonUid =
    (prevUser != null && prevUser.isAnonymous) ? prevUser.uid : null;

    // 2) Firebase Auth 로그인
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

    // 5) 이름 처리 (name > nickname > id 순서)
    final name = (account.name?.isNotEmpty == true)
        ? account.name
        : (account.nickname?.isNotEmpty == true
        ? account.nickname
        : account.id);

    // 6) Firebase User -> 공통 모델(AuthUser) 변환
    final authUser = AuthUser(
      uid: firebaseUser.uid,
      provider: AuthProvider.naver,
      name: name ?? "이름 없음",
      email: account.email ?? "이메일 없음",
      photoUrl: account.profileImage,
    );

    // 7) Firestore upsert
    print(">>> upsertUser 호출됨: ${authUser.uid}, ${authUser.name}, ${authUser.email}");
    await UserRepository().upsertUser(authUser);
    print(">>> upsertUser 완료");
    return authUser;
  }

  @override
  Future<void> signOut() async {
    try {
      await FlutterNaverLogin.logOutAndDeleteToken(); // 네이버 토큰 정리
    } catch (_) {}
    await fb.FirebaseAuth.instance.signOut();
  }
}

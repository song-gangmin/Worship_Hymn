import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';


import 'package:worship_hymn/repositories/UserRepository.dart';
import '../auth/result_auth.dart';
import '../services/user_data_migrator.dart';

class GoogleAuth implements AuthService {
  @override
  Future<AuthUser> signIn() async {
    final googleSignIn = GoogleSignIn.instance;

    // 초기화 (Web client ID 넣기)
    await googleSignIn.initialize(
      serverClientId:
      "800123758723-bqklphkptd2t5cpahu3kfocickl58rbp.apps.googleusercontent.com",
    );

    // 로그인
    final account = await googleSignIn.authenticate();
    if (account == null) {
      throw Exception('사용자가 Google 로그인을 취소했습니다.');
    }

    // 토큰 얻기
    final auth = await account.authentication;

    // Cloud Functions 호출 (커스텀 토큰 발급)
    final resp = await http.post(
      Uri.parse(
          'https://asia-northeast3-worship-hymn.cloudfunctions.net/googleLogin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': auth.idToken}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Google 커스텀 토큰 발급 실패: ${resp.body}');
    }
    final firebaseCustomToken =
    jsonDecode(resp.body)['firebaseToken'] as String;

    // Firebase 로그인
    // 🔥 1) 현재 유저(익명일 수 있음) 데이터 미리 수집
    final authInstance = fb.FirebaseAuth.instance;
    final prevUser = authInstance.currentUser;
    Map<String, dynamic>? migratedData;
    if (prevUser != null && prevUser.isAnonymous) {
      debugPrint("[GoogleAuth] collecting anonymous data for migration...");
      migratedData = await UserDataMigrator().collectData(prevUser.uid);
    }

    // 2) Firebase 로그인
    debugPrint("[GoogleAuth] signing in with custom token...");
    final fbUserCred = await authInstance.signInWithCustomToken(firebaseCustomToken);
    debugPrint("[GoogleAuth] firebase login success: ${fbUserCred.user}");
    final fb.User firebaseUser = fbUserCred.user!;

    // 🔥 3) 수집된 데이터가 있으면 마이그레이션 적용
    if (migratedData != null) {
      debugPrint("[GoogleAuth] applying migration to ${firebaseUser.uid}...");
      await UserDataMigrator().applyMigration(firebaseUser.uid, migratedData);
    }
    // ✅ AuthUser 생성 (uid는 Firebase, 나머지는 GoogleSignIn에서)
    final authUser = AuthUser(
      uid: firebaseUser.uid,
      provider: AuthProvider.google,
      name: account.displayName,
      email: account.email,
      photoUrl: account.photoUrl,
    );

    // (옵션) Firebase User에도 업데이트 → authStateChanges() 쓸 때 유용
    try {
      await firebaseUser.updateDisplayName(account.displayName);
      await firebaseUser.updatePhotoURL(account.photoUrl);
      await firebaseUser.reload();
    } catch (e) {
      debugPrint('[GoogleAuth] FirebaseUser update skipped: $e');
    }

    // DB 저장
    await UserRepository().upsertUser(authUser);

    return authUser;
  }

  @override
  Future<void> signOut() async {
    // 1) 연결 해제(계정 연결 자체 끊기) → 2) 로그아웃
    try { await GoogleSignIn.instance.disconnect(); } catch (_) {}
    try { await GoogleSignIn.instance.signOut();     } catch (_) {}
    // Firebase signOut은 공통 헬퍼에서 호출
  }
}

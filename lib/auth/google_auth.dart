import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../UserRepository.dart';
import '../auth/resualt_auth.dart';

class GoogleAuth implements AuthService {
  @override
  Future<AuthUser> signIn() async {
    final googleSignIn = GoogleSignIn.instance;

    // 초기화 (Web client ID 넣기)
    await googleSignIn.initialize(
      serverClientId:
      "800123758723-bqklphkptd2t5cpahu3kfocickl58rbp.apps.googleusercontent.com",
    );

    // ✅ 로그인 (signIn → authenticate 로 변경됨)
    final account = await googleSignIn.authenticate();
    if (account == null) {
      throw Exception('사용자가 Google 로그인을 취소했습니다.');
    }

    // 토큰 얻기
    final auth = await account.authentication;

    // Cloud Functions 호출
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
    final fbUserCred =
    await fb.FirebaseAuth.instance.signInWithCustomToken(firebaseCustomToken);
    final fb.User firebaseUser = fbUserCred.user!;

    // UserRepository 저장
    final authUser = AuthUser(
      uid: firebaseUser.uid,
      provider: AuthProvider.google,
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
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await fb.FirebaseAuth.instance.signOut();
  }
}

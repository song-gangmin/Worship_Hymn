import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../UserRepository.dart';
import '../auth/resualt_auth.dart';

class GoogleAuth implements AuthService {
  @override
  Future<AuthUser> signIn() async {
    // 1) Google 로그인
    final account = await GoogleSignIn.instance.authenticate();
    if (account == null) {
      throw Exception('사용자가 Google 로그인을 취소했습니다.');
    }
    final auth = await account.authentication;

    // 2) Cloud Functions 에서 Firebase Custom Token 발급
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

    // 3) Firebase 로그인
    final fbUserCred = await fb.FirebaseAuth.instance
        .signInWithCustomToken(firebaseCustomToken);
    final fb.User firebaseUser = fbUserCred.user!;

    // 4) 변환해서 Firestore 저장
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

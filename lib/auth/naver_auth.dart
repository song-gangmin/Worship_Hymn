import 'package:flutter_naver_login/flutter_naver_login.dart' as nv;
import 'resualt_auth.dart';

class NaverAuth implements AuthService {
  @override
  Future<AuthUser> signIn() async {
    try {
      final result = await nv.FlutterNaverLogin.logIn();
      if (result.status != nv.NaverLoginStatus.loggedIn) {
        throw AuthException('canceled', '사용자가 취소');
      }
      final token = await nv.FlutterNaverLogin.currentAccessToken;
      final profile = await nv.FlutterNaverLogin.currentAccount();

      return AuthUser(
        uid: profile.id ?? '',
        provider: AuthProvider.naver,
        name: profile.name,
        email: profile.email,
        photoUrl: profile.profileImage,
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );
    } catch (e) {
      throw AuthException('unknown', 'Naver 로그인 실패: $e');
    }
  }

  @override
  Future<void> signOut() => nv.FlutterNaverLogin.logOut();
}

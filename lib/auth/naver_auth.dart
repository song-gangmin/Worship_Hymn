import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'resualt_auth.dart';

class NaverAuth implements AuthService {
  @override
  Future<AuthUser> signIn() async {
    try {
      final login = await FlutterNaverLogin.logIn();
      if (login.status != NaverLoginStatus.loggedIn) {
        throw AuthException('canceled', '사용자가 네이버 로그인을 취소했습니다.');
      }

      final token = await FlutterNaverLogin.getCurrentAccessToken();
      final account = login.account ?? await FlutterNaverLogin.getCurrentAccount();

      return AuthUser(
        uid: account.id ?? '',
        provider: AuthProvider.naver,
        name: (account.name?.isNotEmpty ?? false) ? account.name : account.nickname,
        email: account.email,
        photoUrl: account.profileImage,
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );
    } catch (e) {
      throw AuthException('unknown', '네이버 로그인 실패: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await FlutterNaverLogin.logOut();
    } catch (_) {}
  }

  // 선택: 토큰까지 완전 삭제
  Future<void> disconnect() async {
    try {
      await FlutterNaverLogin.logOutAndDeleteToken();
    } catch (_) {}
  }

  // 선택: 현재 토큰 유효 여부
  Future<bool> isLoggedIn() async {
    try {
      final t = await FlutterNaverLogin.getCurrentAccessToken();
      return t.isValid();
    } catch (_) {
      return false;
    }
  }
}

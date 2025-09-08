import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kk;
import 'resualt_auth.dart';

class KakaoAuth implements AuthService {
  @override
  Future<AuthUser> signIn() async {
    try {
      kk.OAuthToken token;
      if (await kk.isKakaoTalkInstalled()) {
        try {
          token = await kk.UserApi.instance.loginWithKakaoTalk();
        } catch (_) {
          token = await kk.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kk.UserApi.instance.loginWithKakaoAccount();
      }

      final me = await kk.UserApi.instance.me();
      return AuthUser(
        uid: '${me.id}',
        provider: AuthProvider.kakao,
        name: me.kakaoAccount?.profile?.nickname,
        email: me.kakaoAccount?.email,
        photoUrl: me.kakaoAccount?.profile?.profileImageUrl,
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );
    } on kk.KakaoAuthException catch (e) {
      throw AuthException('canceled', '로그인 취소/실패: ${e.message}');
    } on kk.KakaoClientException catch (e) {
      throw AuthException('network', '네트워크 오류: ${e.message}');
    } catch (e) {
      throw AuthException('unknown', 'Kakao 로그인 실패: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await kk.UserApi.instance.logout(); // 토큰 무효화(클라이언트)
    } catch (_) {}
  }
}

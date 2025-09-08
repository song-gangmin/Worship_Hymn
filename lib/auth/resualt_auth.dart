enum AuthProvider { google, kakao, naver }

class AuthUser {
  final String uid;              // 공급자 고유 ID
  final String? name;
  final String? email;
  final String? photoUrl;

  // 토큰 모음 (필요한 것만 사용)
  final String? idToken;         // Google: idToken, Kakao: idToken 유사개념 X
  final String? accessToken;     // 공통 accessToken
  final String? refreshToken;

  final AuthProvider provider;

  AuthUser({
    required this.uid,
    required this.provider,
    this.name,
    this.email,
    this.photoUrl,
    this.idToken,
    this.accessToken,
    this.refreshToken,
  });
}

// 표준화된 예외: UI에서 한결같이 처리 가능
class AuthException implements Exception {
  final String code;     // e.g. "canceled", "network", "config", "unknown"
  final String message;
  AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException($code): $message';
}

// 공통 인터페이스
abstract class AuthService {
  Future<AuthUser> signIn();
  Future<void> signOut();
}

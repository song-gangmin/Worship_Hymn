import 'package:google_sign_in/google_sign_in.dart';
import 'resualt_auth.dart';

class GoogleAuth implements AuthService {
  final GoogleSignIn _signIn = GoogleSignIn.instance;

  @override
  Future<AuthUser> signIn() async {
    try {
      final account = await _signIn.authenticate();
      if (account == null) throw AuthException('canceled', '사용자가 취소');

      final auth = await account.authentication;
      return AuthUser(
        uid: account.id,
        provider: AuthProvider.google,
        name: account.displayName,
        email: account.email,
        photoUrl: account.photoUrl,
        idToken: auth.idToken,
        accessToken: auth.idToken,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('unknown', 'Google 로그인 실패: $e');
    }
  }

  @override
  Future<void> signOut() => _signIn.signOut();
}

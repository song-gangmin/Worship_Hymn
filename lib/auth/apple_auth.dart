import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:worship_hymn/auth/result_auth.dart';
import 'package:worship_hymn/repositories/UserRepository.dart';
import '../services/user_data_migrator.dart';

class AppleAuth implements AuthService {
  @override
  Future<AuthUser> signIn() async {
    // 1. Get credential from Apple
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    // 2. Create Firebase credential
    final fb.OAuthProvider oAuthProvider = fb.OAuthProvider('apple.com');
    final fb.OAuthCredential credential = oAuthProvider.credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    // 3. User Data Migration (Pre-Login)
    final authInstance = fb.FirebaseAuth.instance;
    final prevUser = authInstance.currentUser;
    Map<String, dynamic>? migratedData;
    if (prevUser != null && prevUser.isAnonymous) {
      migratedData = await UserDataMigrator().collectData(prevUser.uid);
    }

    // 4. Sign in to Firebase
    final fbUserCred = await authInstance.signInWithCredential(credential);
    final fb.User firebaseUser = fbUserCred.user!;

    // 5. Apply Migration (Post-Login)
    if (migratedData != null) {
      await UserDataMigrator().applyMigration(firebaseUser.uid, migratedData);
    }

    // 6. Handle User Name (Apple only sends it on first login)
    String? name = firebaseUser.displayName;
    if ((name == null || name.isEmpty) && appleCredential.givenName != null) {
      name = '${appleCredential.familyName ?? ""} ${appleCredential.givenName ?? ""}'.trim();
      if (name.isNotEmpty) {
        await firebaseUser.updateDisplayName(name);
      }
    }

    // 7. Create AuthUser
    final authUser = AuthUser(
      uid: firebaseUser.uid,
      provider: AuthProvider.apple,
      name: (name != null && name.isNotEmpty) ? name : '이름 없음',
      email: firebaseUser.email ?? '이메일 없음',
      // Apple does not standardized photoURL in the same way, usually null
      photoUrl: firebaseUser.photoURL,
    );

    await UserRepository().upsertUser(authUser);
    return authUser;
  }

  @override
  Future<void> signOut() async {
    await fb.FirebaseAuth.instance.signOut();
  }
}

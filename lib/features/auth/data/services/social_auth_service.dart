import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/social_auth_config.dart';
import '../../../../core/services/supabase_service.dart';

class SocialAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInitialization;

  Future<AuthResponse> signInWithGoogle() async {
    _googleInitialization ??= _googleSignIn.initialize(
      clientId: SocialAuthConfig.googleIosClientId.isEmpty
          ? null
          : SocialAuthConfig.googleIosClientId,
      serverClientId: SocialAuthConfig.googleWebClientId.isEmpty
          ? null
          : SocialAuthConfig.googleWebClientId,
    );
    await _googleInitialization;

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const AuthException('Google ile giriş bu platformda desteklenmiyor.');
    }

    late final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } catch (error) {
      if (_isCancellation(error)) throw const SocialAuthCancelledException();
      rethrow;
    }
    final authorization = await account.authorizationClient
        .authorizationForScopes(const <String>[]);
    final idToken = account.authentication.idToken;
    final accessToken = authorization?.accessToken;

    if (idToken == null || accessToken == null) {
      throw const AuthException('Google kimlik bilgileri alınamadı.');
    }

    final response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    await _ensureProfile(response.user);
    return response;
  }

  Future<AuthResponse> signInWithApple() async {
    if (kIsWeb || !(await SignInWithApple.isAvailable())) {
      throw const AuthException('Apple ile giriş bu platformda desteklenmiyor.');
    }

    final rawNonce = supabase.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    late final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } catch (error) {
      if (_isCancellation(error)) throw const SocialAuthCancelledException();
      rethrow;
    }
    final idToken = credential.identityToken;

    if (idToken == null) {
      throw const AuthException('Apple kimlik bilgileri alınamadı.');
    }

    final response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
    await _ensureProfile(response.user);
    return response;
  }

  Future<void> _ensureProfile(User? user) async {
    if (user == null) return;

    final existing = await supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) return;

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName = (metadata['full_name'] ??
            metadata['name'] ??
            [metadata['given_name'], metadata['family_name']]
                .whereType<String>()
                .join(' '))
        .toString()
        .trim();

    try {
      await supabase.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'full_name': fullName.isEmpty ? 'Yeni kullanıcı' : fullName,
        'role': 'student',
        'onboarding_completed': false,
      });
    } catch (_) {
      // A database trigger may have created the row between select and insert.
      // Do not overwrite an existing profile or role.
    }
  }

  Future<void> signOutProviderSessions() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Supabase sign-out remains authoritative for the app session.
    }
  }

  bool _isCancellation(Object error) {
    final value = error.toString().toLowerCase();
    return value.contains('cancel') || value.contains('dismiss');
  }
}

class SocialAuthCancelledException implements Exception {
  const SocialAuthCancelledException();
}

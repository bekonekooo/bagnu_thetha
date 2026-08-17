/// Configure these values with `--dart-define` for native social sign-in.
/// No client IDs or private credentials are stored in the repository.
class SocialAuthConfig {
  static const googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  const SocialAuthConfig._();
}

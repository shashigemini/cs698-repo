import 'package:envied/envied.dart';

part 'env.g.dart';

/// Securely obfuscates environment variables using `envied`.
@Envied(path: '.env')
abstract class Env {
  /// Base API URL (obfuscated)
  @EnviedField(varName: 'API_BASE_URL', obfuscate: true)
  static final String apiBaseUrl = _Env.apiBaseUrl;

  /// Android package name
  @EnviedField(varName: 'ANDROID_PACKAGE_NAME', obfuscate: true)
  static final String androidPackageName = _Env.androidPackageName;

  /// Android signing certificate hash
  @EnviedField(varName: 'ANDROID_CERT_HASH', obfuscate: true)
  static final String androidCertHash = _Env.androidCertHash;

  /// iOS bundle ID
  @EnviedField(varName: 'IOS_BUNDLE_ID', obfuscate: true)
  static final String iosBundleId = _Env.iosBundleId;

  /// iOS Team ID
  @EnviedField(varName: 'IOS_TEAM_ID', obfuscate: true)
  static final String iosTeamId = _Env.iosTeamId;

  /// Watcher mail for security alerts
  @EnviedField(varName: 'SECURITY_WATCHER_MAIL', obfuscate: true)
  static final String securityWatcherMail = _Env.securityWatcherMail;

  /// SHA-256 fingerprint for SSL pinning
  @EnviedField(varName: 'SSL_CERT_FINGERPRINT', obfuscate: true)
  static final String sslCertFingerprint = _Env.sslCertFingerprint;

  /// Flag to enable/disable SSL pinning
  @EnviedField(varName: 'USE_SSL_PINNING', defaultValue: 'false')
  static final bool useSslPinning = _Env.useSslPinning;
}

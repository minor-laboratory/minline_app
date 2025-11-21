import 'env.dev.dart';
import 'env_fields.dart';

class AppEnv {
  static AppEnvFields get instance {
    const mode = String.fromEnvironment('mode', defaultValue: 'dev');
    switch (mode) {
      case 'dev':
        return EnvDev();
      default:
        return EnvDev();
    }
  }

  // 간편한 접근을 위한 getter들
  static String get supabaseUrl => instance.supabaseUrl;
  static String get supabaseAnonKey => instance.supabaseAnonKey;
  static String get revenueCatApiKeyIos => instance.revenueCatApiKeyIos;
  static String get revenueCatApiKeyAndroid => instance.revenueCatApiKeyAndroid;
}

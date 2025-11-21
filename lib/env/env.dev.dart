import 'package:envied/envied.dart';
import 'env_fields.dart';

part 'env.dev.g.dart';

@Envied(path: '.env.dev')
class EnvDev implements AppEnvFields {
  @override
  @EnviedField(varName: 'SUPABASE_URL')
  final String supabaseUrl = _EnvDev.supabaseUrl;

  @override
  @EnviedField(varName: 'SUPABASE_ANON_KEY', obfuscate: true)
  final String supabaseAnonKey = _EnvDev.supabaseAnonKey;

  @override
  @EnviedField(varName: 'REVENUECAT_API_KEY_IOS', defaultValue: '')
  final String revenueCatApiKeyIos = _EnvDev.revenueCatApiKeyIos;

  @override
  @EnviedField(varName: 'REVENUECAT_API_KEY_ANDROID', defaultValue: '')
  final String revenueCatApiKeyAndroid = _EnvDev.revenueCatApiKeyAndroid;
}

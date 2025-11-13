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
}

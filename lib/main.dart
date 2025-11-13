import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

import 'core/database/database_service.dart';
import 'core/services/sync/lifecycle_service.dart';
import 'core/utils/logger.dart';
import 'env/app_env.dart';
import 'router/app_router.dart';

void main() async {
  // 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // easy_localization 초기화
  await EasyLocalization.ensureInitialized();

  // Isar Database 초기화 (로컬 데이터베이스)
  await DatabaseService.instance.init();

  // MinorLab Common SupabaseService 초기화 (내부에서 Supabase도 초기화됨)
  await common.SupabaseService.initialize(
    common.SupabaseConfig.development(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    ),
  );
  logger.i('Supabase initialized successfully');

  // Supabase 세션 복구 대기 (저장된 토큰에서 사용자 정보 복구)
  // 첫 번째 auth state change 이벤트까지 대기 (세션 복구 완료 신호)
  await Supabase.instance.client.auth.onAuthStateChange.first;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // 초기화 완료 후 동기화 서비스 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // LifecycleService 초기화 (Provider ref와 함께)
      ref.read(lifecycleServiceProvider).initialize();
      logger.i('[Main] LifecycleService initialized');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MiniLine',
      theme: common.AppTheme.lightTheme(
        seedColor: const Color(0xFF5B6CF6),
      ),
      darkTheme: common.AppTheme.darkTheme(
        seedColor: const Color(0xFF5B6CF6),
      ),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/database/database_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/local_notification_service.dart';
import 'firebase_options.dart';
import 'core/services/share_activity_service.dart';
import 'core/services/share_handler_provider.dart';
import 'core/services/share_handler_service.dart';
import 'core/services/sync/lifecycle_service_provider.dart';
import 'core/utils/logger.dart';
import 'env/app_env.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/share/presentation/pages/share_input_page.dart';
import 'router/app_router.dart' as router;

void main() async {
  // 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // easy_localization 초기화
  await EasyLocalization.ensureInitialized();

  // Isar Database 초기화 (로컬 데이터베이스)
  await DatabaseService.instance.init();

  // Firebase 초기화 (FCM, Crashlytics 사용)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  logger.i('Firebase initialized successfully');

  // Crashlytics 초기화 (릴리즈 빌드에서 에러 추적)
  if (kReleaseMode) {
    // Flutter 프레임워크 에러를 Crashlytics로 전송
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // 비동기 에러를 Crashlytics로 전송
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    logger.i('Crashlytics initialized for release mode');
  }

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
      child: const KeyboardDismissOnTap(child: ProviderScope(child: MyApp())),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isCheckingShareActivity = true;
  bool _isShareActivity = false;
  Map<String, dynamic>? _sharedData;

  @override
  void initState() {
    super.initState();

    // ShareHandlerService에 Navigator Key 설정 (app_router에서)
    ShareHandlerService.navigatorKey = router.navigatorKey;

    // ShareActivity 확인 (build 전에 완료)
    _checkShareActivity();
  }

  /// ShareActivity 여부 확인 및 데이터 로드
  Future<void> _checkShareActivity() async {
    final isShare = await ShareActivityService.isShareActivity();

    if (isShare) {
      logger.i('[Main] Started from ShareActivity');
      final sharedData = await ShareActivityService.getSharedData();
      logger.d('[Main] Shared data: $sharedData');

      setState(() {
        _sharedData = sharedData;
        _isShareActivity = true;
        _isCheckingShareActivity = false;
      });
    } else {
      logger.i('[Main] Started from MainActivity');

      setState(() {
        _isCheckingShareActivity = false;
      });

      // 일반 서비스 초기화
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await LocalNotificationService().initialize();
        await FcmService().initialize(); // FCM 초기화 (토큰 가져오기)
        ref.read(lifecycleServiceProvider).initialize();
        ref.read(shareHandlerServiceProvider).initialize();
        logger.i('[Main] All services initialized');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ShareActivity 확인 중일 때 로딩 화면 표시 (빈 화면)
    if (_isCheckingShareActivity) {
      return const MaterialApp(
        home: Scaffold(
          body: SizedBox.shrink(),
        ),
      );
    }

    // ShareActivity일 때 전용 UI 표시
    if (_isShareActivity && _sharedData != null) {
      // 기본 Shadcn 테마 생성
      final shadLightTheme = common.MinorLabShadTheme.lightTheme(
        paletteId: 'zinc',
        backgroundOption: common.BackgroundColorOption.defaultColor,
      );
      final shadDarkTheme = common.MinorLabShadTheme.darkTheme(
        paletteId: 'zinc',
        backgroundOption: common.BackgroundColorOption.defaultColor,
      );

      return ShadApp.custom(
        themeMode: ThemeMode.system,
        theme: shadLightTheme,
        darkTheme: shadDarkTheme,
        appBuilder: (appContext) {
          final materialTheme = Theme.of(appContext);
          return MaterialApp(
            theme: materialTheme,
            darkTheme: materialTheme,
            themeMode: ThemeMode.system,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: ShareInputPage(
              directData: _sharedData,
              isFromShareActivity: true,
            ),
          );
        },
      );
    }

    final themeModeAsync = ref.watch(themeModeProvider);
    final colorThemeAsync = ref.watch(colorThemeProvider);
    final backgroundColorAsync = ref.watch(backgroundColorProvider);
    final localeAsync = ref.watch(localeProvider);

    return themeModeAsync.when(
      data: (themeMode) => colorThemeAsync.when(
        data: (colorTheme) => backgroundColorAsync.when(
          data: (backgroundOption) {
            // Shadcn UI 테마 생성 (배경색 옵션 적용)
            final shadLightTheme = common.MinorLabShadTheme.lightTheme(
              paletteId: colorTheme,
              backgroundOption: backgroundOption,
            );
            final shadDarkTheme = common.MinorLabShadTheme.darkTheme(
              paletteId: colorTheme,
              backgroundOption: backgroundOption,
            );

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: themeMode == ThemeMode.dark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: themeMode == ThemeMode.dark
                    ? Brightness.dark
                    : Brightness.light,
                systemNavigationBarContrastEnforced: false,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: themeMode == ThemeMode.dark
                    ? Brightness.light
                    : Brightness.dark,
                systemStatusBarContrastEnforced: false,
              ),
              child: ShadApp.custom(
                themeMode: themeMode,
                theme: shadLightTheme,
                darkTheme: shadDarkTheme,
                appBuilder: (context) {
                  // ShadApp이 자동으로 생성한 Material Theme 사용
                  final materialTheme = Theme.of(context);

                  return MaterialApp.router(
                    title: 'MiniLine',
                    theme: materialTheme,
                    darkTheme: materialTheme,
                    themeMode: themeMode,
                    routerConfig: router.appRouter,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    locale: localeAsync.value ?? context.locale,
                    builder: (context, child) {
                      return ShadAppBuilder(child: child!);
                    },
                  );
                },
              ),
            );
          },
          loading: () => MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          ),
          error: (error, stack) {
            final shadLightTheme = common.MinorLabShadTheme.lightTheme(
              paletteId: colorTheme,
              backgroundOption: common.BackgroundColorOption.defaultColor,
            );
            final shadDarkTheme = common.MinorLabShadTheme.darkTheme(
              paletteId: colorTheme,
              backgroundOption: common.BackgroundColorOption.defaultColor,
            );

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: themeMode == ThemeMode.dark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: themeMode == ThemeMode.dark
                    ? Brightness.dark
                    : Brightness.light,
                systemNavigationBarContrastEnforced: false,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: themeMode == ThemeMode.dark
                    ? Brightness.light
                    : Brightness.dark,
                systemStatusBarContrastEnforced: false,
              ),
              child: ShadApp.custom(
                themeMode: themeMode,
                theme: shadLightTheme,
                darkTheme: shadDarkTheme,
                appBuilder: (appContext) {
                  final materialTheme = Theme.of(appContext);
                  return MaterialApp.router(
                    title: 'MiniLine',
                    theme: materialTheme,
                    darkTheme: materialTheme,
                    themeMode: themeMode,
                    routerConfig: router.appRouter,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    locale: localeAsync.value ?? context.locale,
                    builder: (context, child) {
                      return ShadAppBuilder(child: child!);
                    },
                  );
                },
              ),
            );
          },
        ),
        loading: () => MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
        error: (error, stack) {
          final shadLightTheme = common.MinorLabShadTheme.lightTheme(
            paletteId: 'zinc',
            backgroundOption: common.BackgroundColorOption.defaultColor,
          );
          final shadDarkTheme = common.MinorLabShadTheme.darkTheme(
            paletteId: 'zinc',
            backgroundOption: common.BackgroundColorOption.defaultColor,
          );

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: themeMode == ThemeMode.dark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: themeMode == ThemeMode.dark
                  ? Brightness.dark
                  : Brightness.light,
              systemNavigationBarContrastEnforced: false,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarIconBrightness: themeMode == ThemeMode.dark
                  ? Brightness.light
                  : Brightness.dark,
              systemStatusBarContrastEnforced: false,
            ),
            child: ShadApp.custom(
              themeMode: themeMode,
              theme: shadLightTheme,
              darkTheme: shadDarkTheme,
              appBuilder: (appContext) {
                final materialTheme = Theme.of(appContext);
                return MaterialApp.router(
                  title: 'MiniLine',
                  theme: materialTheme,
                  darkTheme: materialTheme,
                  themeMode: themeMode,
                  routerConfig: router.appRouter,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: localeAsync.value ?? context.locale,
                  builder: (context, child) {
                    return ShadAppBuilder(child: child!);
                  },
                );
              },
            ),
          );
        },
      ),
      loading: () => MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stack) {
        final shadLightTheme = common.MinorLabShadTheme.lightTheme(
          paletteId: 'zinc',
          backgroundOption: common.BackgroundColorOption.defaultColor,
        );
        final shadDarkTheme = common.MinorLabShadTheme.darkTheme(
          paletteId: 'zinc',
          backgroundOption: common.BackgroundColorOption.defaultColor,
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarContrastEnforced: false,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemStatusBarContrastEnforced: false,
          ),
          child: ShadApp.custom(
            themeMode: ThemeMode.system,
            theme: shadLightTheme,
            darkTheme: shadDarkTheme,
            appBuilder: (appContext) {
              final materialTheme = Theme.of(appContext);
              return MaterialApp.router(
                title: 'MiniLine',
                theme: materialTheme,
                darkTheme: materialTheme,
                themeMode: ThemeMode.system,
                routerConfig: router.appRouter,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                builder: (context, child) {
                  return ShadAppBuilder(child: child!);
                },
              );
            },
          ),
        );
      },
    );
  }
}

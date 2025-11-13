import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

import 'core/database/database_service.dart';
import 'core/utils/logger.dart';
import 'env/app_env.dart';

void main() async {
  // 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

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
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MiniLine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'MiniLine Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

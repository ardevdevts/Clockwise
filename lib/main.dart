import 'package:financialtracker/core/routes/routes.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart';
import 'core/services/workmanager_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/providers.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  final workManagerService = WorkManagerService();
  await workManagerService.initialize();

  // Initialize auth service
  final authService = AuthService();
  await authService.initialize();

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final syncService = ref.read(syncServiceProvider);
    final authService = ref.read(authServiceProvider);

    if (state == AppLifecycleState.resumed && authService.isAuthenticated) {
      // Sync when app comes to foreground
      syncService.sync();
    } else if (state == AppLifecycleState.paused) {
      // Disconnect when app goes to background
      syncService.disconnect();
    }
  }

  Future<void> _initializeSync() async {
    final syncService = ref.read(syncServiceProvider);
    final authService = ref.read(authServiceProvider);

    // Initialize sync service
    await syncService.initialize();

    // If authenticated, connect and perform initial sync
    if (authService.isAuthenticated) {
      await syncService.connect();
      await syncService.sync(fullSync: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AuthState>(authStateProvider, (previous, next) async {
      final syncService = ref.read(syncServiceProvider);

      if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        // User just logged in - connect and sync
        await syncService.connect();
        await syncService.sync(fullSync: true);
      } else if (!next.isAuthenticated &&
          (previous?.isAuthenticated ?? false)) {
        // User just logged out - disconnect
        await syncService.disconnect();
      }
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ClockWise',
      theme: themeDark,
      routerConfig: appRouter,
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('pt', 'PT'),
        Locale('fr', 'FR'),
        Locale('de', 'DE'),
        Locale('it', 'IT'),
        Locale('ja', 'JP'),
        Locale('ko', 'KR'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
      ],
    );
  }
}

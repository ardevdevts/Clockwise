import 'package:financialtracker/core/routes/routes.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart';
import 'core/services/workmanager_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  
  final workManagerService = WorkManagerService();
  await workManagerService.initialize();
  
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Taskie',
      theme: themeDark,
      routerConfig: appRouter,
    );
  }
}

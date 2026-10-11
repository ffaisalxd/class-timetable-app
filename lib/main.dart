import 'package:flutter/material.dart';
import 'pages/splash_page.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();
  await MessagingService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Timetable App',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
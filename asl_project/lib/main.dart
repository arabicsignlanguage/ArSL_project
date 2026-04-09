import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers/app_provider.dart';
// 🟢 استيراد ملف الـ Splash بدلاً من الـ Welcome
import 'screens/main_app/splash_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error: $e');
  }
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
      child: const SignLanguageApp(),
    ),
  );
}

class SignLanguageApp extends StatelessWidget {
  const SignLanguageApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryDark = Color(0xFF0D3146);
    const Color primaryLight = Color(0xFF395B6F);
    const Color accentColor = Color(0xFF958979);
    const Color bgColor = Color(0xFFEBE3D5);

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ArSL Interpreter',
          themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: bgColor,
            appBarTheme: const AppBarTheme(backgroundColor: primaryDark, foregroundColor: Colors.white, elevation: 0),
            colorScheme: ColorScheme.fromSeed(seedColor: primaryDark, primary: primaryDark, secondary: accentColor),
            fontFamily: 'Arial',
          ),
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: const Color(0xFF0A1922),
            cardColor: const Color(0xFF122C3D),
            appBarTheme: const AppBarTheme(backgroundColor: primaryDark, foregroundColor: Colors.white),
            colorScheme: const ColorScheme.dark(primary: primaryLight, secondary: accentColor, surface: Color(0xFF122C3D)),
            textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white), bodyMedium: TextStyle(color: Colors.white70)),
          ),
          locale: Locale(provider.currentLang.substring(0, 2)),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar'), Locale('en'), Locale('ja'), Locale('zh'),
            Locale('de'), Locale('tr'), Locale('ko'), Locale('fr'),
            Locale('es'), Locale('ru'),
          ],
          // 🟢 تشغيل شاشة البداية أولاً
          home: const SplashScreen(),
        );
      },
    );
  }
}
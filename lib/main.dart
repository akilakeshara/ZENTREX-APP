import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main_layout.dart';
import 'config_manager.dart';
import 'settings_manager.dart';
import 'data_usage_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ConfigManager.instance.init(); // Initialize asynchronously
  SettingsManager.instance.init();
  DataUsageManager.instance.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ZentrexApp());
}

class ZentrexApp extends StatelessWidget {
  const ZentrexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZENTREX',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const MainLayout(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'services/store_config_service.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  // Check if store is configured
  final isConfigured = await StoreConfigService.isConfigured();

  runApp(GoldiCardApp(isConfigured: isConfigured));
}

class GoldiCardApp extends StatelessWidget {
  final bool isConfigured;

  const GoldiCardApp({super.key, required this.isConfigured});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goldi Card',
      debugShowCheckedModeBanner: false,
      theme: GoldiTheme.themeData,
      home: isConfigured ? const HomeScreen() : const SetupScreen(),
    );
  }
}

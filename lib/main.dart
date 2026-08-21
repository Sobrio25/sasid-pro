import 'package:flutter/material.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SasidApp());
}

class SasidApp extends StatelessWidget {
  const SasidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SASID A - Espectros Sísmicos CDMX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}

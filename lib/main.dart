import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/claim_repository.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const ClaimApp());
}

class ClaimApp extends StatelessWidget {
  const ClaimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClaimRepository(),
      child: MaterialApp(
        title: 'Insurance Claims',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFFF5F7FA),
          ),
          cardTheme: const CardThemeData(
            surfaceTintColor: Colors.white,
            margin: EdgeInsets.zero,
          ),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}

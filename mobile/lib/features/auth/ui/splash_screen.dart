import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.forest,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

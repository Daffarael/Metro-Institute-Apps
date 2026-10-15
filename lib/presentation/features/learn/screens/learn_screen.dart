import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Belajar')),
      body: const Center(child: Text('Learn Screen â€” TODO')),
    );
  }
}


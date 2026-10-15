import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tantangan')),
      body: const Center(child: Text('Challenge Screen â€” TODO')),
    );
  }
}


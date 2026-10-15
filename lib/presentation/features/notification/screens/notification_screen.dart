import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifikasi')),
      body: const Center(child: Text('Notification Screen â€” TODO')),
    );
  }
}


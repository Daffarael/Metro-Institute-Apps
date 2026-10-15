import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sertifikat')),
      body: const Center(child: Text('Certificate Screen â€” TODO')),
    );
  }
}


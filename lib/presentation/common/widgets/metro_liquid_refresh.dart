import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

/// MetroLiquidRefresh
///
/// Komponen Pull-to-Refresh fluida elastis (Liquid Droplet) berkualitas tinggi:
/// • Menggunakan pustaka resmi LiquidPullToRefresh (Ramotion concept).
/// • Animasi cairan tetesan (liquid droplet / wave) yang meregang halus dari atas.
/// • Fisika pegas (spring bounce) saat ditarik dan dilepas.
/// • Skema warna terintegrasi sempurna dengan Metro Institute:
///   - Warna Cairan: Metro Green (#018556)
///   - Warna Background Indikator: Light Warm Canvas (#FAF9F5) atau Putih
/// • Bergerak mulus pada 60/120 FPS tanpa menyebabkan pergeseran layout aneh
///   atau menutupi teks header.
class MetroLiquidRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color color;
  final Color backgroundColor;
  final double height;
  final bool showChildOpacityTransition;

  const MetroLiquidRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color = const Color(0xFF018556), // Metro Green
    this.backgroundColor = const Color(0xFFFAF9F5), // Metro Canvas
    this.height = 70.0,
    this.showChildOpacityTransition = false,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidPullToRefresh(
      onRefresh: onRefresh,
      color: color,
      backgroundColor: backgroundColor,
      height: height,
      animSpeedFactor: 1.6,
      springAnimationDurationInMilliseconds: 500,
      showChildOpacityTransition: showChildOpacityTransition,
      child: child,
    );
  }
}

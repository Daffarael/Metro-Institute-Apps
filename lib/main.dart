import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/di/injection_container.dart' as di;
import 'core/network/api_client.dart';
import 'core/services/fcm_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Instant in-memory DI & HTTP client setup (< 5ms)
  await ApiClient.init();
  await di.init();

  // Launch UI immediately so the white screen is just ~1 second native startup
  runApp(const MetroInstituteApp());

  // Non-blocking background initializations (run in parallel without holding the splash screen)
  initializeDateFormatting('id_ID', null).catchError((_) {});
  initializeDateFormatting('id', null).catchError((_) {});
  FcmService.init().catchError((e) {
    debugPrint('FCM init error: $e');
  });
}

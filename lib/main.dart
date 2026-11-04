import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/di/injection_container.dart' as di;
import 'core/network/api_client.dart';
import 'core/services/fcm_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Future.wait([
      initializeDateFormatting('id_ID', null),
      initializeDateFormatting('id', null),
    ]);
  } catch (_) {}
  await ApiClient.init();
  await di.init();
  await FcmService.init();
  runApp(const MetroInstituteApp());
}

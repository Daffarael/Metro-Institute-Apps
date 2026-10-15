import 'package:flutter/material.dart';
import 'core/di/injection_container.dart' as di;
import 'core/network/api_client.dart';
import 'core/services/fcm_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.init();
  await di.init();
  await FcmService.init();
  runApp(const MetroInstituteApp());
}

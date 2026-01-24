import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:getrebate/app/app.dart';
import 'package:getrebate/app/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
    // Initialize Local Notifications
    await NotificationService().initialize();
    
  } catch (e) {
    print('⚠️ Firebase/Notification initialization failed: $e');
  }

  runApp(const MyApp());
}

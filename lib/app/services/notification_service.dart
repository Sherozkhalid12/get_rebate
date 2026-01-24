import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getrebate/app/models/notification_model.dart' as model;
import 'package:getrebate/app/utils/api_constants.dart';

class NotificationServiceException implements Exception {
  final String message;
  final int? statusCode;

  NotificationServiceException({required this.message, this.statusCode});

  @override
  String toString() => 'NotificationServiceException: $message (Status: $statusCode)';
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  late final Dio _dio;
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // General initialization settings
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // Initialize local notifications
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        if (kDebugMode) {
          print('🔔 Notification tapped: ${details.payload}');
        }
      },
    );

    // Create high importance channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _isInitialized = true;
    if (kDebugMode) {
      print('✅ NotificationService initialized');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('🔔 Received foreground notification: ${message.notification?.title}');
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // If `onMessage` is triggered with a notification, construct our own
    // local notification to show to users using the created channel.
    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: android.smallIcon,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  /// Fetches notifications for a given user ID
  Future<model.NotificationResponse> getNotifications(String userId) async {
    try {
      final storage = GetStorage();
      final authToken = storage.read('auth_token');

      final headers = <String, String>{
        ...ApiConstants.ngrokHeaders,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final endpoint = ApiConstants.getNotificationsEndpoint(userId);
      // Remove base URL if present to get relative path
      final path = endpoint.replaceFirst(ApiConstants.apiBaseUrl, '/api/v1');

      final response = await _dio.get(
        path,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return model.NotificationResponse.fromJson(data);
        } else {
          throw NotificationServiceException(
            message: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw NotificationServiceException(
          message: 'Failed to fetch notifications: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NotificationServiceException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw NotificationServiceException(
        message: 'Unexpected error: $e',
      );
    }
  }

  /// Marks a specific notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final storage = GetStorage();
      final authToken = storage.read('auth_token');

      final headers = <String, String>{
        ...ApiConstants.ngrokHeaders,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final endpoint = ApiConstants.getMarkNotificationReadEndpoint(notificationId);
      final path = endpoint.replaceFirst(ApiConstants.apiBaseUrl, '/api/v1');

      final response = await _dio.patch(
        path,
        options: Options(headers: headers),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Marks all notifications as read for a user
  Future<bool> markAllNotificationsAsRead(String userId) async {
    try {
      final storage = GetStorage();
      final authToken = storage.read('auth_token');

      final headers = <String, String>{
        ...ApiConstants.ngrokHeaders,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final endpoint = ApiConstants.getMarkAllNotificationsReadEndpoint(userId);
      final path = endpoint.replaceFirst(ApiConstants.apiBaseUrl, '/api/v1');

      final response = await _dio.patch(
        path,
        options: Options(headers: headers),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  void dispose() {
    // Clean up resources if needed
  }
}

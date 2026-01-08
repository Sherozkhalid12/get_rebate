import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/notification_model.dart';
import 'package:getrebate/app/services/notification_service.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

class NotificationsController extends GetxController {
  final NotificationService _notificationService = NotificationService();
  final AuthController _authController = Get.find<AuthController>();

  // Observable state
  final _notifications = <NotificationModel>[].obs;
  final _isLoading = false.obs;
  final _unreadCount = 0.obs;
  final _total = 0.obs;
  final _error = Rxn<String>();

  // Getters
  List<NotificationModel> get notifications => _notifications.toList();
  bool get isLoading => _isLoading.value;
  int get unreadCount => _unreadCount.value;
  int get total => _total.value;
  String? get error => _error.value;

  // Get unread notifications
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  // Get read notifications
  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  /// Fetches notifications for the current user
  Future<void> fetchNotifications() async {
    final userId = _authController.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      _error.value = 'User not logged in';
      return;
    }

    _isLoading.value = true;
    _error.value = null;

    try {
      final response = await _notificationService.getNotifications(userId);
      _notifications.value = response.notifications;
      _unreadCount.value = response.unreadCount;
      _total.value = response.total;

      if (kDebugMode) {
        print('✅ Notifications fetched successfully');
        print('   Total: ${response.total}');
        print('   Unread: ${response.unreadCount}');
      }
    } catch (e) {
      _error.value = e.toString();
      if (kDebugMode) {
        print('❌ Error fetching notifications: $e');
      }
      SnackbarHelper.showError('Failed to load notifications');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Marks a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final success = await _notificationService.markNotificationAsRead(notificationId);
      if (success) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          // Recalculate unread count
          _unreadCount.value = _notifications.where((n) => !n.isRead).length;
        }

        if (kDebugMode) {
          print('✅ Notification marked as read: $notificationId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking notification as read: $e');
      }
      SnackbarHelper.showError('Failed to mark notification as read');
    }
  }

  /// Marks all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _authController.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      SnackbarHelper.showError('User not logged in');
      return;
    }

    try {
      final success = await _notificationService.markAllNotificationsAsRead(userId);
      if (success) {
        // Update local state
        _notifications.value = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        _unreadCount.value = 0;

        if (kDebugMode) {
          print('✅ All notifications marked as read');
        }
        SnackbarHelper.showSuccess('All notifications marked as read');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking all notifications as read: $e');
      }
      SnackbarHelper.showError('Failed to mark all notifications as read');
    }
  }

  /// Refreshes notifications
  Future<void> refresh() async {
    await fetchNotifications();
  }

  /// Handles notification tap - marks as read and navigates if needed
  Future<void> handleNotificationTap(NotificationModel notification) async {
    // Check current state in the list (may have been marked as read already)
    final matchingNotifications = _notifications.where(
      (n) => n.id == notification.id,
    );
    
    // Mark as read if still unread
    if (matchingNotifications.isNotEmpty) {
      final currentNotification = matchingNotifications.first;
      if (!currentNotification.isRead) {
        await markAsRead(notification.id);
      }
    }

    // Handle navigation based on notification type
    final type = notification.type.toLowerCase();
    
    // Check if it's a proposal acceptance notification
    if (type.contains('proposal') && (type.contains('accept') || type.contains('accepted'))) {
      // Extract proposal ID from notification
      String? proposalId = notification.proposalId;
      
      // If proposalId is not directly in the notification, try to extract from message
      if (proposalId == null || proposalId.isEmpty) {
        // Try to extract proposal ID from message (e.g., "Your proposal to [Name] has been accepted. Proposal ID: xxx")
        final message = notification.message;
        final proposalIdMatch = RegExp(r'proposal[_\s]?id[:\s]+([a-zA-Z0-9]+)', caseSensitive: false)
            .firstMatch(message);
        if (proposalIdMatch != null) {
          proposalId = proposalIdMatch.group(1);
        }
      }
      
      if (proposalId != null && proposalId.isNotEmpty) {
        // Navigate to proposals screen with the proposal ID
        Get.toNamed('/proposals', arguments: {'proposalId': proposalId});
      } else {
        // If we can't find proposal ID, just navigate to proposals screen
        Get.toNamed('/proposals');
      }
    }
    // Add other notification type handlers here if needed
  }

  @override
  void onClose() {
    _notificationService.dispose();
    super.onClose();
  }
}


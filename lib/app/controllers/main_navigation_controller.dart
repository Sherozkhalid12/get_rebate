import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/buyer_v2/views/buyer_v2_view.dart';
import 'package:getrebate/app/modules/buyer_v2/bindings/buyer_v2_binding.dart';
// DISABLED: Seller/PropertyListings imports - buyers cannot create listings anymore
// import 'package:getrebate/app/modules/seller/views/seller_view.dart';
// import 'package:getrebate/app/modules/seller/bindings/seller_binding.dart';
import 'package:getrebate/app/modules/favorites/views/favorites_view.dart';
import 'package:getrebate/app/modules/favorites/bindings/favorites_binding.dart';
import 'package:getrebate/app/modules/messages/views/messages_view.dart';
import 'package:getrebate/app/modules/messages/bindings/messages_binding.dart';
import 'package:getrebate/app/modules/profile/views/profile_view.dart';
import 'package:getrebate/app/modules/profile/bindings/profile_binding.dart';
import 'package:getrebate/app/modules/notifications/bindings/notifications_binding.dart';
import 'package:getrebate/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
// import 'package:getrebate/app/modules/property_listings/bindings/property_listings_binding.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';

class MainNavigationController extends GetxController {
  final _currentIndex = 0.obs;
  final _isNavBarVisible = true.obs;

  int get currentIndex => _currentIndex.value;
  bool get isNavBarVisible => _isNavBarVisible.value;

  void changeIndex(int index) {
    // Ensure index is within valid range
    final validIndex = index.clamp(0, pages.length - 1);
    
    if (index != validIndex) {
      if (kDebugMode) {
        print('⚠️ Invalid navigation index: $index, clamped to: $validIndex');
      }
    }
    
    if (_currentIndex.value != validIndex) {
      final oldIndex = _currentIndex.value;
      _currentIndex.value = validIndex;
      
      // Always show navbar when navigating to main navigation pages
      _isNavBarVisible.value = true;
      
      if (kDebugMode) {
        print('🔄 Navigation changed: ${_getPageName(oldIndex)} -> ${_getPageName(validIndex)}');
        print('   Index: $oldIndex -> $validIndex');
        print('   Pages array: [Home(0), Favorites(1), Messages(2), Profile(3)]');
        print('   Navbar visibility: true');
      }
      
      // Load notifications when navigating to home page (index 0)
      if (validIndex == 0) {
        _loadNotifications();
      }
    } else {
      // Even if index hasn't changed, ensure navbar is visible
      if (!_isNavBarVisible.value) {
        _isNavBarVisible.value = true;
        if (kDebugMode) {
          print('🔄 Navbar visibility restored (index unchanged: $validIndex)');
        }
      }
      
      // Also load notifications if already on home page and user taps home again
      if (validIndex == 0) {
        _loadNotifications();
      }
    }
  }
  
  /// Loads notification data when navigating to home page
  void _loadNotifications() {
    try {
      if (Get.isRegistered<NotificationsController>()) {
        final notificationsController = Get.find<NotificationsController>();
        notificationsController.fetchNotifications();
        if (kDebugMode) {
          print('📬 Loading notifications on home page navigation');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ NotificationsController not registered yet');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading notifications: $e');
      }
    }
  }

  void hideNavBar() {
    _isNavBarVisible.value = false;
  }

  void showNavBar() {
    _isNavBarVisible.value = true;
  }

  List<Widget> get pages => [
    const BuyerV2View(),        // Index 0: Home
    const FavoritesView(),    // Index 1: Favorites
    const MessagesView(),     // Index 2: Messages
    const ProfileView(),      // Index 3: Profile
  ];
  
  // Navigation mapping for reference:
  // Index 0 -> Home (BuyerV2View)
  // Index 1 -> Favorites (FavoritesView)
  // Index 2 -> Messages (MessagesView)
  // Index 3 -> Profile (ProfileView)

  @override
  void onInit() {
    super.onInit();
    // Initialize bindings for all pages
    BuyerV2Binding().dependencies();
    // DISABLED: Seller/PropertyListings bindings - buyers cannot create listings anymore
    // SellerBinding().dependencies();
    // PropertyListingsBinding().dependencies();
    FavoritesBinding().dependencies();
    MessagesBinding().dependencies();
    ProfileBinding().dependencies();
    // Initialize notifications controller globally
    NotificationsBinding().dependencies();
    
    // Initialize socket connection early so messages are received even when not in messages screen
    _initializeSocketEarly();
  }
  
  /// Initializes socket connection early so messages are received on home screen
  void _initializeSocketEarly() {
    // Wait a bit for bindings to initialize
    Future.delayed(const Duration(milliseconds: 800), () {
      try {
        if (Get.isRegistered<MessagesController>()) {
          final messagesController = Get.find<MessagesController>();
          // Force initialization if not already done
          // This ensures socket connects and joins all rooms even when not in messages screen
          if (kDebugMode) {
            print('🔌 Initializing socket early from MainNavigationController');
          }
          // The MessagesController.onInit will handle initialization
          // But we can also ensure threads are loaded and rooms are joined
          if (!messagesController.isLoadingThreads && messagesController.allConversations.isEmpty) {
            messagesController.loadThreads();
          }
        } else {
          if (kDebugMode) {
            print('⚠️ MessagesController not registered yet, will initialize when available');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error initializing socket early: $e');
        }
      }
    });
  }

  Widget buildBottomNavigationBar() {
    return Obx(
      () {
        // Navigation mapping: Icon index -> Page index
        // Icon 0 (Home) -> Page 0 (BuyerV2View)
        // Icon 1 (Favorites) -> Page 1 (FavoritesView)
        // Icon 2 (Messages) -> Page 2 (MessagesView)
        // Icon 3 (Profile) -> Page 3 (ProfileView)
        
        // Ensure we have matching icon and page counts
        final iconCount = 4; // Home, Favorites, Messages, Profile
        final pageCount = pages.length;
        
        if (iconCount != pageCount && kDebugMode) {
          print('⚠️ Icon count ($iconCount) does not match page count ($pageCount)');
        }
        
        // Ensure current index is valid
        final safeIndex = _currentIndex.value.clamp(0, 3);
        if (safeIndex != _currentIndex.value && kDebugMode) {
          print('⚠️ CircleNavBar: Corrected index from ${_currentIndex.value} to $safeIndex');
        }
        
        // Get unread count for messages badge (reactive)
        int unreadCount = 0;
        try {
          if (Get.isRegistered<MessagesController>()) {
            final messagesController = Get.find<MessagesController>();
            // Access allConversations to make this reactive
            messagesController.allConversations; // This makes Obx reactive to changes
            unreadCount = messagesController.totalUnreadCount;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error getting unread count: $e');
          }
        }
        
        // Hide badge when user is on messages tab (index 2)
        final isOnMessagesTab = safeIndex == 2;
        final badgeUnreadCount = isOnMessagesTab ? 0 : unreadCount;
        
        return CircleNavBar(
          activeIcons: [
            Icon(Icons.home, color: AppTheme.primaryBlue, size: 24.sp),      // Icon 0 -> Page 0: Home
            Icon(Icons.favorite, color: AppTheme.primaryBlue, size: 24.sp),  // Icon 1 -> Page 1: Favorites
            _buildMessageIconWithBadge(
              Icon(Icons.message, color: AppTheme.primaryBlue, size: 24.sp),
              badgeUnreadCount,
            ),   // Icon 2 -> Page 2: Messages
            Icon(Icons.person, color: AppTheme.primaryBlue, size: 24.sp),    // Icon 3 -> Page 3: Profile
          ],
          inactiveIcons: [
            Icon(Icons.home_outlined, color: AppTheme.mediumGray, size: 24.sp),      // Icon 0 -> Page 0: Home
            Icon(Icons.favorite_border, color: AppTheme.mediumGray, size: 24.sp),    // Icon 1 -> Page 1: Favorites
            _buildMessageIconWithBadge(
              Icon(Icons.message_outlined, color: AppTheme.mediumGray, size: 24.sp),
              badgeUnreadCount,
            ),   // Icon 2 -> Page 2: Messages
            Icon(Icons.person_outline, color: AppTheme.mediumGray, size: 24.sp),     // Icon 3 -> Page 3: Profile
          ],
          color: Colors.white,
          height: 60.h,
          circleWidth: 45.w,
          initIndex: safeIndex, // Use safe clamped index
          onChanged: (iconIndex) {
            // Map icon index directly to page index (they should match now)
            final pageIndex = iconIndex.clamp(0, pages.length - 1);
            
            if (kDebugMode) {
              print('📱 CircleNavBar tapped icon index: $iconIndex');
              print('   Mapping to page index: $pageIndex');
              print('   Page at index $pageIndex: ${_getPageName(pageIndex)}');
              print('   Current index before change: ${_currentIndex.value}');
            }
            
            // Ensure the index is valid before changing
            if (pageIndex >= 0 && pageIndex < pages.length) {
              changeIndex(pageIndex);
            } else {
              if (kDebugMode) {
                print('❌ Invalid page index: $pageIndex (max: ${pages.length - 1})');
                print('   Rejecting navigation to invalid index');
              }
            }
          },
          padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 20.h),
          cornerRadius: BorderRadius.only(
            topLeft: Radius.circular(8.r),
            topRight: Radius.circular(8.r),
            bottomRight: Radius.circular(24.r),
            bottomLeft: Radius.circular(24.r),
          ),
          shadowColor: AppTheme.primaryBlue,
          elevation: 10,
        );
      },
    );
  }
  
  /// Builds message icon with badge showing unread count
  Widget _buildMessageIconWithBadge(Widget icon, int unreadCount) {
    if (unreadCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(
            right: -6.w,
            top: -6.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5.w),
              ),
              constraints: BoxConstraints(
                minWidth: 16.w,
                minHeight: 16.h,
              ),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return icon;
  }
  
  String _getPageName(int index) {
    switch (index) {
      case 0:
        return 'Home (BuyerV2View)';
      case 1:
        return 'Favorites (FavoritesView)';
      case 2:
        return 'Messages (MessagesView)';
      case 3:
        return 'Profile (ProfileView)';
      default:
        return 'Unknown';
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}

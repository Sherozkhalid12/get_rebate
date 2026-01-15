import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/buyer/views/buyer_view.dart';
import 'package:getrebate/app/modules/buyer/bindings/buyer_binding.dart';
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
    } else {
      // Even if index hasn't changed, ensure navbar is visible
      if (!_isNavBarVisible.value) {
        _isNavBarVisible.value = true;
        if (kDebugMode) {
          print('🔄 Navbar visibility restored (index unchanged: $validIndex)');
        }
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
    const BuyerView(),        // Index 0: Home
    const FavoritesView(),    // Index 1: Favorites
    const MessagesView(),     // Index 2: Messages
    const ProfileView(),      // Index 3: Profile
  ];
  
  // Navigation mapping for reference:
  // Index 0 -> Home (BuyerView)
  // Index 1 -> Favorites (FavoritesView)
  // Index 2 -> Messages (MessagesView)
  // Index 3 -> Profile (ProfileView)

  @override
  void onInit() {
    super.onInit();
    // Initialize bindings for all pages
    BuyerBinding().dependencies();
    // DISABLED: Seller/PropertyListings bindings - buyers cannot create listings anymore
    // SellerBinding().dependencies();
    // PropertyListingsBinding().dependencies();
    FavoritesBinding().dependencies();
    MessagesBinding().dependencies();
    ProfileBinding().dependencies();
    // Initialize notifications controller globally
    NotificationsBinding().dependencies();
  }

  Widget buildBottomNavigationBar() {
    return Obx(
      () {
        // Navigation mapping: Icon index -> Page index
        // Icon 0 (Home) -> Page 0 (BuyerView)
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
        
        return CircleNavBar(
          activeIcons: [
            Icon(Icons.home, color: AppTheme.primaryBlue, size: 24.sp),      // Icon 0 -> Page 0: Home
            Icon(Icons.favorite, color: AppTheme.primaryBlue, size: 24.sp),  // Icon 1 -> Page 1: Favorites
            Icon(Icons.message, color: AppTheme.primaryBlue, size: 24.sp),   // Icon 2 -> Page 2: Messages
            Icon(Icons.person, color: AppTheme.primaryBlue, size: 24.sp),    // Icon 3 -> Page 3: Profile
          ],
          inactiveIcons: [
            Icon(Icons.home_outlined, color: AppTheme.mediumGray, size: 24.sp),      // Icon 0 -> Page 0: Home
            Icon(Icons.favorite_border, color: AppTheme.mediumGray, size: 24.sp),    // Icon 1 -> Page 1: Favorites
            Icon(Icons.message_outlined, color: AppTheme.mediumGray, size: 24.sp),   // Icon 2 -> Page 2: Messages
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
  
  String _getPageName(int index) {
    switch (index) {
      case 0:
        return 'Home (BuyerView)';
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/buyer/views/buyer_view.dart';
import 'package:getrebate/app/modules/buyer/bindings/buyer_binding.dart';
import 'package:getrebate/app/modules/seller/views/seller_view.dart';
import 'package:getrebate/app/modules/seller/bindings/seller_binding.dart';
import 'package:getrebate/app/modules/favorites/views/favorites_view.dart';
import 'package:getrebate/app/modules/favorites/bindings/favorites_binding.dart';
import 'package:getrebate/app/modules/messages/views/messages_view.dart';
import 'package:getrebate/app/modules/messages/bindings/messages_binding.dart';
import 'package:getrebate/app/modules/profile/views/profile_view.dart';
import 'package:getrebate/app/modules/profile/bindings/profile_binding.dart';
import 'package:getrebate/app/modules/property_listings/bindings/property_listings_binding.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';

class MainNavigationController extends GetxController {
  final _currentIndex = 0.obs;
  final _isNavBarVisible = true.obs;

  int get currentIndex => _currentIndex.value;
  bool get isNavBarVisible => _isNavBarVisible.value;

  void changeIndex(int index) {
    if (_currentIndex.value != index) {
      _currentIndex.value = index;
    }
  }

  void hideNavBar() {
    _isNavBarVisible.value = false;
  }

  void showNavBar() {
    _isNavBarVisible.value = true;
  }

  List<Widget> get pages => [
    const BuyerView(),
    const SellerView(),
    const FavoritesView(),
    const MessagesView(),
    const ProfileView(),
  ];

  @override
  void onInit() {
    super.onInit();
    // Initialize bindings for all pages
    BuyerBinding().dependencies();
    SellerBinding().dependencies();
    PropertyListingsBinding().dependencies();
    FavoritesBinding().dependencies();
    MessagesBinding().dependencies();
    ProfileBinding().dependencies();
  }

  Widget buildBottomNavigationBar() {
    return Obx(
      () => CircleNavBar(
        activeIcons: [
          Icon(Icons.home, color: AppTheme.primaryBlue, size: 24.sp),
          Icon(Icons.sell, color: AppTheme.primaryBlue, size: 24.sp),
          Icon(Icons.favorite, color: AppTheme.primaryBlue, size: 24.sp),
          Icon(Icons.message, color: AppTheme.primaryBlue, size: 24.sp),
          Icon(Icons.person, color: AppTheme.primaryBlue, size: 24.sp),
        ],
        inactiveIcons: [
          Icon(Icons.home_outlined, color: AppTheme.mediumGray, size: 24.sp),
          Icon(Icons.sell_outlined, color: AppTheme.mediumGray, size: 24.sp),
          Icon(Icons.favorite_border, color: AppTheme.mediumGray, size: 24.sp),
          Icon(Icons.message_outlined, color: AppTheme.mediumGray, size: 24.sp),
          Icon(Icons.person_outline, color: AppTheme.mediumGray, size: 24.sp),
        ],
        color: Colors.white,
        height: 60.h,
        circleWidth: 45.w,
        initIndex: _currentIndex.value,
        onChanged: changeIndex,
        padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 20.h),
        cornerRadius: BorderRadius.only(
          topLeft: Radius.circular(8.r),
          topRight: Radius.circular(8.r),
          bottomRight: Radius.circular(24.r),
          bottomLeft: Radius.circular(24.r),
        ),
        shadowColor: AppTheme.primaryBlue,
        elevation: 10,
      ),
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}

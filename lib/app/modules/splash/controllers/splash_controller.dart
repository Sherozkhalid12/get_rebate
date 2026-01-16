import 'dart:async';
import 'package:get/get.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';

class SplashController extends GetxController {
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    print('Splash: Controller initialized');
    _startTimer();
  }

  @override
  void onReady() {
    super.onReady();
    print('Splash: Controller ready');
  }

  void _startTimer() {
    print('Splash: Starting 0.8-second timer for faster loading...');
    Timer(const Duration(milliseconds: 800), () {
      print('Splash: Timer completed, checking auth status...');
      _checkAuthAndNavigate();
    });
    print('Splash: Timer started successfully');
  }

  void _checkAuthAndNavigate() {
    try {
      // Get auth controller and check if user is logged in
      final authController = Get.find<AuthController>();

      if (authController.isLoggedIn && authController.currentUser != null) {
        // User is logged in - preload data in background for instant access
        _preloadData();
        
        // Navigate to appropriate screen based on role
        final user = authController.currentUser!;
        print('Splash: User is logged in as ${user.role}, navigating...');
        _navigateBasedOnRole(user.role);
      } else {
        // User is not logged in, navigate to onboarding
        print('Splash: User is not logged in, navigating to onboarding...');
        _navigateToOnboarding();
      }
    } catch (e) {
      print('Splash: Error checking auth status: $e');
      // If error occurs, navigate to onboarding as fallback
      _navigateToOnboarding();
    }
  }

  /// Preloads data in background for instant access when user opens app
  void _preloadData() {
    try {
      // Initialize messages controller immediately to start loading threads
      // This ensures threads are loading while splash screen is showing
      if (!Get.isRegistered<MessagesController>()) {
        // Initialize controller immediately - it will start loading threads in background
        Get.put(MessagesController(), permanent: true);
        print('🚀 Splash: MessagesController initialized - threads loading in background');
      } else {
        // Controller already exists, trigger thread refresh
        try {
          final messagesController = Get.find<MessagesController>();
          messagesController.refreshThreads();
          print('🚀 Splash: Triggered thread refresh for existing MessagesController');
        } catch (e) {
          print('⚠️ Splash: Failed to refresh threads: $e');
        }
      }
      
      // Note: BuyerController will be initialized when main screen loads via bindings
      // This ensures data loads in parallel with navigation
      print('🚀 Splash: Data preload initiated');
    } catch (e) {
      print('⚠️ Splash: Failed to preload data: $e');
      // Don't block navigation if preload fails
    }
  }

  void _navigateBasedOnRole(UserRole role) {
    try {
      switch (role) {
        case UserRole.buyerSeller:
          Get.offAllNamed(AppPages.MAIN);
          print('Splash: Navigated to MAIN');
          break;
        case UserRole.agent:
          Get.offAllNamed(AppPages.AGENT);
          print('Splash: Navigated to AGENT');
          break;
        case UserRole.loanOfficer:
          Get.offAllNamed(AppPages.LOAN_OFFICER);
          print('Splash: Navigated to LOAN_OFFICER');
          break;
      }
    } catch (e) {
      print('Splash: Navigation failed: $e');
      // Fallback to onboarding
      _navigateToOnboarding();
    }
  }

  void navigateToOnboarding() {
    try {
      Get.offAllNamed(AppPages.ONBOARDING);
      print('Splash: Navigation successful');
    } catch (e) {
      print('Splash: Navigation failed: $e');
      // Try alternative navigation
      Get.toNamed(AppPages.ONBOARDING);
    }
  }

  void _navigateToOnboarding() {
    navigateToOnboarding();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

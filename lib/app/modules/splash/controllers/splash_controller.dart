import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/controllers/current_loan_officer_controller.dart';
import 'package:getrebate/app/controllers/location_controller.dart';
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/utils/storage_keys.dart';

class SplashController extends GetxController {
  Timer? _timer;
  final _storage = GetStorage();

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

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Get auth controller and check if user is logged in
      final authController = Get.find<AuthController>();

      if (authController.isLoggedIn && authController.currentUser != null) {
        final user = authController.currentUser!;
        // User is logged in - preload data in background for instant access
        _preloadData(user.role);

        // For agent/loan officer: fetch firstZipCodeClaimed during splash so we don't show loading on home
        if (user.role == UserRole.agent || user.role == UserRole.loanOfficer) {
          await _fetchAndStoreFirstZipCodeClaimed(user.id);
        }

        // For loan officer: ensure profile is loaded before entering loan officer view.
        // If profile fails to load, redirect to sign in so user can sign in again and we fetch profile then.
        if (user.role == UserRole.loanOfficer) {
          final currentLoController =
              Get.isRegistered<CurrentLoanOfficerController>()
                  ? Get.find<CurrentLoanOfficerController>()
                  : Get.put(CurrentLoanOfficerController(), permanent: true);
          await currentLoController.fetchCurrentLoanOfficer(user.id);
          if (currentLoController.currentLoanOfficer.value == null) {
            print('Splash: Loan officer profile not loaded, redirecting to sign in.');
            SnackbarHelper.showError(
              'Could not load your profile. Please sign in again.',
              duration: const Duration(seconds: 4),
            );
            authController.logout();
            return;
          }
          print('Splash: Loan officer profile loaded, navigating to LOAN_OFFICER.');
        }

        print('Splash: User is logged in as ${user.role}, navigating...');
        _navigateBasedOnRole(user.role);
      } else {
        // User is not logged in - request location for sign-up (agent/loan officer zip fields)
        _preloadLocation();
        print('Splash: User is not logged in, navigating to onboarding...');
        _navigateToOnboarding();
      }
    } catch (e) {
      print('Splash: Error checking auth status: $e');
      // If error occurs, navigate to onboarding as fallback
      _navigateToOnboarding();
    }
  }

  /// Fetches firstZipCodeClaimed from /auth/users and stores in GetStorage.
  /// Agent/LoanOfficer controllers read this on init to avoid loading flicker.
  Future<void> _fetchAndStoreFirstZipCodeClaimed(String userId) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.apiBaseUrl));
      final authToken = _storage.read('auth_token');

      final response = await dio.get(
        '/auth/users/$userId',
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final userData = data is Map
            ? (data['user'] ?? data['agent'] ?? data['officer'] ?? data['loanOfficer'] ?? data)
            : data;
        final raw = userData is Map ? userData['firstZipCodeClaimed'] : null;
        if (raw is bool) {
          _storage.write(kFirstZipCodeClaimedStorageKey, raw);
          print('Splash: Stored firstZipCodeClaimed=$raw for agent/loan officer');
        }
      }
    } catch (e) {
      print('Splash: Could not fetch firstZipCodeClaimed: $e (will use loading fallback)');
    }
  }

  /// Requests location permission and fetches current zip. Runs for buyers
  /// (home search) and for sign-up (agent/loan officer office zip). Calls
  /// getCurrentLocation() so the system permission dialog is shown when needed.
  void _preloadLocation([UserRole? role]) {
    try {
      final locCtrl = Get.find<LocationController>();
      locCtrl.getCurrentLocation();
      print('🚀 Splash: Location request started (will prompt for permission if needed)');
    } catch (e) {
      print('⚠️ Splash: Location preload skipped: $e');
    }
  }

  /// Preloads data in background for instant access when user opens app
  void _preloadData(UserRole role) {
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
      
      // Request location permission and fetch zip (buyers + sign-up flow)
      _preloadLocation(role);

      // Note: BuyerV2Controller will be initialized when main screen loads via bindings
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

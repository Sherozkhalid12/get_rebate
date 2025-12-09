import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io';
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/routes/app_pages.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();

  // Observable variables
  final _isLoading = false.obs;
  final _currentUser = Rxn<UserModel>();
  final _isLoggedIn = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  UserModel? get currentUser => _currentUser.value;
  bool get isLoggedIn => _isLoggedIn.value;

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    final userData = _storage.read('current_user');

    if (userData != null) {
      _currentUser.value = UserModel.fromJson(userData);
      _isLoggedIn.value = true;

      print('✅ User session restored from storage');
      print('   User ID: ${_currentUser.value?.id}');
      print('   Email: ${_currentUser.value?.email}');
      print('   Role: ${_currentUser.value?.role}');
    } else {
      print('ℹ️ No saved user session found');
      _isLoggedIn.value = false;
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? provider,
  }) async {
    try {
      _isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Create mock user for demo
      final user = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: email.split('@')[0],
        role: UserRole.buyerSeller,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isVerified: true,
      );

      // Store user
          _currentUser.value = user;
          _isLoggedIn.value = true;
          _storage.write('current_user', user.toJson());

          print('✅ Login successful!');
          print('   User ID: ${user.id}');
          print('   Email: ${user.email}');
          print('   Name: ${user.name}');
          print('   Role: ${user.role}');

          Get.snackbar(
            'Success',
        'Login successful!',
            backgroundColor: Get.theme.colorScheme.primary,
            colorText: Get.theme.colorScheme.onPrimary,
          );

          _navigateToRoleBasedScreen();
    } catch (e) {
      print('❌ Unexpected Error: ${e.toString()}');
      Get.snackbar('Error', 'Login failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    List<String>? licensedStates,
    Map<String, dynamic>? additionalData,
    File? profilePic,
    File? companyLogo,
  }) async {
    try {
      _isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Create user model
        final user = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          name: name,
          phone: phone,
          role: role,
          licensedStates: licensedStates ?? [],
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        isVerified: false,
          additionalData: additionalData,
        );

        _currentUser.value = user;
        _isLoggedIn.value = true;
        _storage.write('current_user', user.toJson());

        print('✅ User created successfully!');
        print('   User ID: ${user.id}');
        print('   Email: ${user.email}');
        print('   Name: ${user.name}');
        print('   Role: ${user.role}');

        Get.snackbar(
          'Success',
          'Account created successfully!',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        _navigateToRoleBasedScreen();
    } catch (e) {
      Get.snackbar('Error', 'Sign up failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> socialLogin({
    required String provider,
    required String email,
    required String name,
    String? profileImage,
  }) async {
    try {
      _isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      final user = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        profileImage: profileImage,
        role: UserRole.buyerSeller, // Default role for social login
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isVerified: true,
      );

      _currentUser.value = user;
      _isLoggedIn.value = true;
      _storage.write('current_user', user.toJson());

      Get.toNamed(AppPages.ONBOARDING);
    } catch (e) {
      Get.snackbar('Error', 'Social login failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  void logout() {
    _currentUser.value = null;
    _isLoggedIn.value = false;
    _storage.remove('current_user');
    print('🔓 User logged out - cleared user data');
    Get.offAllNamed(AppPages.AUTH);
  }

  void updateUser(UserModel user) {
    _currentUser.value = user;
    _storage.write('current_user', user.toJson());
  }

  void _navigateToRoleBasedScreen() {
    switch (_currentUser.value?.role) {
      case UserRole.buyerSeller:
        Get.offAllNamed(AppPages.MAIN);
        break;
      case UserRole.agent:
        Get.offAllNamed(AppPages.AGENT);
        break;
      case UserRole.loanOfficer:
        Get.offAllNamed(AppPages.LOAN_OFFICER);
        break;
      default:
        Get.offAllNamed(AppPages.ONBOARDING);
    }
  }

}

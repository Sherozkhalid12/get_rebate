import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

class ProfileController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();

  // Observable variables
  final _isEditing = false.obs;
  final _isLoading = false.obs;
  final _selectedImage = Rxn<String>();

  // Getters
  bool get isEditing => _isEditing.value;
  bool get isLoading => _isLoading.value;
  String? get selectedImage => _selectedImage.value;
  UserModel? get currentUser => _authController.currentUser;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _authController.currentUser;
    if (user != null) {
      nameController.text = user.name;
      emailController.text = user.email;
      phoneController.text = user.phone ?? '';
      bioController.text = user.additionalData?['bio'] ?? '';
      _selectedImage.value = user.profileImage;
    }
  }

  void toggleEditing() {
    _isEditing.value = !_isEditing.value;
    if (!_isEditing.value) {
      // Reset form if canceling edit
      _loadUserData();
    }
  }

  Future<void> saveProfile() async {
    if (!_validateForm()) return;

    try {
      _isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Update user data
      final updatedUser = currentUser?.copyWith(
        name: nameController.text.trim(),
        phone: phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : null,
        profileImage: _selectedImage.value,
        additionalData: {
          ...?currentUser?.additionalData,
          'bio': bioController.text.trim(),
        },
      );

      if (updatedUser != null) {
        _authController.updateUser(updatedUser);
        _isEditing.value = false;
        SnackbarHelper.showSuccess('Profile updated successfully!');
        
        // Wait a moment for snackbar to be visible, then navigate to home page
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate to home page based on user role
        final user = _authController.currentUser;
        if (user != null) {
          switch (user.role) {
            case UserRole.agent:
              Get.offAllNamed(AppPages.AGENT);
              break;
            case UserRole.buyerSeller:
              Get.offAllNamed(AppPages.MAIN);
              break;
            case UserRole.loanOfficer:
              Get.offAllNamed(AppPages.LOAN_OFFICER);
              break;
          }
        }
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to update profile: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> changeProfileImage() async {
    try {
      // Simulate image picker
      await Future.delayed(const Duration(seconds: 1));

      // Mock image selection
      _selectedImage.value = 'https://i.pravatar.cc/150?img=3';
    } catch (e) {
      SnackbarHelper.showError('Failed to select image: ${e.toString()}');
    }
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(Get.context!), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(Get.context!);
              _authController.logout();
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      SnackbarHelper.showValidation('Please enter your name');
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      SnackbarHelper.showValidation('Please enter your email');
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      SnackbarHelper.showValidation('Please enter a valid email');
      return false;
    }

    return true;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    bioController.dispose();
    super.onClose();
  }
}

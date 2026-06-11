import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/services/user_service.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

class ProfileController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();

  // Observable variables
  final _isEditing = false.obs;
  final _isLoading = false.obs;
  final _isUploadingImage = false.obs;
  final _selectedImageFile = Rxn<File>();
  final _profileImageUrl = Rxn<String>();

  // Getters
  bool get isEditing => _isEditing.value;
  bool get isLoading => _isLoading.value;
  bool get isUploadingImage => _isUploadingImage.value;
  File? get selectedImageFile => _selectedImageFile.value;
  String? get profileImageUrl => _profileImageUrl.value;
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
      _profileImageUrl.value = user.profileImage;
      
      if (kDebugMode) {
        print('📸 ProfileController._loadUserData:');
        print('   User profileImage from model: ${user.profileImage}');
        print('   Setting _profileImageUrl to: ${_profileImageUrl.value}');
      }
    }
  }

  void refreshUserData() {
    _loadUserData();
  }

  void toggleEditing() {
    _isEditing.value = !_isEditing.value;
    if (!_isEditing.value) {
      // Reset form if canceling edit
      _loadUserData();
      _selectedImageFile.value = null;
    }
  }

  Future<void> pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImageFile.value = File(image.path);
        // Show instant preview
        if (kDebugMode) {
          print('✅ Image selected: ${image.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking image: $e');
      }
      SnackbarHelper.showError('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> saveProfile() async {
    if (!_validateForm()) return;

    final userId = currentUser?.id;
    if (userId == null || userId.isEmpty) {
      SnackbarHelper.showError('User not logged in');
      return;
    }

    try {
      _isLoading.value = true;

      // Use AuthController's updateUserProfile which handles file uploads
      await _authController.updateUserProfile(
        userId: userId,
        fullname: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : null,
        bio: bioController.text.trim().isNotEmpty
            ? bioController.text.trim()
            : null,
        profilePic: _selectedImageFile.value, // Pass the File directly
      );

      // Refresh user data from AuthController to get updated profile image
      final updatedUser = _authController.currentUser;
      if (updatedUser != null) {
        // Update local profile image URL
        _profileImageUrl.value = updatedUser.profileImage;
        _selectedImageFile.value = null;
        _isEditing.value = false;
        
        // Reload form data to reflect any changes
        _loadUserData();
        
        SnackbarHelper.showSuccess('Profile updated successfully!');
        
        if (kDebugMode) {
          print('✅ Profile updated successfully');
          print('   Final profileImageUrl: ${updatedUser.profileImage}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating profile: $e');
      }
      SnackbarHelper.showError('Failed to update profile: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  void logout() {
    _showConfirmationDialog(
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      onConfirm: _authController.logout,
    );
  }

  void deleteAccount() {
    _showConfirmationDialog(
      title: 'Delete Account',
      message:
          'Are you sure you want to delete your account? You will be signed out and will need to create a new account to use the app again.',
      confirmLabel: 'Delete Account',
      onConfirm: _authController.logout,
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Colors.red),
            ),
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
    _userService.dispose();
    super.onClose();
  }
}

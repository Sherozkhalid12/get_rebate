import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:getrebate/app/controllers/auth_controller.dart';

class AgentEditProfileController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final descriptionController = TextEditingController();
  final licenseNumberController = TextEditingController();

  // Observable variables
  final _isLoading = false.obs;
  final _selectedProfilePic = Rxn<File>();
  final _dualAgencyState = Rxn<bool>();
  final _dualAgencyBrokerage = Rxn<bool>();
  final _licensedStates = <String>[].obs;

  // API Base URL for static files
  static const String _baseUrl = 'https://3a461922e985.ngrok-free.app';

  // Getters
  bool get isLoading => _isLoading.value;
  File? get selectedProfilePic => _selectedProfilePic.value;
  bool? get dualAgencyState => _dualAgencyState.value;
  bool? get dualAgencyBrokerage => _dualAgencyBrokerage.value;
  List<String> get licensedStates => _licensedStates;

  // Get profile picture URL - returns full URL if exists, null otherwise
  String? get profilePictureUrl {
    if (_selectedProfilePic.value != null) {
      // If a new picture is selected, return null (will use File)
      return null;
    }

    final user = _authController.currentUser;
    final profilePic = user?.profileImage;

    if (profilePic == null || profilePic.isEmpty) {
      return null;
    }

    // If profilePic already contains http/https, return as is
    if (profilePic.startsWith('http://') || profilePic.startsWith('https://')) {
      print('📸 Using full profile picture URL: $profilePic');
      return profilePic;
    }

    // Otherwise, prepend base URL
    // Handle both paths with and without leading slash
    String path = profilePic;
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    final fullUrl = '$_baseUrl$path';
    print('📸 Constructed profile picture URL: $fullUrl');
    print('   Base URL: $_baseUrl');
    print('   Profile Pic Path: $profilePic');
    return fullUrl;
  }

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _authController.currentUser;
    if (user != null) {
      fullNameController.text = user.name;
      emailController.text = user.email;
      phoneController.text = user.phone ?? '';
      bioController.text = user.additionalData?['bio'] ?? '';
      descriptionController.text = user.additionalData?['description'] ?? '';
      licenseNumberController.text =
          user.additionalData?['liscenceNumber'] ?? '';

      _dualAgencyState.value = user.additionalData?['dualAgencyState'];
      _dualAgencyBrokerage.value = user.additionalData?['dualAgencySBrokerage'];
      _licensedStates.value = List<String>.from(user.licensedStates);
    }
  }

  Future<void> pickProfilePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedProfilePic.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  void removeProfilePicture() {
    _selectedProfilePic.value = null;
  }

  void setDualAgencyState(bool? value) {
    _dualAgencyState.value = value;
  }

  void setDualAgencyBrokerage(bool? value) {
    _dualAgencyBrokerage.value = value;
  }

  void toggleLicensedState(String state) {
    if (_licensedStates.contains(state)) {
      _licensedStates.remove(state);
    } else {
      _licensedStates.add(state);
    }
  }

  Future<void> saveProfile() async {
    if (!_validateForm()) return;

    try {
      _isLoading.value = true;

      // TODO: Implement API call to update profile
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // Update user model
      final currentUser = _authController.currentUser;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          name: fullNameController.text.trim(),
          phone: phoneController.text.trim().isNotEmpty
              ? phoneController.text.trim()
              : null,
          additionalData: {
            ...?currentUser.additionalData,
            'bio': bioController.text.trim(),
            'description': descriptionController.text.trim(),
            'liscenceNumber': licenseNumberController.text.trim(),
            'dualAgencyState': _dualAgencyState.value,
            'dualAgencySBrokerage': _dualAgencyBrokerage.value,
          },
          licensedStates: _licensedStates.toList(),
        );

        _authController.updateUser(updatedUser);

        Get.snackbar(
          'Success',
          'Profile updated successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.back();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  bool _validateForm() {
    if (fullNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter your full name');
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter your email');
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar('Error', 'Please enter a valid email');
      return false;
    }

    if (_dualAgencyState.value == null) {
      Get.snackbar(
        'Error',
        'Please answer if dual agency is allowed in your state',
      );
      return false;
    }

    if (_dualAgencyBrokerage.value == null) {
      Get.snackbar(
        'Error',
        'Please answer if dual agency is allowed at your brokerage',
      );
      return false;
    }

    return true;
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    bioController.dispose();
    descriptionController.dispose();
    licenseNumberController.dispose();
    super.onClose();
  }
}

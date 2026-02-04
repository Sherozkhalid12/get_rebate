import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/controllers/location_controller.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/controllers/current_loan_officer_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/models/mortgage_types.dart';

class LoanOfficerEditProfileController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final LocationController _locationController = Get.find<LocationController>();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final licenseNumberController = TextEditingController();
  final companyNameController = TextEditingController();
  final mortgageApplicationUrlController = TextEditingController();
  final externalReviewsUrlController = TextEditingController();
  final serviceAreasController = TextEditingController();
  final yearsOfExperienceController = TextEditingController();
  final languagesSpokenController = TextEditingController();
  final discountsOfferedController = TextEditingController();

  // Observable variables
  final _isLoading = false.obs;
  final _selectedProfilePic = Rxn<File>();
  final _selectedCompanyLogo = Rxn<File>();
  final _licensedStates = <String>[].obs;
  final _specialtyProducts = <String>[].obs;

  bool _isDisposed = false;

  static String get _baseUrl => ApiConstants.baseUrl;

  // Getters
  bool get isLoading => _isLoading.value;
  File? get selectedProfilePic => _selectedProfilePic.value;
  File? get selectedCompanyLogo => _selectedCompanyLogo.value;
  List<String> get licensedStates => _licensedStates;
  List<String> get specialtyProducts => _specialtyProducts;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  /// Uses cached current location zip for the service areas field (instant, no fetch on tap).
  void useCurrentLocationForZip() {
    final zipCode = _locationController.currentZipCode;
    if (zipCode != null &&
        zipCode.length == 5 &&
        RegExp(r'^\d+$').hasMatch(zipCode)) {
      final current = serviceAreasController.text.trim();
      if (current.isEmpty) {
        serviceAreasController.text = zipCode;
      } else {
        serviceAreasController.text = '$current, $zipCode';
      }
      serviceAreasController.selection = TextSelection.collapsed(
        offset: serviceAreasController.text.length,
      );
    } else {
      Get.snackbar(
        'Location',
        'Location not ready yet. Please wait a moment and try again, or enter ZIP manually.',
        backgroundColor: AppTheme.primaryBlue,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  // Helper for Success Snackbars
  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: AppTheme.primaryBlue,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  // Helper for Error Snackbars
  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  String? getProfilePictureUrl() {
    final selectedPic = _selectedProfilePic.value;
    if (selectedPic != null) return null;

    try {
      final currentLoanOfficerController = Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;
      final loanOfficer = currentLoanOfficerController?.currentLoanOfficer.value;
      final profilePic = loanOfficer?.profileImage;

      if (profilePic == null || profilePic.isEmpty) return null;
      if (profilePic.startsWith('http://') || profilePic.startsWith('https://')) return profilePic;

      String path = profilePic.startsWith('/') ? profilePic : '/$profilePic';
      return '$_baseUrl$path';
    } catch (e) {
      return null;
    }
  }

  String? getCompanyLogoUrl() {
    final selectedLogo = _selectedCompanyLogo.value;
    if (selectedLogo != null) return null;

    try {
      final currentLoanOfficerController = Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;
      final loanOfficer = currentLoanOfficerController?.currentLoanOfficer.value;
      final companyLogo = loanOfficer?.companyLogoUrl;

      if (companyLogo == null || companyLogo.isEmpty) return null;
      if (companyLogo.startsWith('http://') || companyLogo.startsWith('https://')) return companyLogo;

      String path = companyLogo.startsWith('/') ? companyLogo : '/$companyLogo';
      return '$_baseUrl$path';
    } catch (e) {
      return null;
    }
  }

  void _loadUserData() {
    final currentLoanOfficerController = Get.isRegistered<CurrentLoanOfficerController>()
        ? Get.find<CurrentLoanOfficerController>()
        : null;
    final loanOfficer = currentLoanOfficerController?.currentLoanOfficer.value;

    if (loanOfficer != null) {
      fullNameController.text = loanOfficer.name;
      emailController.text = loanOfficer.email;
      phoneController.text = loanOfficer.phone ?? '';
      bioController.text = loanOfficer.bio ?? '';
      licenseNumberController.text = loanOfficer.licenseNumber;
      companyNameController.text = loanOfficer.company;
      mortgageApplicationUrlController.text = loanOfficer.mortgageApplicationUrl ?? '';
      externalReviewsUrlController.text = loanOfficer.externalReviewsUrl ?? '';
      serviceAreasController.text = loanOfficer.claimedZipCodes.join(', ');
      _licensedStates.value = List<String>.from(loanOfficer.licensedStates);
      _specialtyProducts.value = List<String>.from(loanOfficer.specialtyProducts);
    }
  }

  Future<void> pickProfilePicture() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile != null) _selectedProfilePic.value = File(pickedFile.path);
    } catch (e) {
      _showError('Failed to pick image');
    }
  }

  Future<void> pickCompanyLogo() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile != null) _selectedCompanyLogo.value = File(pickedFile.path);
    } catch (e) {
      _showError('Failed to pick logo');
    }
  }

  Future<void> saveProfile() async {
    if (_isDisposed) return;
    if (!_validateForm()) return;

    try {
      _isLoading.value = true;
      final currentUser = _authController.currentUser;

      if (currentUser == null) {
        _showError('User not found. Please login again.');
        return;
      }

      if (currentUser.id.isEmpty || currentUser.id.startsWith('user_')) {
        _showError('Invalid user ID. Please logout and login again.');
        return;
      }

      final serviceAreasList = serviceAreasController.text.trim().isNotEmpty
          ? serviceAreasController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : null;

      await _authController.updateUserProfile(
        userId: currentUser.id,
        fullname: fullNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        bio: bioController.text.trim(),
        companyName: companyNameController.text.trim(),
        websiteLink: mortgageApplicationUrlController.text.trim(),
        thirdPartReviewLink: externalReviewsUrlController.text.trim(),
        serviceAreas: serviceAreasList,
        areasOfExpertise: _specialtyProducts.toList(),
        licensedStates: _licensedStates.toList(),
        profilePic: _selectedProfilePic.value,
        companyLogo: _selectedCompanyLogo.value,
      );

      final currentLOController = Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;
      if (currentLOController != null) await currentLOController.refreshData(currentUser.id);

      // Get.snackbar(
      //   'Success',
      //   "Profile updated successfully!",
      //   backgroundColor: AppTheme.primaryBlue,
      //   colorText: Colors.white,
      //   snackPosition: SnackPosition.BOTTOM,
      //   margin: const EdgeInsets.all(15),
      //   icon: const Icon(Icons.check_circle, color: Colors.white),
      // );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!_isDisposed) Get.back();

    } catch (e) {
      _showError('Update failed: ${e.toString()}');
    } finally {
      if (!_isDisposed) _isLoading.value = false;
    }
  }

  bool _validateForm() {
    if (_isDisposed) return false;
    if (fullNameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return false;
    }
    if (!GetUtils.isEmail(emailController.text.trim())) {
      _showError('Please enter a valid email');
      return false;
    }
    if (companyNameController.text.trim().isEmpty) {
      _showError('Please enter your company name');
      return false;
    }
    // if (licenseNumberController.text.trim().isEmpty) {
    //   _showError('Please enter your license number');
    //   return false;
    // }
    return true;
  }

  @override
  void onClose() {
    _isDisposed = true;
    fullNameController.clear();
    emailController.clear();
    phoneController.clear();
    bioController.clear();
    licenseNumberController.clear();
    companyNameController.clear();
    mortgageApplicationUrlController.clear();
    externalReviewsUrlController.clear();
    serviceAreasController.clear();
    yearsOfExperienceController.clear();
    languagesSpokenController.clear();
    discountsOfferedController.clear();
    super.onClose();
  }

  // Logic methods
  void toggleLicensedState(String state) {
    _licensedStates.contains(state) ? _licensedStates.remove(state) : _licensedStates.add(state);
  }

  void toggleSpecialtyProduct(String product) {
    _specialtyProducts.contains(product) ? _specialtyProducts.remove(product) : _specialtyProducts.add(product);
  }
}
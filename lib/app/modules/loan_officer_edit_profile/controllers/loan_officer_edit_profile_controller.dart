import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/controllers/current_loan_officer_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/models/mortgage_types.dart';

class LoanOfficerEditProfileController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
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

  // Flag to track if controllers are disposed
  bool _isDisposed = false;

  // API Base URL for static files
  static String get _baseUrl => ApiConstants.baseUrl;

  // Getters
  bool get isLoading => _isLoading.value;
  File? get selectedProfilePic => _selectedProfilePic.value;
  File? get selectedCompanyLogo => _selectedCompanyLogo.value;
  List<String> get licensedStates => _licensedStates;
  List<String> get specialtyProducts => _specialtyProducts;

  // Get profile picture URL - returns full URL if exists, null otherwise
  // This method should be called inside Obx to properly track reactive changes
  String? getProfilePictureUrl() {
    // Access reactive variable first to ensure GetX tracks it
    final selectedPic = _selectedProfilePic.value;
    if (selectedPic != null) {
      // If a new picture is selected, return null (will use File)
      return null;
    }

    try {
      final currentLoanOfficerController = Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;
      // Access .value to ensure GetX tracks this reactive variable
      final loanOfficer = currentLoanOfficerController?.currentLoanOfficer.value;
      final profilePic = loanOfficer?.profileImage;

      if (profilePic == null || profilePic.isEmpty) {
        return null;
      }

      // If profilePic already contains http/https, return as is
      if (profilePic.startsWith('http://') || profilePic.startsWith('https://')) {
        return profilePic;
      }

      // Otherwise, prepend base URL
      String path = profilePic;
      if (!path.startsWith('/')) {
        path = '/$path';
      }

      return '$_baseUrl$path';
    } catch (e) {
      // If controller is not available, return null
      return null;
    }
  }

  // Get company logo URL
  // This method should be called inside Obx to properly track reactive changes
  String? getCompanyLogoUrl() {
    // Access reactive variable first to ensure GetX tracks it
    final selectedLogo = _selectedCompanyLogo.value;
    if (selectedLogo != null) {
      return null;
    }

    try {
      final currentLoanOfficerController = Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;
      // Access .value to ensure GetX tracks this reactive variable
      final loanOfficer = currentLoanOfficerController?.currentLoanOfficer.value;
      final companyLogo = loanOfficer?.companyLogoUrl;

      if (companyLogo == null || companyLogo.isEmpty) {
        return null;
      }

      if (companyLogo.startsWith('http://') || companyLogo.startsWith('https://')) {
        return companyLogo;
      }

      String path = companyLogo;
      if (!path.startsWith('/')) {
        path = '/$path';
      }

      return '$_baseUrl$path';
    } catch (e) {
      // If controller is not available, return null
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
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
    } else {
      // Fallback to current user from auth controller
      final user = _authController.currentUser;
      if (user != null) {
        fullNameController.text = user.name;
        emailController.text = user.email;
        phoneController.text = user.phone ?? '';
        bioController.text = user.additionalData?['bio'] ?? '';
        licenseNumberController.text = user.additionalData?['liscenceNumber'] ?? '';
        companyNameController.text = user.additionalData?['CompanyName'] ?? '';
        mortgageApplicationUrlController.text = user.additionalData?['website_link'] ?? '';
        externalReviewsUrlController.text = user.additionalData?['thirdPartReviewLink'] ?? '';
        
        // Load licensed states and specialty products from user data
        if (user.additionalData?['licensedStates'] != null) {
          _licensedStates.value = List<String>.from(user.additionalData!['licensedStates']);
        }
        if (user.additionalData?['areasOfExpertise'] != null) {
          _specialtyProducts.value = List<String>.from(user.additionalData!['areasOfExpertise']);
        }
      }
    }
  }

  Future<void> pickProfilePicture() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _selectedProfilePic.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> pickCompanyLogo() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _selectedCompanyLogo.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick logo: ${e.toString()}');
    }
  }

  void removeProfilePicture() {
    _selectedProfilePic.value = null;
  }

  void removeCompanyLogo() {
    _selectedCompanyLogo.value = null;
  }

  void toggleLicensedState(String state) {
    if (_licensedStates.contains(state)) {
      _licensedStates.remove(state);
    } else {
      _licensedStates.add(state);
    }
  }

  bool isLicensedStateSelected(String state) {
    return _licensedStates.contains(state);
  }

  void toggleSpecialtyProduct(String product) {
    if (_specialtyProducts.contains(product)) {
      _specialtyProducts.remove(product);
    } else {
      _specialtyProducts.add(product);
    }
  }

  bool isSpecialtyProductSelected(String product) {
    return _specialtyProducts.contains(product);
  }

  Future<void> saveProfile() async {
    // Check if controllers are disposed
    if (_isDisposed) {
      if (kDebugMode) {
        print('⚠️ Controllers disposed, cannot submit form');
      }
      return;
    }

    if (!_validateForm()) return;

    try {
      _isLoading.value = true;

      final currentUser = _authController.currentUser;
      if (currentUser == null) {
        Get.snackbar('Error', 'User not found. Please login again.');
        return;
      }

      // Validate user ID - must be a valid MongoDB ObjectId, not a generated one
      if (currentUser.id.isEmpty || currentUser.id.startsWith('user_')) {
        Get.snackbar(
          'Error',
          'Invalid user ID. Please logout and login again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Wrap controller access in try-catch to handle disposal during async operations
      String fullname, email, phone, bio, companyName, websiteLink, thirdPartReviewLink;
      List<String>? serviceAreasList;

      try {
        // Access controllers - will throw if disposed
        fullname = fullNameController.text.trim();
        email = emailController.text.trim();
        phone = phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : '';
        bio = bioController.text.trim().isNotEmpty
            ? bioController.text.trim()
            : '';
        companyName = companyNameController.text.trim().isNotEmpty
            ? companyNameController.text.trim()
            : '';
        websiteLink = mortgageApplicationUrlController.text.trim().isNotEmpty
            ? mortgageApplicationUrlController.text.trim()
            : '';
        thirdPartReviewLink = externalReviewsUrlController.text.trim().isNotEmpty
            ? externalReviewsUrlController.text.trim()
            : '';

        // Prepare service areas list
        if (serviceAreasController.text.trim().isNotEmpty) {
          serviceAreasList = serviceAreasController.text
              .trim()
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Controllers disposed during form submission: $e');
        }
        _isLoading.value = false;
        return;
      }

      // Debug: Print user ID being used
      if (kDebugMode) {
        print('🔍 Using User ID for update: ${currentUser.id}');
      }

      // Call API to update user
      await _authController.updateUserProfile(
        userId: currentUser.id,
        fullname: fullname,
        email: email,
        phone: phone.isNotEmpty ? phone : null,
        bio: bio.isNotEmpty ? bio : null,
        companyName: companyName.isNotEmpty ? companyName : null,
        websiteLink: websiteLink.isNotEmpty ? websiteLink : null,
        thirdPartReviewLink: thirdPartReviewLink.isNotEmpty ? thirdPartReviewLink : null,
        serviceAreas: serviceAreasList,
        areasOfExpertise: _specialtyProducts.isNotEmpty
            ? _specialtyProducts.toList()
            : null,
        licensedStates: _licensedStates.isNotEmpty
            ? _licensedStates.toList()
            : null,
        profilePic: _selectedProfilePic.value,
        companyLogo: _selectedCompanyLogo.value,
      );

      // Refresh the current loan officer data
      final currentLoanOfficerController = Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;
      if (currentLoanOfficerController != null && currentUser.id.isNotEmpty) {
        await currentLoanOfficerController.refreshData(currentUser.id);
      }

      // Success snackbar is shown in updateUserProfile method
      // Wait a moment for snackbar to be visible, then navigate back
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isDisposed) {
        Get.back();
      }
    } catch (e) {
      // Error is already handled in updateUserProfile method
      // Just log it here
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
    } finally {
      if (!_isDisposed) {
        _isLoading.value = false;
      }
    }
  }

  bool _validateForm() {
    // Check if controllers are disposed
    if (_isDisposed) {
      if (kDebugMode) {
        print('⚠️ Controllers disposed, skipping validation');
      }
      return false;
    }

    try {
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

      if (companyNameController.text.trim().isEmpty) {
        Get.snackbar('Error', 'Please enter your company name');
        return false;
      }

      if (licenseNumberController.text.trim().isEmpty) {
        Get.snackbar('Error', 'Please enter your license number');
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error validating form (controllers may be disposed): $e');
      }
      return false;
    }
  }

  @override
  void onClose() {
    // Set disposed flag first to prevent any further access
    _isDisposed = true;

    // Dispose controllers safely
    try {
      fullNameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      bioController.dispose();
      licenseNumberController.dispose();
      companyNameController.dispose();
      mortgageApplicationUrlController.dispose();
      externalReviewsUrlController.dispose();
      serviceAreasController.dispose();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error disposing controllers: $e');
      }
    }

    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    bioController.dispose();
    licenseNumberController.dispose();
    companyNameController.dispose();
    mortgageApplicationUrlController.dispose();
    externalReviewsUrlController.dispose();
    serviceAreasController.dispose();
    yearsOfExperienceController.dispose();
    languagesSpokenController.dispose();
    discountsOfferedController.dispose();
    super.onClose();
  }
}


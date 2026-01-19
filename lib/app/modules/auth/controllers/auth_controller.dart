import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

class AuthViewController extends GetxController {
  final global.AuthController _globalAuthController =
      Get.find<global.AuthController>();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  // Agent-specific form controllers
  final brokerageController = TextEditingController();
  final agentLicenseNumberController = TextEditingController();
  final bioController = TextEditingController();
  final videoUrlController = TextEditingController();
  final websiteUrlController = TextEditingController();
  final googleReviewsUrlController = TextEditingController();
  final thirdPartyReviewsUrlController = TextEditingController();
  final serviceZipCodesController =
      TextEditingController(); // Comma-separated ZIP codes

  // Loan Officer-specific form controllers
  final companyController = TextEditingController();
  final loanOfficerLicenseNumberController = TextEditingController();
  final loanOfficerBioController = TextEditingController();
  final loanOfficerVideoUrlController = TextEditingController();
  final loanOfficerWebsiteUrlController = TextEditingController();
  final mortgageApplicationUrlController = TextEditingController();
  final loanOfficerExternalReviewsUrlController = TextEditingController();

  // Observable variables
  final _isLoginMode = true.obs;
  final _selectedRole = UserRole.buyerSeller.obs;
  final _isLoading = false.obs;
  final _obscurePassword = true.obs;
  final Rxn<bool> _isDualAgencyAllowedInState = Rxn<bool>();
  final Rxn<bool> _isDualAgencyAllowedAtBrokerage = Rxn<bool>();
  final Rxn<File> _selectedProfilePic = Rxn<File>();
  final Rxn<File> _selectedCompanyLogo = Rxn<File>();
  final Rxn<File> _selectedVideo = Rxn<File>();
  final _selectedExpertise =
      <String>[].obs; // List of selected expertise areas (agents)
  final _selectedSpecialtyProducts =
      <String>[].obs; // List of selected specialty products (loan officers)
  final _selectedLicensedStates = <String>[]
      .obs; // List of selected licensed states (agents & loan officers)
  final _agentVerificationAgreed = false.obs; // Agent verification agreement
  final _loanOfficerVerificationAgreed =
      false.obs; // Loan officer verification agreement

  // Getters
  bool get isLoginMode => _isLoginMode.value;
  UserRole get selectedRole => _selectedRole.value;
  bool get isLoading => _isLoading.value;
  bool get obscurePassword => _obscurePassword.value;
  bool? get isDualAgencyAllowedInState => _isDualAgencyAllowedInState.value;
  bool? get isDualAgencyAllowedAtBrokerage =>
      _isDualAgencyAllowedAtBrokerage.value;
  File? get selectedProfilePic => _selectedProfilePic.value;
  File? get selectedCompanyLogo => _selectedCompanyLogo.value;
  File? get selectedVideo => _selectedVideo.value;
  List<String> get selectedExpertise => _selectedExpertise;
  List<String> get selectedSpecialtyProducts => _selectedSpecialtyProducts;
  List<String> get selectedLicensedStates => _selectedLicensedStates;
  bool get agentVerificationAgreed => _agentVerificationAgreed.value;
  bool get loanOfficerVerificationAgreed =>
      _loanOfficerVerificationAgreed.value;

  void setAgentVerificationAgreed(bool value) {
    _agentVerificationAgreed.value = value;
  }

  void setLoanOfficerVerificationAgreed(bool value) {
    _loanOfficerVerificationAgreed.value = value;
  }

  void toggleMode() {
    _isLoginMode.value = !_isLoginMode.value;
    _clearForm();
  }

  void togglePasswordVisibility() {
    _obscurePassword.value = !_obscurePassword.value;
  }

  void selectRole(UserRole role) {
    _selectedRole.value = role;
    // Reset dual agency fields when changing roles
    _isDualAgencyAllowedInState.value = null;
    _isDualAgencyAllowedAtBrokerage.value = null;
    // Reset agent-specific fields when changing roles
    if (role != UserRole.agent) {
      _selectedExpertise.clear();
      brokerageController.clear();
      agentLicenseNumberController.clear();
      bioController.clear();
      videoUrlController.clear();
      websiteUrlController.clear();
      googleReviewsUrlController.clear();
      thirdPartyReviewsUrlController.clear();
      serviceZipCodesController.clear();
    }
    // Reset loan officer-specific fields when changing roles
    if (role != UserRole.loanOfficer) {
      _selectedSpecialtyProducts.clear();
      companyController.clear();
      loanOfficerLicenseNumberController.clear();
      loanOfficerBioController.clear();
      loanOfficerVideoUrlController.clear();
      loanOfficerWebsiteUrlController.clear();
      mortgageApplicationUrlController.clear();
      loanOfficerExternalReviewsUrlController.clear();
    }
    // Licensed states are shared, so we don't clear them when switching roles
    // Reset verification agreements when changing roles
    _agentVerificationAgreed.value = false;
    _loanOfficerVerificationAgreed.value = false;
  }

  void toggleLicensedState(String state) {
    if (_selectedLicensedStates.contains(state)) {
      _selectedLicensedStates.remove(state);
    } else {
      _selectedLicensedStates.add(state);
    }
  }

  bool isLicensedStateSelected(String state) {
    return _selectedLicensedStates.contains(state);
  }

  void toggleExpertise(String expertise) {
    if (_selectedExpertise.contains(expertise)) {
      _selectedExpertise.remove(expertise);
    } else {
      _selectedExpertise.add(expertise);
    }
  }

  bool isExpertiseSelected(String expertise) {
    return _selectedExpertise.contains(expertise);
  }

  void toggleSpecialtyProduct(String product) {
    if (_selectedSpecialtyProducts.contains(product)) {
      _selectedSpecialtyProducts.remove(product);
    } else {
      _selectedSpecialtyProducts.add(product);
    }
  }

  bool isSpecialtyProductSelected(String product) {
    return _selectedSpecialtyProducts.contains(product);
  }

  void setDualAgencyInState(bool? value) {
    _isDualAgencyAllowedInState.value = value;
  }

  void setDualAgencyAtBrokerage(bool? value) {
    _isDualAgencyAllowedAtBrokerage.value = value;
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
      SnackbarHelper.showError('Failed to pick image: ${e.toString()}');
    }
  }

  void removeProfilePicture() {
    _selectedProfilePic.value = null;
  }

  Future<void> pickCompanyLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedCompanyLogo.value = File(image.path);
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to pick company logo: ${e.toString()}');
    }
  }

  void removeCompanyLogo() {
    _selectedCompanyLogo.value = null;
  }

  Future<void> pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        _selectedVideo.value = File(video.path);
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to pick video: ${e.toString()}');
    }
  }

  void removeVideo() {
    _selectedVideo.value = null;
  }

  void _clearForm() {
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    phoneController.clear();
    _isDualAgencyAllowedInState.value = null;
    _isDualAgencyAllowedAtBrokerage.value = null;
    _selectedProfilePic.value = null;
    _selectedCompanyLogo.value = null;
    _selectedVideo.value = null;
    // Clear agent-specific fields
    brokerageController.clear();
    agentLicenseNumberController.clear();
    bioController.clear();
    videoUrlController.clear();
    websiteUrlController.clear();
    googleReviewsUrlController.clear();
    thirdPartyReviewsUrlController.clear();
    serviceZipCodesController.clear();
    _selectedExpertise.clear();
    // Clear loan officer-specific fields
    companyController.clear();
    loanOfficerLicenseNumberController.clear();
    loanOfficerBioController.clear();
    loanOfficerVideoUrlController.clear();
    loanOfficerWebsiteUrlController.clear();
    mortgageApplicationUrlController.clear();
    loanOfficerExternalReviewsUrlController.clear();
    _selectedSpecialtyProducts.clear();
    // Clear video file
    _selectedVideo.value = null;
    // Clear licensed states
    _selectedLicensedStates.clear();
    // Clear verification agreements
    _agentVerificationAgreed.value = false;
    _loanOfficerVerificationAgreed.value = false;
  }

  Future<void> submitForm() async {
    if (!_validateForm()) return;

    try {
      _isLoading.value = true;

      if (isLoginMode) {
        await _globalAuthController.login(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      } else {
        // Prepare additional data for agents and loan officers
        Map<String, dynamic>? additionalData;
        List<String>? licensedStatesList = _selectedLicensedStates.isNotEmpty
            ? _selectedLicensedStates.toList()
            : null;

        if (selectedRole == UserRole.agent) {
          additionalData = {
            'brokerage': brokerageController.text.trim(),
            'licenseNumber': agentLicenseNumberController.text.trim(),
            'isDualAgencyAllowedInState': isDualAgencyAllowedInState,
            'isDualAgencyAllowedAtBrokerage': isDualAgencyAllowedAtBrokerage,
            // Agent profile fields
            if (bioController.text.trim().isNotEmpty)
              'bio': bioController.text.trim(),
            if (videoUrlController.text.trim().isNotEmpty)
              'videoUrl': videoUrlController.text.trim(),
            if (_selectedExpertise.isNotEmpty) 'expertise': _selectedExpertise,
            if (websiteUrlController.text.trim().isNotEmpty)
              'websiteUrl': websiteUrlController.text.trim(),
            if (googleReviewsUrlController.text.trim().isNotEmpty)
              'googleReviewsUrl': googleReviewsUrlController.text.trim(),
            if (thirdPartyReviewsUrlController.text.trim().isNotEmpty)
              'thirdPartyReviewsUrl': thirdPartyReviewsUrlController.text
                  .trim(),
            if (serviceZipCodesController.text.trim().isNotEmpty)
              'serviceZipCodes': serviceZipCodesController.text
                  .trim()
                  .split(',')
                  .map((z) => z.trim())
                  .where((z) => z.isNotEmpty)
                  .toList(),
            'verificationAgreed': _agentVerificationAgreed.value,
          };
        } else if (selectedRole == UserRole.loanOfficer) {
          additionalData = {
            'company': companyController.text.trim(),
            'licenseNumber': loanOfficerLicenseNumberController.text.trim(),
            // Loan officer profile fields
            if (loanOfficerBioController.text.trim().isNotEmpty)
              'bio': loanOfficerBioController.text.trim(),
            if (loanOfficerVideoUrlController.text.trim().isNotEmpty)
              'videoUrl': loanOfficerVideoUrlController.text.trim(),
            if (_selectedSpecialtyProducts.isNotEmpty)
              'specialtyProducts': _selectedSpecialtyProducts,
            if (loanOfficerWebsiteUrlController.text.trim().isNotEmpty)
              'websiteUrl': loanOfficerWebsiteUrlController.text.trim(),
            if (mortgageApplicationUrlController.text.trim().isNotEmpty)
              'mortgageApplicationUrl': mortgageApplicationUrlController.text
                  .trim(),
            if (loanOfficerExternalReviewsUrlController.text.trim().isNotEmpty)
              'externalReviewsUrl': loanOfficerExternalReviewsUrlController.text
                  .trim(),
            'verificationAgreed': _loanOfficerVerificationAgreed.value,
          };
        }

        await _globalAuthController.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          name: nameController.text.trim(),
          role: selectedRole,
          phone: phoneController.text.trim().isNotEmpty
              ? phoneController.text.trim()
              : null,
          licensedStates: licensedStatesList,
          additionalData: additionalData,
          profilePic: _selectedProfilePic.value,
          companyLogo: _selectedCompanyLogo.value,
          video: _selectedVideo.value,
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> socialLogin(String provider) async {
    try {
      _isLoading.value = true;

      // Mock social login data
      final mockData = {
        'google': {
          'email': 'user@gmail.com',
          'name': 'Google User',
          'profileImage': null,
        },
        'apple': {
          'email': 'user@icloud.com',
          'name': 'Apple User',
          'profileImage': null,
        },
        'facebook': {
          'email': 'user@facebook.com',
          'name': 'Facebook User',
          'profileImage': null,
        },
      };

      final data = mockData[provider];
      if (data != null) {
        await _globalAuthController.socialLogin(
          provider: provider,
          email: data['email']!,
          name: data['name']!,
          profileImage: data['profileImage'],
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  bool _validateForm() {
    if (emailController.text.trim().isEmpty) {
      SnackbarHelper.showError('Please enter your email');
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      SnackbarHelper.showError('Please enter a valid email');
      return false;
    }

    if (passwordController.text.isEmpty) {
      SnackbarHelper.showError('Please enter your password');
      return false;
    }

    if (passwordController.text.length < 6) {
      SnackbarHelper.showError('Password must be at least 6 characters');
      return false;
    }

    if (!isLoginMode) {
      if (nameController.text.trim().isEmpty) {
        SnackbarHelper.showError('Please enter your name');
        return false;
      }

      // Validate required fields for agents
      if (selectedRole == UserRole.agent) {
        if (brokerageController.text.trim().isEmpty) {
          SnackbarHelper.showError('Please enter your brokerage name');
          return false;
        }
        if (agentLicenseNumberController.text.trim().isEmpty) {
          SnackbarHelper.showError('Please enter your license number');
          return false;
        }
        if (_selectedLicensedStates.isEmpty) {
          SnackbarHelper.showError('Please select at least one licensed state');
          return false;
        }
        if (isDualAgencyAllowedInState == null) {
          SnackbarHelper.showError(
            'Please answer if dual agency is allowed in your state',
          );
          return false;
        }
        if (isDualAgencyAllowedAtBrokerage == null) {
          SnackbarHelper.showError(
            'Please answer if dual agency is allowed at your brokerage',
          );
          return false;
        }
        if (!_agentVerificationAgreed.value) {
          SnackbarHelper.showError('Please confirm the verification statement');
          return false;
        }
      }

      // Validate required fields for loan officers
      if (selectedRole == UserRole.loanOfficer) {
        if (companyController.text.trim().isEmpty) {
          SnackbarHelper.showError('Please enter your company name');
          return false;
        }
        if (loanOfficerLicenseNumberController.text.trim().isEmpty) {
          SnackbarHelper.showError('Please enter your license number');
          return false;
        }
        if (_selectedLicensedStates.isEmpty) {
          SnackbarHelper.showError('Please select at least one licensed state');
          return false;
        }
        if (!_loanOfficerVerificationAgreed.value) {
          SnackbarHelper.showError('Please confirm the verification statement');
          return false;
        }
      }
    }

    return true;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    brokerageController.dispose();
    agentLicenseNumberController.dispose();
    bioController.dispose();
    videoUrlController.dispose();
    websiteUrlController.dispose();
    googleReviewsUrlController.dispose();
    thirdPartyReviewsUrlController.dispose();
    serviceZipCodesController.dispose();
    companyController.dispose();
    loanOfficerLicenseNumberController.dispose();
    loanOfficerBioController.dispose();
    loanOfficerVideoUrlController.dispose();
    loanOfficerWebsiteUrlController.dispose();
    mortgageApplicationUrlController.dispose();
    loanOfficerExternalReviewsUrlController.dispose();
    super.onClose();
  }
}

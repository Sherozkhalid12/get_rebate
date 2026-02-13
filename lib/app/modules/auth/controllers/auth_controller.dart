import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/controllers/auth_controller.dart' show EmailAlreadyExistsException;
import 'package:getrebate/app/controllers/location_controller.dart';
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/modules/auth/services/pending_signup_store.dart';
import 'package:getrebate/app/modules/auth/views/verify_otp_view.dart';
import 'package:getrebate/app/modules/auth/bindings/verify_otp_binding.dart';
import 'package:getrebate/app/services/rebate_states_service.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

class AuthViewController extends GetxController {
  final global.AuthController _globalAuthController =
      Get.find<global.AuthController>();
  final LocationController _locationController = Get.find<LocationController>();
  final ImagePicker _imagePicker = ImagePicker();
  final RebateStatesService _rebateStatesService = RebateStatesService();
  
  // Observable for allowed states
  final _allowedStates = <String>[].obs;

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  // Agent-specific form controllers
  final brokerageController = TextEditingController();
  final agentLicenseNumberController = TextEditingController();
  final bioController = TextEditingController();
  final websiteUrlController = TextEditingController();
  final googleReviewsUrlController = TextEditingController();
  final thirdPartyReviewsUrlController = TextEditingController();
  final serviceZipCodesController =
      TextEditingController(); // Comma-separated ZIP codes

  // Loan Officer-specific form controllers
  final companyController = TextEditingController();
  final loanOfficerLicenseNumberController = TextEditingController();
  final loanOfficerBioController = TextEditingController();
  final loanOfficerWebsiteUrlController = TextEditingController();
  final mortgageApplicationUrlController = TextEditingController();
  final loanOfficerExternalReviewsUrlController = TextEditingController();
  final loanOfficerOfficeZipController = TextEditingController();

  // Observable variables
  final _isLoginMode = true.obs;
  final _selectedRole = UserRole.buyerSeller.obs;
  final _isLoading = false.obs;
  final _obscurePassword = true.obs;
  // Store email to pre-fill when navigating back from OTP screen
  String? _pendingEmailToFill;
  
  /// Sets the email to pre-fill when the widget is ready (used when navigating back from OTP)
  void setPendingEmailToFill(String email) {
    _pendingEmailToFill = email;
  }
  
  /// Clears the pending email to fill
  void clearPendingEmailToFill() {
    _pendingEmailToFill = null;
  }
  
  /// Gets the pending email to fill (if any)
  String? get pendingEmailToFill => _pendingEmailToFill;
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
  final _termsOfServiceViewed = false.obs; // Track if user has viewed Terms of Service
  final _termsOfServiceAgreed = false.obs; // Track if user has agreed to Terms of Service

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
  bool get termsOfServiceViewed => _termsOfServiceViewed.value;
  bool get termsOfServiceAgreed => _termsOfServiceAgreed.value;
  List<String> get allowedStates => _allowedStates.isEmpty 
      ? RebateStatesService.getFallbackAllowedStates() 
      : _allowedStates;

  void setAgentVerificationAgreed(bool value) {
    _agentVerificationAgreed.value = value;
  }

  void setLoanOfficerVerificationAgreed(bool value) {
    _loanOfficerVerificationAgreed.value = value;
  }

  void setTermsOfServiceAgreed(bool value) {
    _termsOfServiceAgreed.value = value;
    // When user checks the box, mark as viewed (they acknowledge reading)
    if (value) {
      _termsOfServiceViewed.value = true;
    }
  }

  /// Opens the Terms of Service page and marks it as viewed when user returns
  Future<void> openTermsOfService() async {
    await Get.toNamed('/terms-of-service');
    // Mark as viewed when user returns from the terms page
    // This ensures users must actually open the page before they can agree
    _termsOfServiceViewed.value = true;
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
      loanOfficerWebsiteUrlController.clear();
      mortgageApplicationUrlController.clear();
      loanOfficerExternalReviewsUrlController.clear();
      loanOfficerOfficeZipController.clear();
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

  /// Uses cached current location zip for the given controller (instant, no fetch on tap).
  void useCurrentLocationForZip(TextEditingController zipController) {
    final zipCode = _locationController.currentZipCode;
    if (zipCode != null &&
        zipCode.length == 5 &&
        RegExp(r'^\d+$').hasMatch(zipCode)) {
      zipController.text = zipCode;
      zipController.selection = TextSelection.collapsed(offset: zipCode.length);
    } else {
      SnackbarHelper.showInfo(
        'Location not ready yet. Please wait a moment and try again, or enter ZIP manually.',
        title: 'Location',
        duration: const Duration(seconds: 3),
      );
    }
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
    websiteUrlController.clear();
    googleReviewsUrlController.clear();
    thirdPartyReviewsUrlController.clear();
    serviceZipCodesController.clear();
    _selectedExpertise.clear();
    // Clear loan officer-specific fields
    companyController.clear();
    loanOfficerLicenseNumberController.clear();
    loanOfficerBioController.clear();
    loanOfficerWebsiteUrlController.clear();
    mortgageApplicationUrlController.clear();
    loanOfficerExternalReviewsUrlController.clear();
    loanOfficerOfficeZipController.clear();
    _selectedSpecialtyProducts.clear();
    // Clear video file
    _selectedVideo.value = null;
    // Clear licensed states
    _selectedLicensedStates.clear();
    // Clear verification agreements
    _agentVerificationAgreed.value = false;
    _loanOfficerVerificationAgreed.value = false;
    // Clear terms of service acceptance
    _termsOfServiceViewed.value = false;
    _termsOfServiceAgreed.value = false;
  }

  Future<void> submitForm() async {
    if (!_validateForm()) return;

    // Capture email outside try-catch for error handling
    final email = emailController.text.trim();

    try {
      _isLoading.value = true;

      if (isLoginMode) {
        await _globalAuthController.login(
          email: email,
          password: passwordController.text,
        );
      } else {
        // Signup: send verification email first, then navigate to OTP screen
        final phoneValue = phoneController.text.trim();
        final phoneToSend = phoneValue.isNotEmpty ? phoneValue : null;
        final licensedStatesList = _selectedLicensedStates.isNotEmpty
            ? _selectedLicensedStates.toList()
            : null;

        Map<String, dynamic>? additionalData;
        if (selectedRole == UserRole.agent) {
          final officeZipCode = serviceZipCodesController.text.trim();
          final officeZipCodesList = officeZipCode.isNotEmpty
              ? [officeZipCode]
              : null;
          additionalData = {
            'brokerage': brokerageController.text.trim(),
            'licenseNumber': agentLicenseNumberController.text.trim(),
            'isDualAgencyAllowedInState': isDualAgencyAllowedInState,
            'isDualAgencyAllowedAtBrokerage': isDualAgencyAllowedAtBrokerage,
            // Agent profile fields
            if (bioController.text.trim().isNotEmpty)
              'bio': bioController.text.trim(),
            if (_selectedExpertise.isNotEmpty) 'expertise': _selectedExpertise,
            if (websiteUrlController.text.trim().isNotEmpty)
              'websiteUrl': websiteUrlController.text.trim(),
            if (googleReviewsUrlController.text.trim().isNotEmpty)
              'googleReviewsUrl': googleReviewsUrlController.text.trim(),
            if (thirdPartyReviewsUrlController.text.trim().isNotEmpty)
              'thirdPartyReviewsUrl': thirdPartyReviewsUrlController.text
                  .trim(),
            if (officeZipCode.isNotEmpty) 'zipCode': officeZipCode,
            if (officeZipCodesList != null)
              'serviceZipCodes': officeZipCodesList,
            'verificationAgreed': _agentVerificationAgreed.value,
            // Terms of Service acceptance (required for all users)
            'termsOfServiceAgreed': _termsOfServiceAgreed.value,
            'termsOfServiceViewed': _termsOfServiceViewed.value,
          };
        } else if (selectedRole == UserRole.loanOfficer) {
          final officeZipCode = loanOfficerOfficeZipController.text.trim();
          final officeZipCodesList = officeZipCode.isNotEmpty
              ? [officeZipCode]
              : null;
          additionalData = {
            'company': companyController.text.trim(),
            'licenseNumber': loanOfficerLicenseNumberController.text.trim(),
            // Loan officer profile fields
            if (loanOfficerBioController.text.trim().isNotEmpty)
              'bio': loanOfficerBioController.text.trim(),
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
            if (officeZipCode.isNotEmpty) 'zipCode': officeZipCode,
            if (officeZipCodesList != null) 'serviceAreas': officeZipCodesList,
            'verificationAgreed': _loanOfficerVerificationAgreed.value,
            // Terms of Service acceptance (required for all users)
            'termsOfServiceAgreed': _termsOfServiceAgreed.value,
            'termsOfServiceViewed': _termsOfServiceViewed.value,
          };
        } else {
          // Buyer/Seller - still need to include terms acceptance
          additionalData = {
            // Terms of Service acceptance (required for all users)
            'termsOfServiceAgreed': _termsOfServiceAgreed.value,
            'termsOfServiceViewed': _termsOfServiceViewed.value,
          };
        }

        // Step 1: Send verification email (API: POST /api/v1/auth/sendVerificationEmail)
        if (kDebugMode) {
          print('📧 Signup flow: Sending verification email to $email');
        }
        await _globalAuthController.sendVerificationEmail(email);
        if (kDebugMode) print('✅ Verification email sent. Navigating to OTP screen.');
        SnackbarHelper.showSuccess('Verification code sent! Check your email.');

        // Step 2: Store payload and navigate to OTP screen (avoid passing File/UserRole via Get.arguments)
        PendingSignUpStore.instance.set(
          email: email,
          password: passwordController.text,
          name: nameController.text.trim(),
          role: selectedRole,
          phone: phoneToSend,
          licensedStates: licensedStatesList,
          additionalData: additionalData,
          profilePic: _selectedProfilePic.value,
          companyLogo: _selectedCompanyLogo.value,
          video: _selectedVideo.value,
        );
        Get.to(
          () => const VerifyOtpView(),
          binding: VerifyOtpBinding(),
          arguments: {'email': email},
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Signup/OTP flow exception: $e');
        print('   Exception type: ${e.runtimeType}');
        print('   Stack: $stack');
      }
      
      // Check if error indicates email already exists
      String errorMessage = e.toString();
      bool isEmailExists = false;
      
      // First check: Is it the custom EmailAlreadyExistsException?
      if (e is EmailAlreadyExistsException) {
        isEmailExists = true;
        errorMessage = e.message;
        if (kDebugMode) {
          print('✅ Caught EmailAlreadyExistsException: $errorMessage');
        }
      } else if (e.toString().contains('EmailAlreadyExistsException')) {
        isEmailExists = true;
        // Extract the message
        if (errorMessage.contains('EmailAlreadyExistsException: ')) {
          errorMessage = errorMessage.split('EmailAlreadyExistsException: ').last.trim();
        } else if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.split('Exception: ').last.trim();
        }
      } 
      // Second check: DioException with specific status codes or messages
      else if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        // Simple check: Look for success: false with email exists message
        if (responseData is Map) {
          final success = responseData['success'];
          final msg = responseData['message']?.toString().toLowerCase() ?? '';
          
          // Check for the specific API response format
          if (success == false && 
              (msg.contains('user with this email or phone already exists') ||
               msg.contains('email already exists') ||
               msg.contains('user already exists'))) {
            isEmailExists = true;
            errorMessage = responseData['message']?.toString() ?? 
                'An account with this email already exists';
          }
        }
      } 
      // Third check: Generic exception with email exists message (only if explicitly about email)
      else {
        final lowerError = errorMessage.toLowerCase();
        // Only check for very specific email existence patterns
        if (lowerError.contains('email already exists') ||
            lowerError.contains('user already exists') ||
            lowerError.contains('account already exists') ||
            lowerError.contains('an account with this email already exists')) {
          isEmailExists = true;
        }
      }
      
      if (isEmailExists && !isLoginMode) {
        if (kDebugMode) {
          print('🚫 Email already exists - switching to login mode');
        }
        // Store email to pre-fill after mode switch
        _pendingEmailToFill = email;
        // Switch to login mode (this clears the form, so we'll fill email after)
        if (!isLoginMode) {
          toggleMode();
        }
        // Pre-fill email using post-frame callback to ensure widget is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (_pendingEmailToFill != null) {
              emailController.text = _pendingEmailToFill!;
              _pendingEmailToFill = null; // Clear after setting
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Error setting email text: $e');
            }
            _pendingEmailToFill = null; // Clear on error too
          }
        });
        // Show message after a short delay
        Future.delayed(const Duration(milliseconds: 100), () {
          SnackbarHelper.showError(
            'An account with this email already exists. Please sign in instead.',
          );
        });
        return; // PREVENTS NAVIGATION TO OTP SCREEN
      } else {
        SnackbarHelper.showError(errorMessage);
      }
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
      SnackbarHelper.showError(e.toString());
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

      // Phone is optional for all roles (including buyer/seller); do not require it when empty.

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
        if (serviceZipCodesController.text.trim().isEmpty) {
          SnackbarHelper.showError('Please enter your office ZIP code');
          return false;
        }
        if (!RegExp(r'^\d{5}$').hasMatch(serviceZipCodesController.text.trim())) {
          SnackbarHelper.showError('Office ZIP code must be exactly 5 digits');
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
        if (loanOfficerOfficeZipController.text.trim().isEmpty) {
          SnackbarHelper.showError('Please enter your office ZIP code');
          return false;
        }
        if (!RegExp(r'^\d{5}$')
            .hasMatch(loanOfficerOfficeZipController.text.trim())) {
          SnackbarHelper.showError('Office ZIP code must be exactly 5 digits');
          return false;
        }
        if (!_loanOfficerVerificationAgreed.value) {
          SnackbarHelper.showError('Please confirm the verification statement');
          return false;
        }
      }

      // Validate Terms of Service acceptance for ALL user types
      if (!_termsOfServiceAgreed.value) {
        SnackbarHelper.showError('You must agree to the Terms of Service to create an account');
        return false;
      }
    }

    return true;
  }

  @override
  @override
  void onReady() {
    super.onReady();
    // Pre-fill email if there's a pending email (e.g., from OTP screen navigation)
    if (_pendingEmailToFill != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          emailController.text = _pendingEmailToFill!;
          _pendingEmailToFill = null;
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error pre-filling email in onReady: $e');
          }
          _pendingEmailToFill = null;
        }
      });
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadAllowedStates();
  }

  Future<void> _loadAllowedStates() async {
    try {
      final states = await _rebateStatesService.getAllowedStates();
      _allowedStates.value = states..sort();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to load allowed states: $e');
      }
      // Fallback is handled in the getter
      _allowedStates.value = RebateStatesService.getFallbackAllowedStates()..sort();
    }
  }

  /// Shows a dialog when user tries to sign up with an existing email
  void showAccountExistsDialog(String email) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: AppTheme.primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Account Already Exists',
                      style: Theme.of(Get.context!).textTheme.titleLarge?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Message
              Text(
                'An account with the email "$email" already exists. Would you like to sign in instead?',
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: AppTheme.mediumGray),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppTheme.darkGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        // Switch to login mode and pre-fill email
                        toggleMode();
                        emailController.text = email;
                        SnackbarHelper.showInfo(
                          'Please enter your password to sign in.',
                          duration: const Duration(seconds: 3),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
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
    websiteUrlController.dispose();
    googleReviewsUrlController.dispose();
    thirdPartyReviewsUrlController.dispose();
    serviceZipCodesController.dispose();
    companyController.dispose();
    loanOfficerLicenseNumberController.dispose();
    loanOfficerBioController.dispose();
    loanOfficerWebsiteUrlController.dispose();
    mortgageApplicationUrlController.dispose();
    loanOfficerExternalReviewsUrlController.dispose();
    super.onClose();
  }
}

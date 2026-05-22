import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getrebate/firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? DefaultFirebaseOptions.ios.iosClientId
        : null,
  );
  
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
  final _isCompleteProfileMode = false.obs;
  final _selectedRole = UserRole.buyerSeller.obs;
  final _isLoading = false.obs;
  final _obscurePassword = true.obs;
  // Store email to pre-fill when navigating back from OTP screen
  String? _pendingEmailToFill;
  // Social sign-in credentials to pre-fill Complete Profile (survives route teardown)
  String? _pendingSocialEmail;
  String? _pendingSocialName;
  
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
  bool get isCompleteProfileMode => _isCompleteProfileMode.value;
  bool get showSignupFields => !isLoginMode || isCompleteProfileMode;
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
        final normalizedPhone = _normalizePhone(phoneValue);
        final phoneToSend = normalizedPhone.isNotEmpty ? normalizedPhone : null;
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
    if (provider != 'google' && provider != 'apple') {
      SnackbarHelper.showInfo(
        '${provider[0].toUpperCase()}${provider.substring(1)} login is not available.',
      );
      return;
    }

    if (_isLoading.value) return;

    try {
      _isLoading.value = true;

      // Role is chosen on Complete Profile — do not send role during social sign-in.
      const String? roleForApi = null;

      if (provider == 'google') {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}

        final GoogleSignInAccount? account = await _googleSignIn.signIn();

        if (account == null) {
          SnackbarHelper.showInfo('Google sign-in was cancelled.');
          return;
        }

        final email = account.email;
        final fullName = account.displayName ?? email.split('@').first;

        _applySocialPrefill(email: email, name: fullName);

        await _globalAuthController.socialLogin(
          provider: provider,
          email: email,
          name: fullName,
          profileImage: account.photoUrl,
          role: roleForApi,
        );
      } else {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final email = credential.email;
        if (email == null || email.isEmpty) {
          SnackbarHelper.showError(
            'Apple did not provide an email. Use Sign in with Apple on first sign-in, or sign in with Google.',
          );
          return;
        }

        final given = credential.givenName ?? '';
        final family = credential.familyName ?? '';
        final fullName = '$given $family'.trim();
        final displayName =
            fullName.isNotEmpty ? fullName : email.split('@').first;

        _applySocialPrefill(email: email, name: displayName);

        await _globalAuthController.socialLogin(
          provider: provider,
          email: email,
          name: displayName,
          profileImage: null,
          role: roleForApi,
        );
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        SnackbarHelper.showError(
          'Apple sign-in failed: ${e.message}',
        );
      }
    } on PlatformException catch (e) {
      SnackbarHelper.showError(
        'Sign-in failed: ${e.message ?? e.code}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Social login error (controller): $e');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  void _applySocialPrefill({required String email, required String name}) {
    _pendingSocialEmail = email.trim();
    _pendingSocialName = name.trim();
    try {
      emailController.text = _pendingSocialEmail!;
      nameController.text = _pendingSocialName!;
    } catch (_) {}
  }

  void _clearSocialPrefill() {
    _pendingSocialEmail = null;
    _pendingSocialName = null;
  }

  void initCompleteProfileMode() {
    final user = _globalAuthController.currentUser;
    if (user == null) {
      Get.offAllNamed('/auth');
      return;
    }

    _isCompleteProfileMode.value = true;
    _isLoginMode.value = false;

    final email = _pendingSocialEmail?.isNotEmpty == true
        ? _pendingSocialEmail!
        : user.email;
    final name = _pendingSocialName?.isNotEmpty == true
        ? _pendingSocialName!
        : user.name;

    try {
      nameController.text = name;
      emailController.text = email;
    } catch (_) {}
    if (user.phone != null && user.phone!.isNotEmpty) {
      phoneController.text = user.phone!;
    }

    // After social login, let the user pick their role (don't use API default).
    if (_globalAuthController.pendingSocialProfileCompletion) {
      _selectedRole.value = UserRole.buyerSeller;
      _clearRoleSpecificFormFields();
      return;
    }

    _selectedRole.value = user.role;

    final ad = user.additionalData ?? {};
    if (user.role == UserRole.agent) {
      brokerageController.text = ad['CompanyName']?.toString() ?? '';
      agentLicenseNumberController.text =
          ad['liscenceNumber']?.toString() ?? '';
      bioController.text = ad['bio']?.toString() ?? '';
      websiteUrlController.text = ad['website_link']?.toString() ?? '';
      googleReviewsUrlController.text =
          ad['google_reviews_link']?.toString() ?? '';
      thirdPartyReviewsUrlController.text =
          ad['thirdPartReviewLink']?.toString() ?? '';
      serviceZipCodesController.text = ad['zipCode']?.toString() ?? '';
      if (ad['dualAgencyState'] != null) {
        _isDualAgencyAllowedInState.value = ad['dualAgencyState'] == true ||
            ad['dualAgencyState'].toString().toLowerCase() == 'true';
      }
      if (ad['dualAgencySBrokerage'] != null) {
        _isDualAgencyAllowedAtBrokerage.value =
            ad['dualAgencySBrokerage'] == true ||
                ad['dualAgencySBrokerage'].toString().toLowerCase() == 'true';
      }
      if (ad['areasOfExpertise'] is List) {
        _selectedExpertise.assignAll(
          List<String>.from(ad['areasOfExpertise']),
        );
      }
      _agentVerificationAgreed.value =
          ad['verificationStatement'] == true ||
              ad['verificationStatement'].toString().toLowerCase() == 'true';
    } else if (user.role == UserRole.loanOfficer) {
      companyController.text = ad['CompanyName']?.toString() ?? '';
      loanOfficerLicenseNumberController.text =
          ad['liscenceNumber']?.toString() ?? '';
      loanOfficerBioController.text = ad['bio']?.toString() ?? '';
      loanOfficerWebsiteUrlController.text =
          ad['website_link']?.toString() ?? '';
      mortgageApplicationUrlController.text =
          ad['mortgageApplicationUrl']?.toString() ?? '';
      loanOfficerExternalReviewsUrlController.text =
          ad['externalReviewsUrl']?.toString() ??
              ad['thirdPartReviewLink']?.toString() ??
              '';
      loanOfficerOfficeZipController.text = ad['zipCode']?.toString() ?? '';
      if (ad['specialtyProducts'] is List) {
        _selectedSpecialtyProducts.assignAll(
          List<String>.from(ad['specialtyProducts']),
        );
      }
      _loanOfficerVerificationAgreed.value =
          ad['verificationStatement'] == true ||
              ad['verificationStatement'].toString().toLowerCase() == 'true';
    }

    if (user.licensedStates.isNotEmpty) {
      _selectedLicensedStates.assignAll(user.licensedStates);
    }
  }

  void _clearRoleSpecificFormFields() {
    _isDualAgencyAllowedInState.value = null;
    _isDualAgencyAllowedAtBrokerage.value = null;
    brokerageController.clear();
    agentLicenseNumberController.clear();
    bioController.clear();
    websiteUrlController.clear();
    googleReviewsUrlController.clear();
    thirdPartyReviewsUrlController.clear();
    serviceZipCodesController.clear();
    _selectedExpertise.clear();
    companyController.clear();
    loanOfficerLicenseNumberController.clear();
    loanOfficerBioController.clear();
    loanOfficerWebsiteUrlController.clear();
    mortgageApplicationUrlController.clear();
    loanOfficerExternalReviewsUrlController.clear();
    loanOfficerOfficeZipController.clear();
    _selectedSpecialtyProducts.clear();
    _selectedLicensedStates.clear();
    _agentVerificationAgreed.value = false;
    _loanOfficerVerificationAgreed.value = false;
  }

  Future<void> submitCompleteProfile() async {
    if (!_validateForm()) return;

    final user = _globalAuthController.currentUser;
    if (user == null) {
      SnackbarHelper.showError('Session expired. Please sign in again.');
      return;
    }

    try {
      _isLoading.value = true;

      final phoneValue = phoneController.text.trim();
      final normalizedPhone = _normalizePhone(phoneValue);
      final phoneToSend = normalizedPhone.isNotEmpty ? normalizedPhone : null;
      final licensedStatesList = _selectedLicensedStates.isNotEmpty
          ? _selectedLicensedStates.toList()
          : null;
      final roleApi = _globalAuthController.mapRoleToApiFormat(selectedRole);

      if (selectedRole == UserRole.agent) {
        final officeZipCode = serviceZipCodesController.text.trim();
        final serviceAreas = officeZipCode.isNotEmpty ? [officeZipCode] : null;

        await _globalAuthController.updateUserProfile(
          userId: user.id,
          role: roleApi,
          fullname: nameController.text.trim(),
          phone: phoneToSend,
          bio: bioController.text.trim().isNotEmpty
              ? bioController.text.trim()
              : null,
          licenseNumber: agentLicenseNumberController.text.trim(),
          zipCode: officeZipCode.isNotEmpty ? officeZipCode : null,
          companyName: brokerageController.text.trim(),
          websiteLink: websiteUrlController.text.trim().isNotEmpty
              ? websiteUrlController.text.trim()
              : null,
          googleReviewsLink: googleReviewsUrlController.text.trim().isNotEmpty
              ? googleReviewsUrlController.text.trim()
              : null,
          thirdPartReviewLink:
              thirdPartyReviewsUrlController.text.trim().isNotEmpty
              ? thirdPartyReviewsUrlController.text.trim()
              : null,
          serviceAreas: serviceAreas,
          areasOfExpertise: _selectedExpertise.isNotEmpty
              ? _selectedExpertise.toList()
              : null,
          licensedStates: licensedStatesList,
          dualAgencyState: isDualAgencyAllowedInState,
          dualAgencySBrokerage: isDualAgencyAllowedAtBrokerage,
          verificationStatement: _agentVerificationAgreed.value,
          profilePic: _selectedProfilePic.value,
          companyLogo: _selectedCompanyLogo.value,
          video: _selectedVideo.value,
        );
      } else if (selectedRole == UserRole.loanOfficer) {
        final officeZipCode = loanOfficerOfficeZipController.text.trim();
        final serviceAreas = officeZipCode.isNotEmpty ? [officeZipCode] : null;

        await _globalAuthController.updateUserProfile(
          userId: user.id,
          role: roleApi,
          fullname: nameController.text.trim(),
          phone: phoneToSend,
          bio: loanOfficerBioController.text.trim().isNotEmpty
              ? loanOfficerBioController.text.trim()
              : null,
          licenseNumber: loanOfficerLicenseNumberController.text.trim(),
          zipCode: officeZipCode.isNotEmpty ? officeZipCode : null,
          companyName: companyController.text.trim(),
          websiteLink: loanOfficerWebsiteUrlController.text.trim().isNotEmpty
              ? loanOfficerWebsiteUrlController.text.trim()
              : null,
          mortgageApplicationUrl:
              mortgageApplicationUrlController.text.trim().isNotEmpty
              ? mortgageApplicationUrlController.text.trim()
              : null,
          externalReviewsUrl:
              loanOfficerExternalReviewsUrlController.text.trim().isNotEmpty
              ? loanOfficerExternalReviewsUrlController.text.trim()
              : null,
          serviceAreas: serviceAreas,
          specialtyProducts: _selectedSpecialtyProducts.isNotEmpty
              ? _selectedSpecialtyProducts.toList()
              : null,
          licensedStates: licensedStatesList,
          verificationStatement: _loanOfficerVerificationAgreed.value,
          profilePic: _selectedProfilePic.value,
          companyLogo: _selectedCompanyLogo.value,
          video: _selectedVideo.value,
        );
      } else {
        await _globalAuthController.updateUserProfile(
          userId: user.id,
          role: roleApi,
          fullname: nameController.text.trim(),
          phone: phoneToSend,
          profilePic: _selectedProfilePic.value,
        );
      }

      _globalAuthController.clearPendingSocialProfileCompletion();
      _clearSocialPrefill();
      _isCompleteProfileMode.value = false;
      await _globalAuthController.finishAuthNavigation();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Complete profile error: $e');
      }
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

    if (!isCompleteProfileMode) {
      if (passwordController.text.isEmpty) {
        SnackbarHelper.showError('Please enter your password');
        return false;
      }

      if (passwordController.text.length < 6) {
        SnackbarHelper.showError('Password must be at least 6 characters');
        return false;
      }
    }

    if (showSignupFields) {
      if (nameController.text.trim().isEmpty) {
        SnackbarHelper.showError('Please enter your name');
        return false;
      }

      // Phone is required for Agent and Loan Officer, optional for Buyer/Seller
      final phoneValue = phoneController.text.trim();
      if (selectedRole == UserRole.agent || selectedRole == UserRole.loanOfficer) {
        if (phoneValue.isEmpty) {
          SnackbarHelper.showError('Please enter your phone number');
          return false;
        }
      }
      if (phoneValue.isNotEmpty && !_isValidPhone(phoneValue)) {
        SnackbarHelper.showError('Phone number must be 10 to 15 digits');
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

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  bool _isValidPhone(String value) {
    final digits = _normalizePhone(value);
    return digits.length >= 10 && digits.length <= 15;
  }

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
    // Do not clear fields when routing to Complete Profile after social login.
    if (_globalAuthController.pendingSocialProfileCompletion) {
      super.onClose();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_globalAuthController.pendingSocialProfileCompletion) {
        _disposeControllers();
      }
    });
    super.onClose();
  }

  void _disposeControllers() {
    try {
      emailController.clear();
    } catch (_) {}
    try {
      passwordController.clear();
    } catch (_) {}
    try {
      nameController.clear();
    } catch (_) {}
    try {
      phoneController.clear();
    } catch (_) {}
    try {
      brokerageController.clear();
    } catch (_) {}
    try {
      agentLicenseNumberController.clear();
    } catch (_) {}
    try {
      bioController.clear();
    } catch (_) {}
    try {
      websiteUrlController.clear();
    } catch (_) {}
    try {
      googleReviewsUrlController.clear();
    } catch (_) {}
    try {
      thirdPartyReviewsUrlController.clear();
    } catch (_) {}
    try {
      serviceZipCodesController.clear();
    } catch (_) {}
    try {
      companyController.clear();
    } catch (_) {}
    try {
      loanOfficerLicenseNumberController.clear();
    } catch (_) {}
    try {
      loanOfficerBioController.clear();
    } catch (_) {}
    try {
      loanOfficerWebsiteUrlController.clear();
    } catch (_) {}
    try {
      mortgageApplicationUrlController.clear();
    } catch (_) {}
    try {
      loanOfficerExternalReviewsUrlController.clear();
    } catch (_) {}
    try {
      loanOfficerOfficeZipController.clear();
    } catch (_) {}
  }
}

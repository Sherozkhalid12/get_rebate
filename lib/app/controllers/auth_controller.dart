import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart'; // Added for initialization check
import 'package:getrebate/firebase_options.dart'; // Added to access DefaultFirebaseOptions
import 'dart:io';
import 'dart:convert';
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/connectivity_helper.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/controllers/current_loan_officer_controller.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';

import '../modules/messages/controllers/messages_controller.dart';

/// Custom exception for email already exists
class EmailAlreadyExistsException implements Exception {
  final String message;
  EmailAlreadyExistsException(this.message);
  @override
  String toString() => 'EmailAlreadyExistsException: $message';
}

class AuthController extends GetxController {
  final _storage = GetStorage();
  final Dio _dio = Dio();

  // API Base URL - Using ApiConstants for centralized management
  static String get _baseUrl => ApiConstants.apiBaseUrl;
  static const String _licensedStatesStorageKey = 'agent_licensed_states';

  // Observable variables
  final _isLoading = false.obs;
  final _currentUser = Rxn<UserModel>();
  final _isLoggedIn = false.obs;
  bool _isLoadingLoanOfficerProfile =
      false; // Guard to prevent multiple simultaneous loads

  // Getters
  bool get isLoading => _isLoading.value;
  UserModel? get currentUser => _currentUser.value;
  bool get isLoggedIn => _isLoggedIn.value;
  String? get token => _storage.read('auth_token');

  @override
  void onInit() {
    super.onInit();
    _setupDio();
    _checkAuthStatus();
    _validateAndFixStoredUser();
  }

  /// Validates and fixes stored user data - clears invalid IDs
  void _validateAndFixStoredUser() {
    final user = _currentUser.value;
    if (user != null) {
      // Check if ID is a generated one (starts with "user_")
      final isGeneratedId = user.id.startsWith('user_');
      // MongoDB ObjectIds are exactly 24 hex characters
      final isValidMongoId =
          user.id.length == 24 &&
          RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(user.id);

      if (isGeneratedId || (!isValidMongoId && user.id.isNotEmpty)) {
        print('⚠️ CRITICAL: Invalid user ID detected after init: ${user.id}');
        print('   Clearing invalid user data. User must log in again.');
        _clearInvalidUserData();
      }
    }
  }

  /// Clears invalid user data from storage
  void _clearInvalidUserData() {
    _storage.remove('current_user');
    _storage.remove('auth_token');
    _currentUser.value = null;
    _isLoggedIn.value = false;
  }

  List<String> _readCachedLicensedStates() {
    final stored = _storage.read(_licensedStatesStorageKey);
    if (stored is List) {
      return stored.whereType<String>().toList();
    }
    return [];
  }

  void _cacheLicensedStates(List<String> states) {
    _storage.write(_licensedStatesStorageKey, states);
  }

  UserModel _applyCachedLicensedStates(UserModel user) {
    final cached = _readCachedLicensedStates();
    if (user.licensedStates.isEmpty && cached.isNotEmpty) {
      return user.copyWith(licensedStates: cached);
    }
    if (user.licensedStates.isNotEmpty &&
        cached.join(',') != user.licensedStates.join(',')) {
      _cacheLicensedStates(user.licensedStates);
    }
    return user;
  }

  void _setupDio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };
  }

  void _checkAuthStatus() {
    final userData = _storage.read('current_user');
    final authToken = _storage.read('auth_token');

    if (userData != null) {
      var user = UserModel.fromJson(userData);
      user = _applyCachedLicensedStates(user);

      // Validate user ID - MongoDB ObjectIds are 24 hex characters
      // If it starts with "user_" it's a generated ID from old code, clear it
      // Also check if it's empty or doesn't look like a valid MongoDB ID
      final isValidMongoId =
          user.id.length == 24 &&
          RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(user.id);
      final isGeneratedId = user.id.startsWith('user_');

      if (isGeneratedId || (!isValidMongoId && user.id.isNotEmpty)) {
        print(
          '⚠️ WARNING: Detected invalid/generated user ID in storage: ${user.id}',
        );
        print(
          '   Valid MongoDB IDs are 24 hex characters. Clearing invalid user data.',
        );
        _clearInvalidUserData();
        print(
          '   Please log in again to get the correct user ID from the API.',
        );
        return;
      }

      if (user.id.isEmpty) {
        print(
          '⚠️ WARNING: User ID is empty in storage. Clearing invalid user data.',
        );
        _clearInvalidUserData();
        return;
      }

      _currentUser.value = user;
      _isLoggedIn.value = true;

      // Setup Dio with auth token if available
      if (authToken != null) {
        _dio.options.headers['Authorization'] = 'Bearer $authToken';
      }

      // Refresh FCM token on app start
      if (kDebugMode) {
        print('🔄 Refreshing FCM token on app start');
      }
      setFCM(user.id);

      print('✅ User session restored from storage');
      print('   User ID: ${_currentUser.value?.id}');
      print('   Email: ${_currentUser.value?.email}');
      print('   Role: ${_currentUser.value?.role}');

      // If this is a loan officer, eagerly load their full profile
      // Only load if not already loading to prevent infinite loops
      if (_currentUser.value?.role == UserRole.loanOfficer &&
          !_isLoadingLoanOfficerProfile) {
        _loadLoanOfficerProfile();
      }
    } else {
      print('ℹ️ No saved user session found');
      _isLoggedIn.value = false;
    }
  }

  /// Loads the loan officer profile asynchronously
  /// Prevents multiple simultaneous calls with a guard flag
  Future<void> _loadLoanOfficerProfile() async {
    // Guard: Prevent multiple simultaneous calls
    if (_isLoadingLoanOfficerProfile) {
      if (kDebugMode) {
        print(
          '⚠️ AuthController._loadLoanOfficerProfile: Already loading, skipping duplicate call.',
        );
      }
      return;
    }

    // Guard: Check if data already exists
    try {
      if (Get.isRegistered<CurrentLoanOfficerController>()) {
        final currentLoanOfficerController =
            Get.find<CurrentLoanOfficerController>();
        if (currentLoanOfficerController.currentLoanOfficer.value != null &&
            currentLoanOfficerController.currentLoanOfficer.value!.id ==
                _currentUser.value?.id) {
          if (kDebugMode) {
            print(
              '✅ AuthController._loadLoanOfficerProfile: Loan officer data already loaded, skipping.',
            );
          }
          return;
        }
      }
    } catch (e) {
      // Continue if controller not registered yet
    }

    _isLoadingLoanOfficerProfile = true;

    try {
      final loanOfficerId = _currentUser.value!.id;
      if (kDebugMode) {
        print(
          '📡 AuthController._loadLoanOfficerProfile: Detected loan officer session.',
        );
        print('   Loan officer ID to load: $loanOfficerId');
      }

      final currentLoanOfficerController =
          Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : Get.put(CurrentLoanOfficerController(), permanent: true);

      await currentLoanOfficerController.fetchCurrentLoanOfficer(loanOfficerId);

      // Only log success if we actually have loan officer data
      if (currentLoanOfficerController.currentLoanOfficer.value != null) {
        if (kDebugMode) {
          print(
            '✅ AuthController._loadLoanOfficerProfile: Current loan officer profile loaded after session restore.',
          );
        }
      } else {
        if (kDebugMode) {
          print(
            '⚠️ AuthController._loadLoanOfficerProfile: fetchCurrentLoanOfficer completed but loan officer is still null.',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ AuthController._loadLoanOfficerProfile: Failed to load current loan officer profile: $e',
        );
      }
      // Don't block the app - user can still use it, just without full profile data
    } finally {
      _isLoadingLoanOfficerProfile = false;
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? provider,
  }) async {
    try {
      await ConnectivityHelper.ensureConnectivity();
      _isLoading.value = true;

      // Prepare request body
      final requestData = {'email': email.trim(), 'password': password};

      print('🚀 Sending POST request to: $_baseUrl/auth/login');
      print('📤 Request Data:');
      print('  - email: $email');
      print('  - password: ********');

      // Make API call
      final response = await _dio.post(
        '/auth/login',
        data: requestData,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      // Handle successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ SUCCESS - Status Code: ${response.statusCode}');
        print('📥 Response Data:');
        print(response.data);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        final responseData = response.data;
        // CRITICAL: Only proceed if API indicates success - never enter app on failure
        if (responseData is Map && responseData['success'] == false) {
          final msg = responseData['message']?.toString() ?? 'Login failed. Please try again.';
          if (kDebugMode) print('❌ Login API returned success:false: $msg');
          throw Exception(msg);
        }
        final userData = responseData['user'];
        final token = responseData['token'];

        if (userData != null) {
          // Extract user ID - must use _id from API response
          final userId =
              userData['_id']?.toString() ?? userData['id']?.toString();

          if (userId == null || userId.isEmpty) {
            print('❌ CRITICAL ERROR: User ID is empty in API response!');
            print('   userData keys: ${userData.keys}');
            print('   userData: $userData');
            throw Exception(
              'User ID (_id) not found in login API response. Cannot proceed without valid user ID.',
            );
          }

          print('✅ Extracted User ID from login: $userId');
          // Map API response to UserModel
          var user = UserModel(
            id: userId,
            email: userData['email'] ?? email,
            name:
                userData['fullname'] ?? userData['name'] ?? email.split('@')[0],
            phone: userData['phone']?.toString(),
            role: _mapApiRoleToUserRole(userData['role']?.toString()),
            profileImage:
                userData['profilePic']?.toString() ??
                userData['profileImage']?.toString(),
            licensedStates: List<String>.from(
              userData['LisencedStates'] ?? userData['licensedStates'] ?? [],
            ),
            createdAt: userData['createdAt'] != null
                ? DateTime.parse(userData['createdAt'])
                : DateTime.now(),
            lastLoginAt: DateTime.now(),
            isVerified: userData['verified'] ?? false,
            additionalData: {
              // Basic fields
              'CompanyName':
                  userData['CompanyName'] ??
                  userData['brokerage'] ??
                  userData['company'],
              'liscenceNumber':
                  userData['liscenceNumber'] ?? userData['licenseNumber'],
              'dualAgencyState': userData['dualAgencyState'],
              'dualAgencySBrokerage': userData['dualAgencySBrokerage'],
              'verificationStatement':
                  userData['verificationStatement'] ??
                  userData['verificationAgreed'],
              'bio': userData['bio'],
              'description': userData['description'],
              'video': userData['video'] ?? userData['videoUrl'],
              'companyLogo': userData['companyLogo'],
              // Arrays
              'serviceAreas':
                  userData['serviceAreas'] ?? userData['serviceZipCodes'],
              'areasOfExpertise':
                  userData['areasOfExpertise'] ?? userData['expertise'],
              'specialtyProducts': userData['specialtyProducts'],
              // Links
              'website_link':
                  userData['website_link'] ?? userData['websiteUrl'],
              'google_reviews_link':
                  userData['google_reviews_link'] ??
                  userData['googleReviewsUrl'],
              'thirdPartReviewLink':
                  userData['thirdPartReviewLink'] ??
                  userData['client_reviews_link'] ??
                  userData['thirdPartyReviewsUrl'],
              'mortgageApplicationUrl': userData['mortgageApplicationUrl'],
              'externalReviewsUrl': userData['externalReviewsUrl'],
              // Stats
              'ratings': userData['ratings'],
              'reviews': userData['reviews'],
              'searches': userData['searches'],
              'views': userData['views'],
              'contacts': userData['contacts'],
            },
          );

          user = _applyCachedLicensedStates(user);

          // Store user and token
          _currentUser.value = user;
          _isLoggedIn.value = true;
          _storage.write('current_user', user.toJson());
          if (token != null) {
            _storage.write('auth_token', token);
            print('🔑 Auth token stored $token');
          }
          
          // Set FCM token
          setFCM(user.id);

          print('✅ Login successful!');
          print('   User ID (logged-in): ${user.id}');
          print('   Email: ${user.email}');
          print('   Name: ${user.name}');
          print('   Role: ${user.role}');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          SnackbarHelper.showSuccess(
            responseData['message']?.toString() ?? 'Login successful!',
            duration: const Duration(seconds: 2),
          );

          await _navigateToRoleBasedScreen();
        } else {
          throw Exception('User data not found in response');
        }
      }
    } on DioException catch (e) {
      // Handle Dio errors
      print('❌ ERROR - Status Code: ${e.response?.statusCode ?? "N/A"}');
      print('📥 Error Response:');
      print(e.response?.data ?? e.message);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      String errorMessage = 'Login failed. Please try again.';

      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        // Handle 500 server errors
        if (statusCode == 500) {
          // Check if response contains MongoDB error
          final responseString = responseData?.toString() ?? '';
          if (responseString.contains('MongooseError') ||
              responseString.contains('buffering timed out')) {
            errorMessage =
                'Server database connection error. Please try again in a moment.';
          } else {
            errorMessage = 'Server error. Please try again later.';
          }
        } else if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (statusCode == 401) {
          errorMessage = 'Invalid email or password';
        } else if (statusCode == 400) {
          errorMessage = 'Invalid request. Please check your credentials.';
        } else {
          errorMessage = e.response?.statusMessage ?? errorMessage;
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      SnackbarHelper.showError(errorMessage);
      throw Exception(errorMessage); // ALWAYS throw - caller must NOT navigate on failure
    } catch (e) {
      print('❌ Unexpected Error: ${e.toString()}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      SnackbarHelper.showError('Login failed. Please try again.');
      rethrow; // ALWAYS rethrow - caller must NOT navigate on failure
    } finally {
      _isLoading.value = false;
    }
  }

  /// Sends verification email with OTP to the given email address.
  /// Used before signup - call this first, then show OTP screen.
  /// API: POST {{server}}/api/v1/auth/sendVerificationEmail
  Future<void> sendVerificationEmail(String email) async {
    await ConnectivityHelper.ensureConnectivity();
    final trimmedEmail = email.trim();
    final url = ApiConstants.sendVerificationEmailEndpoint;
    final body = {'email': trimmedEmail};

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📧 OTP API: sendVerificationEmail');
      print('   URL: $url');
      print('   Body: $body');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    try {
      final response = await _dio.post(url, data: body);

      if (kDebugMode) {
        print('✅ sendVerificationEmail SUCCESS');
        print('   Status: ${response.statusCode}');
        print('   Response: ${response.data}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      // DO NOT check for email existence in sendVerificationEmail
      // Email existence is ONLY checked in /auth/createUser endpoint

      if (response.statusCode != 200 && response.statusCode != 201) {
        final msg = (response.data as Map?)?['message']?.toString() ??
            'Failed to send verification email';
        if (kDebugMode) print('❌ sendVerificationEmail FAILED: $msg');
        throw Exception(msg);
      }
    } on DioException catch (e) {
      // DO NOT check for email existence in sendVerificationEmail
      // Email existence is ONLY checked in /auth/createUser endpoint
      
      final msg = (e.response?.data as Map?)?['message']?.toString();
      final errMsg = msg ?? _dioErrorToMessage(e);
      if (kDebugMode) {
        print('❌ sendVerificationEmail DioException');
        print('   Status: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
        print('   Error: $errMsg');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      throw Exception(errMsg);
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ sendVerificationEmail Exception: $e');
        print('   Stack: $stack');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      rethrow;
    }
  }

  /// Verifies the OTP entered by the user.
  /// API: POST {{server}}/api/v1/auth/verifyOtp
  Future<void> verifyOtp(String email, String otp) async {
    await ConnectivityHelper.ensureConnectivity();
    final trimmedEmail = email.trim();
    final trimmedOtp = otp.trim();
    final url = ApiConstants.verifyOtpEndpoint;
    final body = {'email': trimmedEmail, 'otp': trimmedOtp};

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔐 OTP API: verifyOtp');
      print('   URL: $url');
      print('   Body: {email: ..., otp: ***}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    try {
      final response = await _dio.post(url, data: body);

      if (kDebugMode) {
        print('✅ verifyOtp SUCCESS');
        print('   Status: ${response.statusCode}');
        print('   Response: ${response.data}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        final msg = (response.data as Map?)?['message']?.toString() ??
            'Invalid or expired OTP';
        if (kDebugMode) print('❌ verifyOtp FAILED: $msg');
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message']?.toString();
      final errMsg = msg ?? _dioErrorToMessage(e);
      if (kDebugMode) {
        print('❌ verifyOtp DioException');
        print('   Status: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
        print('   Error: $errMsg');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      throw Exception(errMsg);
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ verifyOtp Exception: $e');
        print('   Stack: $stack');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      rethrow;
    }
  }

  /// Resends verification email (new OTP).
  /// API: POST {{server}}/api/v1/auth/resendVerificationEmail
  Future<void> resendVerificationEmail(String email) async {
    await ConnectivityHelper.ensureConnectivity();
    final trimmedEmail = email.trim();
    final url = ApiConstants.resendVerificationEmailEndpoint;
    final body = {'email': trimmedEmail};

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📧 OTP API: resendVerificationEmail');
      print('   URL: $url');
      print('   Body: $body');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    try {
      final response = await _dio.post(url, data: body);

      if (kDebugMode) {
        print('✅ resendVerificationEmail SUCCESS');
        print('   Status: ${response.statusCode}');
        print('   Response: ${response.data}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        final msg = (response.data as Map?)?['message']?.toString() ??
            'Failed to resend verification email';
        if (kDebugMode) print('❌ resendVerificationEmail FAILED: $msg');
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message']?.toString();
      final errMsg = msg ?? _dioErrorToMessage(e);
      if (kDebugMode) {
        print('❌ resendVerificationEmail DioException');
        print('   Status: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
        print('   Error: $errMsg');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      throw Exception(errMsg);
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ resendVerificationEmail Exception: $e');
        print('   Stack: $stack');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      rethrow;
    }
  }

  /// Sends password reset email to the given email.
  /// API: POST {{server}}/api/v1/auth/sendPasswordResetEmail
  Future<void> sendForgotPasswordOtp(String email) async {
    await ConnectivityHelper.ensureConnectivity();
    final trimmedEmail = email.trim();
    final url = ApiConstants.sendPasswordResetEmailEndpoint;
    final body = {'email': trimmedEmail};

    if (kDebugMode) {
      print('📧 sendPasswordResetEmail API: POST $url');
    }

    try {
      final response = await _dio.post(url, data: body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final msg = (response.data as Map?)?['message']?.toString() ??
            (response.data as Map?)?['error']?.toString() ??
            'Failed to send reset code';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final data = e.response?.data as Map?;
      final msg = data?['message']?.toString() ?? data?['error']?.toString();
      throw Exception(msg ?? _dioErrorToMessage(e));
    }
  }

  /// Verifies the password reset OTP.
  /// API: POST {{server}}/api/v1/auth/verifyPasswordResetOtp
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    await ConnectivityHelper.ensureConnectivity();
    final url = ApiConstants.verifyPasswordResetOtpEndpoint;
    final body = {
      'email': email.trim(),
      'otp': otp.trim(),
    };

    if (kDebugMode) {
      print('🔐 verifyPasswordResetOtp API: POST $url');
    }

    try {
      final response = await _dio.post(url, data: body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final msg = (response.data as Map?)?['message']?.toString() ??
            (response.data as Map?)?['error']?.toString() ??
            'Invalid or expired OTP';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final data = e.response?.data as Map?;
      final msg = data?['message']?.toString() ?? data?['error']?.toString();
      throw Exception(msg ?? _dioErrorToMessage(e));
    }
  }

  /// Resets password using email and new password (OTP must be verified first).
  /// API: PATCH {{server}}/api/v1/auth/resetPassword
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    await ConnectivityHelper.ensureConnectivity();
    final url = ApiConstants.resetPasswordEndpoint;
    final body = {
      'email': email.trim(),
      'newPassword': newPassword.trim(),
    };

    if (kDebugMode) {
      print('🔐 resetPassword API: PATCH $url');
    }

    try {
      final response = await _dio.patch(url, data: body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final msg = (response.data as Map?)?['message']?.toString() ??
            (response.data as Map?)?['error']?.toString() ??
            'Failed to reset password';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final data = e.response?.data as Map?;
      final msg = data?['message']?.toString() ?? data?['error']?.toString();
      throw Exception(msg ?? _dioErrorToMessage(e));
    }
  }

  String _dioErrorToMessage(DioException e) {
    if (e.response?.statusCode == 401) return 'Invalid OTP or session expired.';
    if (e.response?.statusCode == 400) return 'Invalid request.';
    if (e.response?.statusCode == 429) return 'Too many requests. Please wait before resending.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your network.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
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
    File? video,
    bool skipNavigation = false,
  }) async {
    try {
      await ConnectivityHelper.ensureConnectivity();
      _isLoading.value = true;

      // Prepare form data
      final formData = FormData();

      // Add text fields
      formData.fields.addAll([
        MapEntry('fullname', name),
        MapEntry('email', email),
        MapEntry('password', password),
        if (phone != null && phone.isNotEmpty) MapEntry('phone', phone),
        MapEntry('role', _mapRoleToApiFormat(role)),
      ]);

      // Add licensed states if provided (as JSON array string)
      if (licensedStates != null && licensedStates.isNotEmpty) {
        formData.fields.add(
          MapEntry('licensedStates', jsonEncode(licensedStates)),
        );
      }

      // Add agent-specific fields
      if (role == UserRole.agent && additionalData != null) {
        // CompanyName (brokerage)
        if (additionalData['brokerage'] != null) {
          formData.fields.add(
            MapEntry('CompanyName', additionalData['brokerage'].toString()),
          );
        }

        // liscenceNumber (note: API uses typo "liscence" instead of "license")
        if (additionalData['licenseNumber'] != null) {
          formData.fields.add(
            MapEntry(
              'liscenceNumber',
              additionalData['licenseNumber'].toString(),
            ),
          );
        }

        // Dual agency fields
        final dualAgencyState = additionalData['isDualAgencyAllowedInState'];
        final dualAgencyBrokerage =
            additionalData['isDualAgencyAllowedAtBrokerage'];

        if (dualAgencyState != null) {
          formData.fields.add(
            MapEntry('dualAgencyState', dualAgencyState.toString()),
          );
        }
        if (dualAgencyBrokerage != null) {
          formData.fields.add(
            MapEntry('dualAgencySBrokerage', dualAgencyBrokerage.toString()),
          );
        }

        // Office ZIP code (single)
        if (additionalData['zipCode'] != null) {
          formData.fields.add(
            MapEntry('zipCode', additionalData['zipCode'].toString()),
          );
        }

        // Service Areas (as JSON array string)
        if (additionalData['serviceZipCodes'] != null &&
            additionalData['serviceZipCodes'] is List) {
          final serviceAreasList = additionalData['serviceZipCodes'] as List;
          if (serviceAreasList.isNotEmpty) {
            formData.fields.add(
              MapEntry('serviceAreas', jsonEncode(serviceAreasList)),
            );
          }
        }

        // Bio
        if (additionalData['bio'] != null) {
          formData.fields.add(
            MapEntry('bio', additionalData['bio'].toString()),
          );
        }

        // Areas of Expertise (as JSON array string)
        if (additionalData['expertise'] != null &&
            additionalData['expertise'] is List) {
          final expertiseList = additionalData['expertise'] as List;
          if (expertiseList.isNotEmpty) {
            formData.fields.add(
              MapEntry(
                'areasOfExpertise',
                '${expertiseList.map((e) => '"$e"').toList()}',
              ),
            );
          }
        }

        // Website link
        if (additionalData['websiteUrl'] != null) {
          formData.fields.add(
            MapEntry('website_link', additionalData['websiteUrl'].toString()),
          );
        }

        // Google Reviews link
        if (additionalData['googleReviewsUrl'] != null) {
          formData.fields.add(
            MapEntry(
              'google_reviews_link',
              additionalData['googleReviewsUrl'].toString(),
            ),
          );
        }

        // Third Party Review Link
        if (additionalData['thirdPartyReviewsUrl'] != null) {
          formData.fields.add(
            MapEntry(
              'thirdPartReviewLink',
              additionalData['thirdPartyReviewsUrl'].toString(),
            ),
          );
        }

        // Verification Statement
        if (additionalData['verificationAgreed'] != null) {
          formData.fields.add(
            MapEntry(
              'verificationStatement',
              additionalData['verificationAgreed'].toString(),
            ),
          );
        }
      }

      // Add loan officer-specific fields
      if (role == UserRole.loanOfficer && additionalData != null) {
        // CompanyName (for loan officers, this is the company name)
        if (additionalData['company'] != null) {
          formData.fields.add(
            MapEntry('CompanyName', additionalData['company'].toString()),
          );
        }

        // liscenceNumber (note: API uses typo "liscence" instead of "license")
        if (additionalData['licenseNumber'] != null) {
          formData.fields.add(
            MapEntry(
              'liscenceNumber',
              additionalData['licenseNumber'].toString(),
            ),
          );
        }

        // Bio
        if (additionalData['bio'] != null) {
          formData.fields.add(
            MapEntry('bio', additionalData['bio'].toString()),
          );
        }

        // Service Areas (as JSON array string) - for loan officers
        if (additionalData['serviceAreas'] != null &&
            additionalData['serviceAreas'] is List) {
          final serviceAreasList = additionalData['serviceAreas'] as List;
          if (serviceAreasList.isNotEmpty) {
            formData.fields.add(
              MapEntry('serviceAreas', jsonEncode(serviceAreasList)),
            );
          }
        }


        // Specialty Products (as JSON array string)
        if (additionalData['specialtyProducts'] != null &&
            additionalData['specialtyProducts'] is List) {
          final specialtyList = additionalData['specialtyProducts'] as List;
          if (specialtyList.isNotEmpty) {
            formData.fields.add(
              MapEntry('specialtyProducts', jsonEncode(specialtyList)),
            );
          }
        }

        // Website link
        if (additionalData['websiteUrl'] != null) {
          formData.fields.add(
            MapEntry('website_link', additionalData['websiteUrl'].toString()),
          );
        }

        // Mortgage Application URL
        if (additionalData['mortgageApplicationUrl'] != null) {
          formData.fields.add(
            MapEntry(
              'mortgageApplicationUrl',
              additionalData['mortgageApplicationUrl'].toString(),
            ),
          );
        }

        // External Reviews URL (third party reviews)
        if (additionalData['externalReviewsUrl'] != null) {
          formData.fields.add(
            MapEntry(
              'thirdPartReviewLink',
              additionalData['externalReviewsUrl'].toString(),
            ),
          );
        }

        // Verification Statement
        if (additionalData['verificationAgreed'] != null) {
          formData.fields.add(
            MapEntry(
              'verificationStatement',
              additionalData['verificationAgreed'].toString(),
            ),
          );
        }

        // Office ZIP code (single)
        if (additionalData['zipCode'] != null) {
          formData.fields.add(
            MapEntry('zipCode', additionalData['zipCode'].toString()),
          );
        }
      }

      // Add profile picture file if provided
      if (profilePic != null) {
        final fileName = profilePic.path.split('/').last;
        formData.files.add(
          MapEntry(
            'profilePic',
            await MultipartFile.fromFile(profilePic.path, filename: fileName),
          ),
        );
      }

      if (companyLogo != null) {
        final fileName = companyLogo.path.split('/').last;
        formData.files.add(
          MapEntry(
            'companyLogo',
            await MultipartFile.fromFile(companyLogo.path, filename: fileName),
          ),
        );
      }

      // Add video file if provided (for agents and loan officers)
      if (video != null) {
        final fileName = video.path.split('/').last;
        formData.files.add(
          MapEntry(
            'video',
            await MultipartFile.fromFile(video.path, filename: fileName),
          ),
        );
      }

      print('🚀 Sending POST request to: $_baseUrl/auth/createUser');
      print('📤 Request Data:');
      print('  - fullname: $name');
      print('  - email: $email');
      print('  - phone: ${phone ?? "not provided"}');
      print('  - role: ${_mapRoleToApiFormat(role)}');
      if (licensedStates != null && licensedStates.isNotEmpty) {
        print('  - licensedStates: ${licensedStates.join(", ")}');
      }
      if (companyLogo != null) {
        print('  - companyLogo: ${companyLogo.path.split("/").last}');
      }
      if (role == UserRole.agent && additionalData != null) {
        if (additionalData['brokerage'] != null) {
          print('  - brokerage: ${additionalData['brokerage']}');
        }
        if (additionalData['licenseNumber'] != null) {
          print('  - licenseNumber: ${additionalData['licenseNumber']}');
        }
        if (additionalData['serviceZipCodes'] != null) {
          print('  - serviceZipCodes: ${additionalData['serviceZipCodes']}');
        }
        print(
          '  - dualAgencyState: ${additionalData['isDualAgencyAllowedInState']}',
        );
        print(
          '  - dualAgencySBrokerage: ${additionalData['isDualAgencyAllowedAtBrokerage']}',
        );
        if (additionalData['bio'] != null) {
          print('  - bio: ${additionalData['bio']}');
        }
        if (additionalData['videoUrl'] != null) {
          print('  - videoUrl: ${additionalData['videoUrl']}');
        }
        if (additionalData['expertise'] != null) {
          print('  - expertise: ${additionalData['expertise']}');
        }
        if (additionalData['websiteUrl'] != null) {
          print('  - websiteUrl: ${additionalData['websiteUrl']}');
        }
        if (additionalData['googleReviewsUrl'] != null) {
          print('  - googleReviewsUrl: ${additionalData['googleReviewsUrl']}');
        }
        if (additionalData['thirdPartyReviewsUrl'] != null) {
          print(
            '  - thirdPartyReviewsUrl: ${additionalData['thirdPartyReviewsUrl']}',
          );
        }
        if (additionalData['verificationAgreed'] != null) {
          print(
            '  - verificationAgreed: ${additionalData['verificationAgreed']}',
          );
        }
      }
      if (role == UserRole.loanOfficer && additionalData != null) {
        if (additionalData['company'] != null) {
          print('  - company: ${additionalData['company']}');
        }
        if (additionalData['licenseNumber'] != null) {
          print('  - licenseNumber: ${additionalData['licenseNumber']}');
        }
        if (additionalData['bio'] != null) {
          print('  - bio: ${additionalData['bio']}');
        }
        if (additionalData['videoUrl'] != null) {
          print('  - videoUrl: ${additionalData['videoUrl']}');
        }
        if (additionalData['specialtyProducts'] != null) {
          print(
            '  - specialtyProducts: ${additionalData['specialtyProducts']}',
          );
        }
        if (additionalData['websiteUrl'] != null) {
          print('  - websiteUrl: ${additionalData['websiteUrl']}');
        }
        if (additionalData['mortgageApplicationUrl'] != null) {
          print(
            '  - mortgageApplicationUrl: ${additionalData['mortgageApplicationUrl']}',
          );
        }
        if (additionalData['externalReviewsUrl'] != null) {
          print(
            '  - externalReviewsUrl: ${additionalData['externalReviewsUrl']}',
          );
        }
        if (additionalData['verificationAgreed'] != null) {
          print(
            '  - verificationAgreed: ${additionalData['verificationAgreed']}',
          );
        }
      }
      if (profilePic != null) {
        print('  - profilePic: ${profilePic.path.split('/').last}');
      } else {
        print('  - profilePic: not provided');
      }

      // Make API call
      final response = await _dio.post(
        '/auth/createUser',
        data: formData,
        options: Options(headers: {'ngrok-skip-browser-warning': 'true'}),
      );

      // Handle response
      final responseData = response.data;
      
      // CRITICAL: Only proceed if API indicates success - never enter app on failure
      if (responseData is Map) {
        final success = responseData['success'];
        final message = responseData['message']?.toString().trim() ?? '';
        
        if (success == false) {
          // Email already exists - special handling
          if (message.toLowerCase() == 'user with this email or phone already exists') {
            final errorMsg = message.isNotEmpty ? message : 'An account with this email already exists';
            if (kDebugMode) {
              print('❌ Email already exists detected from /auth/createUser: $errorMsg');
              print('   Response: $responseData');
            }
            throw EmailAlreadyExistsException(errorMsg);
          }
          // Any other success:false - do NOT let user enter app
          final errorMsg = message.isNotEmpty ? message : 'Sign up failed. Please try again.';
          if (kDebugMode) {
            print('❌ SignUp API returned success:false: $errorMsg');
            print('   Response: $responseData');
          }
          throw Exception(errorMsg);
        }
      }
      
      // Handle successful response (success is true or not present - legacy API)
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ SUCCESS - Status Code: ${response.statusCode}');
        print('📥 Response Data:');
        print(response.data);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Extract user data - check if nested in 'user' object or at root level
        final userData = responseData['user'] ?? responseData;

        // Extract user ID - must use _id from API response
        final userId =
            userData['_id']?.toString() ?? userData['id']?.toString();

        if (userId == null || userId.isEmpty) {
          print('❌ ERROR: User ID not found in signup API response');
          print('📥 Full Response Data:');
          print(responseData);
          throw Exception(
            'User ID (_id) not found in signup API response. Please try again.',
          );
        }

        print('✅ Extracted User ID from signup: $userId');

        // Create user model from API response - use data from API response
        final user = UserModel(
          id: userId,
          email: userData['email'] ?? email,
          name: userData['fullname'] ?? userData['name'] ?? name,
          phone: userData['phone']?.toString() ?? phone,
          role: role,
          profileImage:
              userData['profilePic']?.toString() ??
              userData['profileImage']?.toString(),
          licensedStates: userData['licensedStates'] != null
              ? List<String>.from(userData['licensedStates'])
              : (licensedStates ?? []),
          createdAt: userData['createdAt'] != null
              ? DateTime.parse(userData['createdAt'])
              : DateTime.now(),
          lastLoginAt: DateTime.now(),
          isVerified: userData['verified'] ?? userData['isVerified'] ?? false,
          additionalData: {
            // Basic fields from API response
            'CompanyName':
                userData['CompanyName'] ??
                userData['brokerage'] ??
                userData['company'] ??
                additionalData?['brokerage'] ??
                additionalData?['company'],
            'liscenceNumber':
                userData['liscenceNumber'] ??
                userData['licenseNumber'] ??
                additionalData?['licenseNumber'],
            'dualAgencyState':
                userData['dualAgencyState'] ??
                additionalData?['isDualAgencyAllowedInState'],
            'dualAgencySBrokerage':
                userData['dualAgencySBrokerage'] ??
                additionalData?['isDualAgencyAllowedAtBrokerage'],
            'verificationStatement':
                userData['verificationStatement'] ??
                userData['verificationAgreed'] ??
                additionalData?['verificationAgreed'],
            'bio': userData['bio'] ?? additionalData?['bio'],
            'description':
                userData['description'] ?? additionalData?['description'],
            'video':
                userData['video'] ??
                userData['videoUrl'] ??
                additionalData?['videoUrl'],
            'companyLogo': userData['companyLogo'],
            // Arrays from API response
            'serviceAreas':
                userData['serviceAreas'] ??
                userData['serviceZipCodes'] ??
                additionalData?['serviceZipCodes'],
            'areasOfExpertise':
                userData['areasOfExpertise'] ??
                userData['expertise'] ??
                additionalData?['expertise'],
            'specialtyProducts':
                userData['specialtyProducts'] ??
                additionalData?['specialtyProducts'],
            // Links from API response
            'website_link':
                userData['website_link'] ??
                userData['websiteUrl'] ??
                additionalData?['websiteUrl'],
            'google_reviews_link':
                userData['google_reviews_link'] ??
                userData['googleReviewsUrl'] ??
                additionalData?['googleReviewsUrl'],
            'client_reviews_link': userData['client_reviews_link'],
            'thirdPartReviewLink':
                userData['thirdPartReviewLink'] ??
                userData['thirdPartyReviewsUrl'] ??
                additionalData?['thirdPartyReviewsUrl'],
            'mortgageApplicationUrl':
                userData['mortgageApplicationUrl'] ??
                additionalData?['mortgageApplicationUrl'],
            'externalReviewsUrl':
                userData['externalReviewsUrl'] ??
                additionalData?['externalReviewsUrl'],
            // Stats
            'ratings': userData['ratings'],
            'reviews': userData['reviews'],
            'searches': userData['searches'],
            'views': userData['views'],
            'contacts': userData['contacts'],
          },
        );

        _currentUser.value = user;
        _isLoggedIn.value = true;
        _storage.write('current_user', user.toJson());

        // Set FCM token
        setFCM(user.id);

        print('✅ User created successfully!');
        print('   User ID (signed-up): ${user.id}');
        print('   Email: ${user.email}');
        print('   Name: ${user.name}');
        print('   Role: ${user.role}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        SnackbarHelper.showSuccess(
          'Account created successfully!',
          duration: const Duration(seconds: 2),
        );

        if (!skipNavigation) {
          await _navigateToRoleBasedScreen();
        }
      }
    } on DioException catch (e) {
      // Handle Dio errors
      if (kDebugMode) {
        print('❌ SIGNUP ERROR - Status Code: ${e.response?.statusCode ?? "N/A"}');
        print('📥 Error Response:');
        print(e.response?.data ?? e.message);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      String errorMessage = 'Sign up failed. Please try again.';
      bool isEmailExists = false;

      if (e.response != null) {
        final responseData = e.response?.data;
        final statusCode = e.response?.statusCode;
        
        // EXACT check: Only check for the specific API response format from /auth/createUser
        // {"success": false, "message": "User with this email or phone already exists"}
        if (responseData is Map) {
          final success = responseData['success'];
          final msg = responseData['message']?.toString().toLowerCase().trim() ?? '';
          
          // ONLY check for exact message match - no partial matches
          if (success == false && 
              msg == 'user with this email or phone already exists') {
            isEmailExists = true;
            errorMessage = responseData['message']?.toString() ?? 
                'An account with this email already exists';
            if (kDebugMode) {
              print('❌ Email already exists detected in DioException: $errorMessage');
              print('   Status Code: $statusCode');
              print('   Response: $responseData');
            }
          } else {
            // Not an email exists error - use the actual error message
            errorMessage = responseData['message']?.toString() ?? 
                e.response?.statusMessage ?? errorMessage;
          }
        } else {
          errorMessage = e.response?.statusMessage ?? errorMessage;
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      // ALWAYS throw on signUp failure - caller must NOT navigate user into app
      if (isEmailExists) {
        if (kDebugMode) {
          print('❌ Email already exists detected in signUp: $errorMessage');
        }
        throw EmailAlreadyExistsException(errorMessage);
      }
      // Throw for ALL other errors - user must NOT enter app on API failure
      throw Exception(errorMessage);
    } catch (e) {
      // Re-throw so caller knows signUp failed - do NOT swallow
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  String _mapRoleToApiFormat(UserRole role) {
    switch (role) {
      case UserRole.agent:
        return 'agent';
      case UserRole.loanOfficer:
        return 'loanofficer';
      case UserRole.buyerSeller:
        return 'buyer/seller';
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? fullname,
    String? email,
    String? phone,
    String? bio,
    String? description,
    String? companyName,
    String? websiteLink,
    String? googleReviewsLink,
    String? clientReviewsLink,
    String? thirdPartReviewLink,
    List<String>? serviceAreas,
    List<String>? areasOfExpertise,
    List<String>? licensedStates,
    bool? dualAgencyState,
    bool? dualAgencySBrokerage,
    File? profilePic,
    File? companyLogo,
    File? video,
    int? yearsOfExperience,
    List<String>? languagesSpoken,
    String? discountsOffered,
  }) async {
    try {
      _isLoading.value = true;

      // Prepare form data
      final formData = FormData();

      // Add text fields
      if (fullname != null && fullname.isNotEmpty) {
        formData.fields.add(MapEntry('fullname', fullname));
      }
      if (email != null && email.isNotEmpty) {
        formData.fields.add(MapEntry('email', email));
      }
      if (phone != null && phone.isNotEmpty) {
        formData.fields.add(MapEntry('phone', phone));
      }
      if (bio != null && bio.isNotEmpty) {
        formData.fields.add(MapEntry('bio', bio));
      }
      if (description != null && description.isNotEmpty) {
        formData.fields.add(MapEntry('description', description));
      }
      if (companyName != null && companyName.isNotEmpty) {
        formData.fields.add(MapEntry('CompanyName', companyName));
      }
      if (websiteLink != null && websiteLink.isNotEmpty) {
        formData.fields.add(MapEntry('website_link', websiteLink));
      }
      if (googleReviewsLink != null && googleReviewsLink.isNotEmpty) {
        formData.fields.add(MapEntry('google_reviews_link', googleReviewsLink));
      }
      if (clientReviewsLink != null && clientReviewsLink.isNotEmpty) {
        formData.fields.add(MapEntry('client_reviews_link', clientReviewsLink));
      }
      if (thirdPartReviewLink != null && thirdPartReviewLink.isNotEmpty) {
        formData.fields.add(
          MapEntry('thirdPartReviewLink', thirdPartReviewLink),
        );
      }

      // Add arrays as JSON
      if (serviceAreas != null && serviceAreas.isNotEmpty) {
        formData.fields.add(MapEntry('serviceAreas', jsonEncode(serviceAreas)));
      }
      if (areasOfExpertise != null && areasOfExpertise.isNotEmpty) {
        formData.fields.add(
          MapEntry('areasOfExpertise', jsonEncode(areasOfExpertise)),
        );
      }
      if (licensedStates != null && licensedStates.isNotEmpty) {
        formData.fields.add(
          MapEntry('licensedStates', jsonEncode(licensedStates)),
        );
      }
      if (yearsOfExperience != null) {
        formData.fields.add(
          MapEntry('yearsOfExperience', yearsOfExperience.toString()),
        );
      }
      if (languagesSpoken != null && languagesSpoken.isNotEmpty) {
        formData.fields.add(
          MapEntry('languagesSpoken', jsonEncode(languagesSpoken)),
        );
      }
      if (discountsOffered != null && discountsOffered.isNotEmpty) {
        formData.fields.add(MapEntry('discountsOffered', discountsOffered));
      }

      // Add boolean fields
      if (dualAgencyState != null) {
        formData.fields.add(
          MapEntry('dualAgencyState', dualAgencyState.toString()),
        );
      }
      if (dualAgencySBrokerage != null) {
        formData.fields.add(
          MapEntry('dualAgencySBrokerage', dualAgencySBrokerage.toString()),
        );
      }

      // Add file uploads
      if (profilePic != null) {
        final fileName = profilePic.path.split('/').last;
        formData.files.add(
          MapEntry(
            'profilePic',
            await MultipartFile.fromFile(profilePic.path, filename: fileName),
          ),
        );
      }

      if (companyLogo != null) {
        final fileName = companyLogo.path.split('/').last;
        formData.files.add(
          MapEntry(
            'companyLogo',
            await MultipartFile.fromFile(companyLogo.path, filename: fileName),
          ),
        );
      }

      if (video != null) {
        final fileName = video.path.split('/').last;
        formData.files.add(
          MapEntry(
            'video',
            await MultipartFile.fromFile(video.path, filename: fileName),
          ),
        );
      }

      // Validate userId
      if (userId.isEmpty || userId.startsWith('user_')) {
        throw Exception(
          'Invalid user ID. Please login again to get a valid user ID.',
        );
      }

      // Make API call
      print('🚀 Sending PATCH request to: $_baseUrl/auth/updateUser/$userId');
      print('📤 Request Data:');
      print('  - userId: $userId');
      if (fullname != null) print('  - fullname: $fullname');
      if (email != null) print('  - email: $email');
      if (phone != null) print('  - phone: $phone');
      if (bio != null) print('  - bio: $bio');
      if (companyName != null) print('  - CompanyName: $companyName');

      final response = await _dio.patch(
        '/auth/updateUser/$userId',
        data: formData,
        options: Options(headers: {'ngrok-skip-browser-warning': 'true'}),
      );

      // Handle successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ SUCCESS - Status Code: ${response.statusCode}');
        print('📥 Response Data:');
        print(response.data);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        final responseData = response.data;
        final userData = responseData['user'] ?? responseData;

        // Update current user with response data
        if (_currentUser.value != null) {
          // Update user ID if API returns a new one (should use _id from response)
          final updatedUserId =
              userData['_id']?.toString() ??
              userData['id']?.toString() ??
              _currentUser.value!.id;

          final updatedUser = _currentUser.value!.copyWith(
            id: updatedUserId, // Ensure we use the correct ID from API
            name: userData['fullname'] ?? _currentUser.value!.name,
            email: userData['email'] ?? _currentUser.value!.email,
            phone: userData['phone']?.toString() ?? _currentUser.value!.phone,
            profileImage:
                userData['profilePic'] ??
                userData['profileImage'] ??
                _currentUser.value!.profileImage,
            licensedStates: userData['licensedStates'] != null
                ? List<String>.from(userData['licensedStates'])
                : _currentUser.value!.licensedStates,
            additionalData: {
              ...?_currentUser.value!.additionalData,
              'CompanyName': userData['CompanyName'] ?? companyName,
              'bio': userData['bio'] ?? bio,
              'description': userData['description'] ?? description,
              'website_link': userData['website_link'] ?? websiteLink,
              'google_reviews_link':
                  userData['google_reviews_link'] ?? googleReviewsLink,
              'client_reviews_link':
                  userData['client_reviews_link'] ?? clientReviewsLink,
              'thirdPartReviewLink':
                  userData['thirdPartReviewLink'] ?? thirdPartReviewLink,
              'serviceAreas': userData['serviceAreas'] ?? serviceAreas,
              'areasOfExpertise':
                  userData['areasOfExpertise'] ?? areasOfExpertise,
              'dualAgencyState': userData['dualAgencyState'] ?? dualAgencyState,
              'dualAgencySBrokerage':
                  userData['dualAgencySBrokerage'] ?? dualAgencySBrokerage,
              'companyLogo': userData['companyLogo'],
              'video': userData['video'] ?? userData['videoUrl'],
              'yearsOfExperience':
                  userData['yearsOfExperience'] ?? yearsOfExperience,
              'languagesSpoken': userData['languagesSpoken'] ?? languagesSpoken,
              'discountsOffered':
                  userData['discountsOffered'] ?? discountsOffered,
            },
          );

          _currentUser.value = updatedUser;
          _cacheLicensedStates(updatedUser.licensedStates);
          _storage.write('current_user', updatedUser.toJson());

          print('✅ User updated successfully!');
          print('   User ID: ${updatedUser.id}');
          print('   Name: ${updatedUser.name}');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }

        // Show success message after updating user data
        SnackbarHelper.showSuccess(
          'Profile updated successfully!',
          duration: const Duration(seconds: 2),
        );
      } else {
        // If status code is not 200/201, still show success if we got a response
        SnackbarHelper.showSuccess(
          'Profile updated successfully!',
          duration: const Duration(seconds: 2),
        );
      }
    } on DioException catch (e) {
      // Handle Dio errors
      print('❌ ERROR - Status Code: ${e.response?.statusCode ?? "N/A"}');
      print('📥 Error Response:');
      print(e.response?.data ?? e.message);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      String errorMessage = 'Failed to update profile. Please try again.';

      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else {
          errorMessage = e.response?.statusMessage ?? errorMessage;
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      SnackbarHelper.showError(errorMessage);
      rethrow;
    } catch (e) {
      print('❌ Unexpected Error: ${e.toString()}');
      SnackbarHelper.showError('Failed to update profile: ${e.toString()}');
      rethrow;
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

      // TODO: Implement actual social login API call
      // For now, throw error - we MUST get user ID from backend
      throw Exception(
        'Social login not implemented. Must call backend API to get user ID.',
      );

      // When implemented, the API should return user data with _id:
      // final response = await _dio.post('/auth/social-login', data: {...});
      // final responseData = response.data;
      // final userId = responseData['user']['_id']?.toString() ??
      //                responseData['user']['id']?.toString() ?? '';
      // if (userId.isEmpty) {
      //   throw Exception('User ID not found in social login response');
      // }
      // final user = UserModel(id: userId, ...);
    } catch (e) {
      print('❌ Social login error: $e');
      SnackbarHelper.showError('Social login failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  void logout() async {
    // Remove FCM token before clearing user data
    if (_currentUser.value != null) {
      await removeFCM(_currentUser.value!.id);
    }

    _currentUser.value = null;
    _isLoggedIn.value = false;
    _storage.remove('current_user');
    _storage.remove('auth_token');

    // Clear all controller data BEFORE navigation
    // This ensures clean state without force-deleting controllers
    try {
      // Clear MessagesController data - removes all chat data and socket connections
      if (Get.isRegistered<MessagesController>()) {
        final messagesController = Get.find<MessagesController>();
        messagesController.clearAllData();
        print('✅ Cleared MessagesController data');
      }

      // Clear loan officer profile so next login fetches fresh and logout is correct for loan officers
      if (Get.isRegistered<CurrentLoanOfficerController>()) {
        final loController = Get.find<CurrentLoanOfficerController>();
        loController.currentLoanOfficer.value = null;
        loController.currentLoanOfficer.refresh();
        print('✅ Cleared CurrentLoanOfficerController data');
      }
    } catch (e) {
      print('⚠️ Error clearing controller data: $e');
    }

    print('🔓 User logged out - cleared user data and token');

    // Navigate to auth screen - this will automatically dispose route-bound controllers
    Get.offAllNamed(AppPages.AUTH);
  }

  void updateUser(UserModel user) {
    _currentUser.value = user;
    _storage.write('current_user', user.toJson());
    // Set FCM token
    setFCM(user.id);
  }

  Future<void> _navigateToRoleBasedScreen() async {
    final role = _currentUser.value?.role;
    final userId = _currentUser.value?.id;

    print('🔀 AuthController._navigateToRoleBasedScreen called.');
    print('   Role: $role');
    print('   User ID: $userId');

    // If loan officer, fetch profile first. If it fails, redirect to sign in so user can sign in again.
    if (role == UserRole.loanOfficer && userId != null && userId.isNotEmpty) {
      final currentLoanOfficerController =
          Get.isRegistered<CurrentLoanOfficerController>()
              ? Get.find<CurrentLoanOfficerController>()
              : Get.put(CurrentLoanOfficerController(), permanent: true);
      await currentLoanOfficerController.fetchCurrentLoanOfficer(userId);
      if (currentLoanOfficerController.currentLoanOfficer.value == null) {
        print('❌ AuthController: Loan officer profile failed to load, redirecting to sign in.');
        SnackbarHelper.showError(
          'Could not load your profile. Please sign in again.',
          duration: const Duration(seconds: 4),
        );
        logout();
        return;
      }
      print('✅ AuthController: Loan officer profile loaded, navigating to LOAN_OFFICER.');
    }

    switch (role) {
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

  UserRole _mapApiRoleToUserRole(String? apiRole) {
    if (apiRole == null) return UserRole.buyerSeller;

    switch (apiRole.toLowerCase()) {
      case 'agent':
        return UserRole.agent;
      case 'loanofficer':
      case 'loan_officer':
        return UserRole.loanOfficer;
      case 'buyer/seller':
      case 'buyerseller':
      case 'buyer_seller':
        return UserRole.buyerSeller;
      default:
        return UserRole.buyerSeller;
    }
  }

  Future<void> setFCM(String userId) async {
    if (kDebugMode) {
      print('🔥 setFCM called for user: $userId');
    }
    // Wait for Firebase to be initialized if it hasn't been yet
    try {
      if (Firebase.apps.isEmpty) {
        if (kDebugMode) {
          print('⏳ Firebase not initialized yet, waiting...');
        }
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        if (kDebugMode) {
          print('✅ Firebase initialized inside AuthController');
        }
      } else {
        if (kDebugMode) {
          print('✅ Firebase was already initialized');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to auto-initialize Firebase in setFCM: $e');
      }
      return; // Exit if init failed
    }

    try {
      // Check if Firebase is initialized and Messaging is available
      if (kDebugMode) {
        print('📡 Getting FirebaseMessaging instance...');
      }
      final messaging = FirebaseMessaging.instance;
      
      // Request notification permissions
      if (kDebugMode) {
        print('🔔 Requesting notification permissions...');
      }
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('🔔 User granted permission: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('⚠️ Notification permissions denied by user');
        // We can still try to get the token, but notifications won't show
      }
      
      if (kDebugMode) {
        print('📡 Requesting FCM token...');
      }
      
      String? token;
      try {
        token = await messaging.getToken();
        if (kDebugMode) {
          print('🔑 FCM Token retrieved: ${token?.substring(0, 10)}...');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error getting FCM token: $e');
        }
        return;
      }

      if (token == null) {
        print('⚠️ FCM Token is null');
        return;
      }

      final authToken = _storage.read('auth_token');
      if (kDebugMode) {
        print('🚀 Sending FCM token to backend...');
      }
      
      final response = await _dio.patch(
        ApiConstants.setFCMEndpoint,
        data: {
          'userId': userId,
          'fcmToken': token,
        },
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );
      if (kDebugMode) {
        print('✅ FCM Token set: ${response.statusCode}');
        print('   Response: ${response.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting FCM Token: $e');
      }
    }
  }

  Future<void> removeFCM(String userId) async {
    try {
      final url = ApiConstants.removeFCMEndpoint(userId);
      final authToken = _storage.read('auth_token');
      
      if (kDebugMode) {
        print('📡 Removing FCM Token for user: $userId');
        print('   URL: $url');
      }
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );
      if (kDebugMode) {
        print('✅ FCM Token removed: ${response.statusCode}');
        print('   Response: ${response.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing FCM Token: $e');
      }
    }
  }
}

import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/routes/app_pages.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();
  final Dio _dio = Dio();

  // API Base URL
  static const String _baseUrl = 'https://de9f1f9bbb2a.ngrok-free.app/api/v1';

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
      final isValidMongoId = user.id.length == 24 && 
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
      final user = UserModel.fromJson(userData);
      
      // Validate user ID - MongoDB ObjectIds are 24 hex characters
      // If it starts with "user_" it's a generated ID from old code, clear it
      // Also check if it's empty or doesn't look like a valid MongoDB ID
      final isValidMongoId = user.id.length == 24 && 
                            RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(user.id);
      final isGeneratedId = user.id.startsWith('user_');
      
      if (isGeneratedId || (!isValidMongoId && user.id.isNotEmpty)) {
        print('⚠️ WARNING: Detected invalid/generated user ID in storage: ${user.id}');
        print('   Valid MongoDB IDs are 24 hex characters. Clearing invalid user data.');
        _clearInvalidUserData();
        print('   Please log in again to get the correct user ID from the API.');
        return;
      }
      
      if (user.id.isEmpty) {
        print('⚠️ WARNING: User ID is empty in storage. Clearing invalid user data.');
        _clearInvalidUserData();
        return;
      }
      
      _currentUser.value = user;
      _isLoggedIn.value = true;

      // Setup Dio with auth token if available
      if (authToken != null) {
        _dio.options.headers['Authorization'] = 'Bearer $authToken';
      }

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
        final userData = responseData['user'];
        final token = responseData['token'];

        if (userData != null) {
          // Extract user ID - API returns _id, ensure we get it correctly
          final userId = userData['_id']?.toString() ?? 
                        userData['id']?.toString() ?? 
                        '';
          
          if (userId.isEmpty) {
            print('❌ CRITICAL ERROR: User ID is empty in API response!');
            print('   userData keys: ${userData.keys}');
            print('   userData: $userData');
            throw Exception('User ID not found in login API response. Cannot proceed without valid user ID.');
          }
          
          print('✅ Extracted User ID from API: $userId');
          
          // Map API response to UserModel
          final user = UserModel(
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
              'dualAgencyState': userData['dualAgencyState'],
              'dualAgencySBrokerage': userData['dualAgencySBrokerage'],
              'liscenceNumber': userData['liscenceNumber'],
              'ratings': userData['ratings'],
              'reviews': userData['reviews'],
              'bio': userData['bio'],
              'description': userData['description'],
              'serviceAreas': userData['serviceAreas'],
              'searches': userData['searches'],
              'views': userData['views'],
              'contacts': userData['contacts'],
            },
          );

          // Store user and token
          _currentUser.value = user;
          _isLoggedIn.value = true;
          _storage.write('current_user', user.toJson());
          if (token != null) {
            _storage.write('auth_token', token);
            print('🔑 Auth token stored');
          }

          print('✅ Login successful!');
          print('   User ID: ${user.id}');
          print('   Email: ${user.email}');
          print('   Name: ${user.name}');
          print('   Role: ${user.role}');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          Get.snackbar(
            'Success',
            responseData['message']?.toString() ?? 'Login successful!',
            backgroundColor: Get.theme.colorScheme.primary,
            colorText: Get.theme.colorScheme.onPrimary,
          );

          _navigateToRoleBasedScreen();
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
            errorMessage = 'Server database connection error. Please try again in a moment.';
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

      // Safely show snackbar - wrap in try-catch to prevent overlay errors
      try {
        Get.snackbar('Error', errorMessage);
      } catch (overlayError) {
        print('⚠️ Could not show snackbar: $overlayError');
      }
    } catch (e) {
      print('❌ Unexpected Error: ${e.toString()}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // Safely show snackbar - wrap in try-catch to prevent overlay errors
      try {
        Get.snackbar('Error', 'Login failed: ${e.toString()}');
      } catch (overlayError) {
        print('⚠️ Could not show snackbar: $overlayError');
      }
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

      // Add licensed states if provided
      if (licensedStates != null && licensedStates.isNotEmpty) {
        formData.fields.add(
          MapEntry('licensedStates', licensedStates.join(',')),
        );
      }

      // Add agent-specific fields
      if (role == UserRole.agent && additionalData != null) {
        // Required fields
        if (additionalData['brokerage'] != null) {
          formData.fields.add(
            MapEntry('brokerage', additionalData['brokerage'].toString()),
          );
        }
        if (additionalData['licenseNumber'] != null) {
          formData.fields.add(
            MapEntry('licenseNumber', additionalData['licenseNumber'].toString()),
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

        // Service ZIP codes
        if (additionalData['serviceZipCodes'] != null &&
            additionalData['serviceZipCodes'] is List) {
          final zipCodesList = additionalData['serviceZipCodes'] as List;
          if (zipCodesList.isNotEmpty) {
            formData.fields.add(
              MapEntry('serviceZipCodes', zipCodesList.join(',')),
            );
          }
        }

        // Bio
        if (additionalData['bio'] != null) {
          formData.fields.add(
            MapEntry('bio', additionalData['bio'].toString()),
          );
        }

        // Video URL
        if (additionalData['videoUrl'] != null) {
          formData.fields.add(
            MapEntry('videoUrl', additionalData['videoUrl'].toString()),
          );
        }

        // Expertise (as JSON array)
        if (additionalData['expertise'] != null &&
            additionalData['expertise'] is List) {
          final expertiseList = additionalData['expertise'] as List;
          if (expertiseList.isNotEmpty) {
            formData.fields.add(
              MapEntry('expertise', expertiseList.join(',')),
            );
          }
        }

        // Website URL
        if (additionalData['websiteUrl'] != null) {
          formData.fields.add(
            MapEntry('websiteUrl', additionalData['websiteUrl'].toString()),
          );
        }

        // Google Reviews URL
        if (additionalData['googleReviewsUrl'] != null) {
          formData.fields.add(
            MapEntry('googleReviewsUrl', additionalData['googleReviewsUrl'].toString()),
          );
        }

        // Third Party Reviews URL
        if (additionalData['thirdPartyReviewsUrl'] != null) {
          formData.fields.add(
            MapEntry('thirdPartyReviewsUrl', additionalData['thirdPartyReviewsUrl'].toString()),
          );
        }

        // Verification Agreement
        if (additionalData['verificationAgreed'] != null) {
          formData.fields.add(
            MapEntry('verificationAgreed', additionalData['verificationAgreed'].toString()),
          );
        }
      }

      // Add loan officer-specific fields
      if (role == UserRole.loanOfficer && additionalData != null) {
        // Required fields
        if (additionalData['company'] != null) {
          formData.fields.add(
            MapEntry('company', additionalData['company'].toString()),
          );
        }
        if (additionalData['licenseNumber'] != null) {
          formData.fields.add(
            MapEntry('licenseNumber', additionalData['licenseNumber'].toString()),
          );
        }

        // Bio
        if (additionalData['bio'] != null) {
          formData.fields.add(
            MapEntry('bio', additionalData['bio'].toString()),
          );
        }

        // Video URL
        if (additionalData['videoUrl'] != null) {
          formData.fields.add(
            MapEntry('videoUrl', additionalData['videoUrl'].toString()),
          );
        }

        // Specialty Products (as comma-separated string)
        if (additionalData['specialtyProducts'] != null &&
            additionalData['specialtyProducts'] is List) {
          final specialtyList = additionalData['specialtyProducts'] as List;
          if (specialtyList.isNotEmpty) {
            formData.fields.add(
              MapEntry('specialtyProducts', specialtyList.join(',')),
            );
          }
        }

        // Website URL
        if (additionalData['websiteUrl'] != null) {
          formData.fields.add(
            MapEntry('websiteUrl', additionalData['websiteUrl'].toString()),
          );
        }

        // Mortgage Application URL
        if (additionalData['mortgageApplicationUrl'] != null) {
          formData.fields.add(
            MapEntry('mortgageApplicationUrl', additionalData['mortgageApplicationUrl'].toString()),
          );
        }

        // External Reviews URL
        if (additionalData['externalReviewsUrl'] != null) {
          formData.fields.add(
            MapEntry('externalReviewsUrl', additionalData['externalReviewsUrl'].toString()),
          );
        }

        // Verification Agreement
        if (additionalData['verificationAgreed'] != null) {
          formData.fields.add(
            MapEntry('verificationAgreed', additionalData['verificationAgreed'].toString()),
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

      // Make API call
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
          print('  - thirdPartyReviewsUrl: ${additionalData['thirdPartyReviewsUrl']}');
        }
        if (additionalData['verificationAgreed'] != null) {
          print('  - verificationAgreed: ${additionalData['verificationAgreed']}');
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
          print('  - specialtyProducts: ${additionalData['specialtyProducts']}');
        }
        if (additionalData['websiteUrl'] != null) {
          print('  - websiteUrl: ${additionalData['websiteUrl']}');
        }
        if (additionalData['mortgageApplicationUrl'] != null) {
          print('  - mortgageApplicationUrl: ${additionalData['mortgageApplicationUrl']}');
        }
        if (additionalData['externalReviewsUrl'] != null) {
          print('  - externalReviewsUrl: ${additionalData['externalReviewsUrl']}');
        }
        if (additionalData['verificationAgreed'] != null) {
          print('  - verificationAgreed: ${additionalData['verificationAgreed']}');
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

      // Handle successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ SUCCESS - Status Code: ${response.statusCode}');
        print('📥 Response Data:');
        print(response.data);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        final responseData = response.data;

        // Extract user ID from API response - MUST come from backend
        final userId = responseData['_id']?.toString() ?? 
                      responseData['id']?.toString() ?? 
                      '';
        
        if (userId.isEmpty) {
          throw Exception('User ID not found in API response. Cannot proceed without valid user ID.');
        }
        
        print('✅ Extracted User ID from signup API: $userId');

        // Create user model from API response
        final user = UserModel(
          id: userId,
          email: email,
          name: name,
          phone: phone,
          role: role,
          profileImage:
              responseData['profilePic'] ?? responseData['profileImage'],
          licensedStates: licensedStates ?? [],
          createdAt: responseData['createdAt'] != null
              ? DateTime.parse(responseData['createdAt'])
              : DateTime.now(),
          lastLoginAt: DateTime.now(),
          isVerified: responseData['isVerified'] ?? false,
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
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        Get.snackbar(
          'Success',
          'Account created successfully!',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        _navigateToRoleBasedScreen();
      }
    } on DioException catch (e) {
      // Handle Dio errors
      print('❌ ERROR - Status Code: ${e.response?.statusCode ?? "N/A"}');
      print('📥 Error Response:');
      print(e.response?.data ?? e.message);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      String errorMessage = 'Sign up failed. Please try again.';

      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'User with this email or phone already exists';
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

      Get.snackbar('Error', errorMessage);
    } catch (e) {
      Get.snackbar('Error', 'Sign up failed: ${e.toString()}');
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
        'Social login not implemented. Must call backend API to get user ID.'
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
      Get.snackbar('Error', 'Social login failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  void logout() {
    _currentUser.value = null;
    _isLoggedIn.value = false;
    _storage.remove('current_user');
    _storage.remove('auth_token');
    print('🔓 User logged out - cleared user data and token');
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
}

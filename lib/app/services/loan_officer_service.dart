import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';

/// Custom exception for loan officer service errors
class LoanOfficerServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  LoanOfficerServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Service for handling loan officer-related API calls
class LoanOfficerService {
  late final Dio _dio;

  LoanOfficerService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for error handling and auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Automatically add auth token to all requests
          try {
            if (Get.isRegistered<AuthController>()) {
              final authController = Get.find<AuthController>();
              final token = authController.token;
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
                if (kDebugMode) {
                  print('🔑 LoanOfficerService: Added auth token to request');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ LoanOfficerService: Could not add auth token: $e');
            }
          }

          // Add ngrok headers if needed
          options.headers.addAll(ApiConstants.ngrokHeaders);

          handler.next(options);
        },
        onError: (error, handler) {
          _handleError(error);
          handler.next(error);
        },
      ),
    );
  }

  /// Handles Dio errors
  void _handleError(DioException error) {
    if (kDebugMode) {
      print('❌ Loan Officer Service Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Request URL: ${error.requestOptions.uri}');
      print('   Request Headers: ${error.requestOptions.headers}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
      print('   Error: ${error.error}');
      print('   Stack Trace: ${error.stackTrace}');
    }
  }

  /// Fetches all loan officers from the API
  ///
  /// Throws [LoanOfficerServiceException] if the request fails
  Future<List<LoanOfficerModel>> getAllLoanOfficers() async {
    try {
      final response = await _dio.get(
        ApiConstants.allLoanOfficersEndpoint,
      );

      if (kDebugMode) {
        print('✅ Loan officers response received');
        print('   Status Code: ${response.statusCode}');
      }

      // Handle different response formats
      List<dynamic> loanOfficersData;

      if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        // Check for the format with 'success' and 'loanOfficers'
        if (responseMap['success'] == true && responseMap['loanOfficers'] != null) {
          loanOfficersData = responseMap['loanOfficers'] as List<dynamic>;
        } else if (responseMap['data'] != null) {
          loanOfficersData = responseMap['data'] as List<dynamic>;
        } else if (responseMap['loanOfficers'] != null) {
          loanOfficersData = responseMap['loanOfficers'] as List<dynamic>;
        } else {
          loanOfficersData = [];
        }
      } else if (response.data is List) {
        loanOfficersData = response.data as List<dynamic>;
      } else {
        loanOfficersData = [];
      }

      final loanOfficers = <LoanOfficerModel>[];

      for (int i = 0; i < loanOfficersData.length; i++) {
        try {
          final json = loanOfficersData[i];

          // Skip if not a Map
          if (json is! Map<String, dynamic>) {
            if (kDebugMode) {
              print('⚠️ Skipping loan officer at index $i: expected Map but got ${json.runtimeType}');
            }
            continue;
          }

          final loanOfficer = LoanOfficerModel.fromJson(json);
          loanOfficers.add(loanOfficer);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error parsing loan officer at index $i: $e');
            print('   Data: ${loanOfficersData[i]}');
          }
          // Continue to next loan officer instead of failing completely
        }
      }

      if (kDebugMode) {
        print('✅ Successfully parsed ${loanOfficers.length} loan officers');
      }

      return loanOfficers;
    } on DioException catch (e) {
      String errorMessage;
      int? statusCode;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          statusCode = 408;
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Cannot connect to server. Please ensure the server is running.';
          break;
        case DioExceptionType.badResponse:
          statusCode = e.response?.statusCode;
          if (statusCode == 404) {
            errorMessage = 'Loan officers endpoint not found.';
          } else if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please login again.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            errorMessage = e.response?.data?['message']?.toString() ??
                e.response?.data?['error']?.toString() ??
                'Failed to fetch loan officers.';
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request was cancelled.';
          break;
        case DioExceptionType.unknown:
          errorMessage = 'Network error. Please try again.';
          break;
        default:
          errorMessage = 'An unexpected error occurred.';
      }

      throw LoanOfficerServiceException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is LoanOfficerServiceException) {
        rethrow;
      }

      throw LoanOfficerServiceException(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Fetches the currently authenticated loan officer by ID
  ///
  /// Calls `/api/v1/loan-officers/{id}` and returns a single [LoanOfficerModel]
  /// from the `loanOfficer` field in the response.
  ///
  /// Throws [LoanOfficerServiceException] if the request fails.
  Future<LoanOfficerModel> getCurrentLoanOfficer(String loanOfficerId) async {
    try {
      final endpoint = ApiConstants.getLoanOfficerByIdEndpoint(loanOfficerId);

      if (kDebugMode) {
        print('📡 Fetching current loan officer from API...');
        print('   ID: $loanOfficerId');
        print('   Endpoint: $endpoint');
        print('   Base URL: ${_dio.options.baseUrl}');

        // Check if auth token is available
        try {
          if (Get.isRegistered<AuthController>()) {
            final authController = Get.find<AuthController>();
            final token = authController.token;
            if (token != null && token.isNotEmpty) {
              print('   Auth Token: Present (${token.substring(0, 10)}...)');
            } else {
              print('   ⚠️ Auth Token: Missing or empty');
            }
          } else {
            print('   ⚠️ AuthController: Not registered');
          }
        } catch (e) {
          print('   ⚠️ Could not check auth token: $e');
        }
      }

      final response = await _dio.get(endpoint);

      if (kDebugMode) {
        print('✅ Current loan officer response received');
        print('   Status Code: ${response.statusCode}');
        print('   Raw Response: ${response.data}');
      }

      if (response.data is! Map<String, dynamic>) {
        throw LoanOfficerServiceException(
          message: 'Unexpected response format when fetching current loan officer.',
          statusCode: response.statusCode,
          originalError: response.data,
        );
      }

      final Map<String, dynamic> responseMap =
      response.data as Map<String, dynamic>;

      // Expecting: { success: true, loanOfficer: { ... } }
      final dynamic loanOfficerJson = responseMap['loanOfficer'] ?? responseMap['data'];

      if (loanOfficerJson == null || loanOfficerJson is! Map<String, dynamic>) {
        throw LoanOfficerServiceException(
          message: 'Loan officer data not found in response.',
          statusCode: response.statusCode,
          originalError: response.data,
        );
      }

      try {
        final loanOfficer =
        LoanOfficerModel.fromJson(loanOfficerJson as Map<String, dynamic>);

        // Build full URLs for profile picture and company logo
        final loanOfficerWithUrls = _buildImageUrls(loanOfficer);

        if (kDebugMode) {
          print('✅ Successfully parsed current loan officer: ${loanOfficerWithUrls.id}');
          print('   Profile Image URL: ${loanOfficerWithUrls.profileImage ?? "Not set"}');
          print('   Company Logo URL: ${loanOfficerWithUrls.companyLogoUrl ?? "Not set"}');
        }

        return loanOfficerWithUrls;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error parsing current loan officer: $e');
          print('   Data: $loanOfficerJson');
        }

        throw LoanOfficerServiceException(
          message: 'Failed to parse current loan officer data.',
          statusCode: response.statusCode,
          originalError: e,
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      int? statusCode;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage =
          'Connection timeout. Please check your internet connection.';
          statusCode = 408;
          break;
        case DioExceptionType.connectionError:
          errorMessage =
          'Cannot connect to server. Please ensure the server is running.';
          break;
        case DioExceptionType.badResponse:
          statusCode = e.response?.statusCode;
          if (statusCode == 404) {
            errorMessage = 'Loan officer not found.';
          } else if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please login again.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            final data = e.response?.data;
            if (data is Map<String, dynamic>) {
              errorMessage = data['message']?.toString() ??
                  data['error']?.toString() ??
                  'Failed to fetch current loan officer.';
            } else {
              errorMessage = 'Failed to fetch current loan officer.';
            }
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request was cancelled.';
          break;
        case DioExceptionType.unknown:
          errorMessage = 'Network error. Please try again.';
          break;
        default:
          errorMessage = 'An unexpected error occurred.';
      }

      throw LoanOfficerServiceException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is LoanOfficerServiceException) {
        rethrow;
      }

      throw LoanOfficerServiceException(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Builds full URLs for profile images
  LoanOfficerModel _buildImageUrls(LoanOfficerModel loanOfficer) {
    String? profileImage = loanOfficer.profileImage;
    if (profileImage != null && profileImage.isNotEmpty) {
      if (!profileImage.startsWith('http://') && !profileImage.startsWith('https://')) {
        // Build full URL with base URL
        final baseUrl = ApiConstants.baseUrl;
        profileImage = profileImage.startsWith('/')
            ? '$baseUrl$profileImage'
            : '$baseUrl/$profileImage';
      }
    }

    String? companyLogoUrl = loanOfficer.companyLogoUrl;
    if (companyLogoUrl != null && companyLogoUrl.isNotEmpty) {
      if (!companyLogoUrl.startsWith('http://') && !companyLogoUrl.startsWith('https://')) {
        // Build full URL with base URL
        final baseUrl = ApiConstants.baseUrl;
        companyLogoUrl = companyLogoUrl.startsWith('/')
            ? '$baseUrl$companyLogoUrl'
            : '$baseUrl/$companyLogoUrl';
      }
    }

    return loanOfficer.copyWith(
      profileImage: profileImage,
      companyLogoUrl: companyLogoUrl,
    );
  }

  // Cache to prevent duplicate API calls within a short time window
  final Map<String, DateTime> _searchCallCache = {};
  final Map<String, DateTime> _profileViewCallCache = {};
  final Map<String, DateTime> _contactCallCache = {};
  static const Duration _cacheDuration = Duration(minutes: 5); // Cache for 5 minutes

  // Track 404 errors to reduce logging noise
  static bool _hasLogged404ForSearch = false;
  static bool _hasLogged404ForProfileView = false;
  static bool _hasLogged404ForContact = false;

  /// Records a search appearance for a loan officer
  /// Returns the response data
  Future<Map<String, dynamic>?> recordSearch(String loanOfficerId, {String? loanOfficerName}) async {
    if (loanOfficerId.isEmpty) {
      return null;
    }

    // Get loan officer name - use provided name or fetch by ID
    String? name = loanOfficerName?.trim();
    if (kDebugMode) {
      print('📊 LoanOfficerService.recordSearch called with:');
      print('   Loan Officer ID: $loanOfficerId');
      print('   Loan Officer Name provided: ${loanOfficerName ?? "null"}');
    }

    if (name == null || name.isEmpty) {
      if (kDebugMode) {
        print('📊 Loan officer name not provided, fetching by ID: $loanOfficerId');
      }
      try {
        // Try to get loan officer by ID to get the name
        final loanOfficer = await getCurrentLoanOfficer(loanOfficerId);
        name = loanOfficer.name.trim();
        if (kDebugMode) {
          if (name.isNotEmpty) {
            print('✅ Fetched loan officer name: "$name" for ID: $loanOfficerId');
          } else {
            print('⚠️ Loan officer found but name is empty for ID: $loanOfficerId');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Could not fetch loan officer name for ID: $loanOfficerId - $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('✅ Using provided loan officer name: "$name" for ID: $loanOfficerId');
      }
    }

    if (name == null || name.isEmpty) {
      if (kDebugMode) {
        print('❌ Cannot record search: Loan officer name not available for ID: $loanOfficerId');
        print('   Skipping search recording - API requires loan officer name, not ID');
      }
      return null;
    }

    // Check cache to prevent duplicate calls (use name as key)
    final now = DateTime.now();
    if (_searchCallCache.containsKey(name)) {
      final lastCall = _searchCallCache[name]!;
      if (now.difference(lastCall) < _cacheDuration) {
        // Already called recently, skip
        return null;
      }
    }

    // Update cache
    _searchCallCache[name] = now;

    // Clean old cache entries (keep only last 100)
    if (_searchCallCache.length > 100) {
      final entries = _searchCallCache.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _searchCallCache.clear();
      for (var i = 0; i < 50 && i < entries.length; i++) {
        _searchCallCache[entries[i].key] = entries[i].value;
      }
    }

    // Use loan officer name in the endpoint (following agent pattern)
    // URL encode the name to handle spaces and special characters
    final encodedName = Uri.encodeComponent(name);
    final endpoint = '${ApiConstants.apiBaseUrl}/loan-officers/addSearch/$encodedName';

    if (kDebugMode) {
      print('📊 Recording search for loan officer: "$name" (ID: $loanOfficerId)');
      print('   Encoded name: $encodedName');
      print('   URL: $endpoint');
    }

    try {
      final response = await _dio.post(
        endpoint,
        options: Options(
          headers: ApiConstants.ngrokHeaders,
          validateStatus: (status) {
            // Accept all status codes to handle them manually
            return true;
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Search recorded successfully for loan officer: $name');
        }
        return response.data as Map<String, dynamic>?;
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist - log once and suppress future logs
        if (kDebugMode && !_hasLogged404ForSearch) {
          print('⚠️ Search endpoint not found (404) - endpoint may not exist on server');
          print('   Endpoint: $endpoint');
          print('   Future 404 errors for this endpoint will be suppressed');
          _hasLogged404ForSearch = true;
        }
        return null;
      } else {
        if (kDebugMode) {
          print('⚠️ Search recording failed for loan officer: $name');
          print('   Status Code: ${response.statusCode}');
          print('   Response: ${response.data}');
        }
        return null;
      }
    } on DioException catch (e) {
      // Suppress 404 errors after first log
      if (e.response?.statusCode == 404 && _hasLogged404ForSearch) {
        return null;
      }

      if (kDebugMode && (!_hasLogged404ForSearch || e.response?.statusCode != 404)) {
        print('⚠️ Error recording search for loan officer: $name');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
        if (e.response?.statusCode == 404) {
          _hasLogged404ForSearch = true;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Unexpected error recording search: $e');
      }
      return null;
    }
  }

  /// Records a contact/chat action for a loan officer
  /// Returns the response data
  Future<Map<String, dynamic>?> recordContact(String loanOfficerId) async {
    if (loanOfficerId.isEmpty) {
      return null;
    }

    // Check cache to prevent duplicate calls
    final now = DateTime.now();
    if (_contactCallCache.containsKey(loanOfficerId)) {
      final lastCall = _contactCallCache[loanOfficerId]!;
      if (now.difference(lastCall) < _cacheDuration) {
        // Already called recently, skip
        return null;
      }
    }

    // Update cache
    _contactCallCache[loanOfficerId] = now;

    final endpoint = '${ApiConstants.apiBaseUrl}/loan-officers/addContact/$loanOfficerId';

    if (kDebugMode && !_hasLogged404ForContact) {
      print('📞 Recording contact for loan officer: $loanOfficerId');
      print('   URL: $endpoint');
    }

    try {
      // API expects GET request, not POST (following agent pattern)
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: ApiConstants.ngrokHeaders,
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Contact recorded successfully for loan officer: $loanOfficerId');
        }
        return response.data as Map<String, dynamic>?;
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist - log once and suppress future logs
        if (kDebugMode && !_hasLogged404ForContact) {
          print('⚠️ Contact endpoint not found (404) - endpoint may not exist on server');
          print('   Endpoint: $endpoint');
          print('   Future 404 errors for this endpoint will be suppressed');
          _hasLogged404ForContact = true;
        }
        return null;
      } else {
        if (kDebugMode) {
          print('⚠️ Contact recording failed for loan officer: $loanOfficerId');
          print('   Status Code: ${response.statusCode}');
          print('   Response: ${response.data}');
        }
        return null;
      }
    } on DioException catch (e) {
      // Suppress 404 errors after first log
      if (e.response?.statusCode == 404 && _hasLogged404ForContact) {
        return null;
      }

      if (kDebugMode && (!_hasLogged404ForContact || e.response?.statusCode != 404)) {
        print('⚠️ Error recording contact for loan officer: $loanOfficerId');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
        if (e.response?.statusCode == 404) {
          _hasLogged404ForContact = true;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Unexpected error recording contact: $e');
      }
      return null;
    }
  }

  /// Records a profile view for a loan officer
  /// Returns the response data
  Future<Map<String, dynamic>?> recordProfileView(String loanOfficerId) async {
    if (loanOfficerId.isEmpty) {
      return null;
    }

    // Check cache to prevent duplicate calls
    final now = DateTime.now();
    if (_profileViewCallCache.containsKey(loanOfficerId)) {
      final lastCall = _profileViewCallCache[loanOfficerId]!;
      if (now.difference(lastCall) < _cacheDuration) {
        // Already called recently, skip
        return null;
      }
    }

    // Update cache
    _profileViewCallCache[loanOfficerId] = now;

    final endpoint = '${ApiConstants.apiBaseUrl}/loan-officers/addProfileView/$loanOfficerId';

    if (kDebugMode && !_hasLogged404ForProfileView) {
      print('👁️ Recording profile view for loan officer: $loanOfficerId');
      print('   URL: $endpoint');
    }

    try {
      final response = await _dio.post(
        endpoint,
        options: Options(
          headers: ApiConstants.ngrokHeaders,
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Profile view recorded successfully for loan officer: $loanOfficerId');
        }
        return response.data as Map<String, dynamic>?;
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist - log once and suppress future logs
        if (kDebugMode && !_hasLogged404ForProfileView) {
          print('⚠️ Profile view endpoint not found (404) - endpoint may not exist on server');
          print('   Endpoint: $endpoint');
          print('   Future 404 errors for this endpoint will be suppressed');
          _hasLogged404ForProfileView = true;
        }
        return null;
      } else {
        if (kDebugMode) {
          print('⚠️ Profile view recording failed for loan officer: $loanOfficerId');
          print('   Status Code: ${response.statusCode}');
          print('   Response: ${response.data}');
        }
        return null;
      }
    } on DioException catch (e) {
      // Suppress 404 errors after first log
      if (e.response?.statusCode == 404 && _hasLogged404ForProfileView) {
        return null;
      }

      if (kDebugMode && (!_hasLogged404ForProfileView || e.response?.statusCode != 404)) {
        print('⚠️ Error recording profile view for loan officer: $loanOfficerId');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
        if (e.response?.statusCode == 404) {
          _hasLogged404ForProfileView = true;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Unexpected error recording profile view: $e');
      }
      return null;
    }
  }

  /// Disposes the Dio instance
  void dispose() {
    _dio.close();
  }
}








import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getrebate/app/models/property_model.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class PropertyListingsController extends GetxController {
  final Dio _dio = Dio();
  final _storage = GetStorage();
  final _properties = <PropertyModel>[].obs;
  final _isLoading = false.obs;
  final _selectedStatus =
      'all'.obs; // 'all', 'active', 'pending', 'sold', 'draft'
  final _selectedPropertyType =
      'all'.obs; // 'all', 'house', 'condo', 'townhouse'
  final _selectedPriceRange =
      'all'.obs; // 'all', 'under_500k', '500k_1m', 'over_1m'
  final _searchQuery = ''.obs;

  // Getters
  List<PropertyModel> get properties => _properties;
  bool get isLoading => _isLoading.value;
  String get selectedStatus => _selectedStatus.value;
  String get selectedPropertyType => _selectedPropertyType.value;
  String get selectedPriceRange => _selectedPriceRange.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    _setupDio();
    // Fetch listings from API instead of mock data
    fetchListings();
  }

  void _setupDio() {
    _dio.options.baseUrl = ApiConstants.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      ...ApiConstants.ngrokHeaders,
    };
  }

  Future<void> fetchListings() async {
    try {
      _isLoading.value = true;

      // Get current user ID from AuthController
      final authController = Get.find<global.AuthController>();
      final currentUser = authController.currentUser;
      final agentId = currentUser?.id;

      if (agentId == null || agentId.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No agent ID found. Cannot fetch listings.');
        }
        _isLoading.value = false;
        return;
      }

      if (kDebugMode) {
        print('🚀 Fetching listings for agent ID: $agentId');
        print('📡 API Endpoint: ${ApiConstants.apiBaseUrl}/agent/getListingByAgentId/$agentId');
      }

      // Make API call with endpoint path (base URL is already set in _setupDio)
      final authToken = _storage.read('auth_token');
      final endpoint = '/agent/getListingByAgentId/$agentId';
      final fullUrl = '${ApiConstants.apiBaseUrl}$endpoint';
      
      if (kDebugMode) {
        print('📡 Full URL: $fullUrl');
        print('📋 Base URL: ${ApiConstants.apiBaseUrl}');
        print('📋 Endpoint: $endpoint');
        print('📋 Ngrok Headers: ${ApiConstants.ngrokHeaders}');
        print('🔑 Auth Token: ${authToken != null ? "Present" : "Missing"}');
      }
      
      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
        ...ApiConstants.ngrokHeaders,
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };
      
      if (kDebugMode) {
        print('📤 Request Headers: $headers');
      }
      
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
          followRedirects: true,
        ),
      );

      // Handle response (check status code)
      if (kDebugMode) {
        print('📥 Response Status Code: ${response.statusCode}');
        print('📥 Response Data Type: ${response.data.runtimeType}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ SUCCESS - Status Code: ${response.statusCode}');
          print('📥 Response Data:');
          print(response.data);
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }

        final responseData = response.data;
        
        // Handle both Map and direct response formats
        Map<String, dynamic> dataMap;
        if (responseData is Map<String, dynamic>) {
          dataMap = responseData;
        } else {
          if (kDebugMode) {
            print('⚠️ Unexpected response format: ${responseData.runtimeType}');
          }
          _isLoading.value = false;
          return;
        }

        final success = dataMap['success'] ?? false;
        final listingsData = dataMap['listings'] as List<dynamic>? ?? [];

        if (success && listingsData.isNotEmpty) {
          // Parse listings from API response
          final baseUrl = ApiConstants.baseUrl;
          final properties = listingsData
              .map((listingJson) {
                try {
                  return _parseListingToProperty(
                    listingJson as Map<String, dynamic>,
                    baseUrl,
                    agentId,
                  );
                } catch (e) {
                  if (kDebugMode) {
                    print('❌ Error parsing listing: $e');
                    print('   Listing JSON: $listingJson');
                  }
                  return null;
                }
              })
              .where((property) => property != null)
              .cast<PropertyModel>()
              .toList();

          _properties.value = properties;
          if (kDebugMode) {
            print('✅ Loaded ${properties.length} listings from API');
          }
        } else {
          // No listings found
          _properties.value = [];
          if (kDebugMode) {
            print('ℹ️ No listings found for this agent (success: $success, count: ${listingsData.length})');
          }
        }
      } else {
        // Non-200 status code
        _isLoading.value = false;
        if (kDebugMode) {
          print('⚠️ Unexpected status code: ${response.statusCode}');
          print('   Response: ${response.data}');
        }
        Get.snackbar('Error', 'Failed to fetch listings. Status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ ERROR - Status Code: ${e.response?.statusCode ?? "N/A"}');
        print('📥 Error Response:');
        print(e.response?.data ?? e.message);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      String errorMessage = 'Failed to fetch listings. Please try again.';

      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (e.response?.statusCode == 404) {
          // 404 is okay - just means no listings found
          _properties.value = [];
          if (kDebugMode) {
            print('ℹ️ No listings found (404)');
          }
          _isLoading.value = false;
          return;
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
        if (kDebugMode) {
          print('🔌 Connection Error Details: ${e.message}');
          print('   Error Type: ${e.type}');
        }
      }

      // Only show snackbar if we have a valid context
      try {
        if (Get.isSnackbarOpen == false) {
          Get.snackbar('Error', errorMessage);
        }
      } catch (snackbarError) {
        if (kDebugMode) {
          print('⚠️ Could not show error snackbar: $snackbarError');
        }
      }
    } catch (e) {
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ Unexpected Error: ${e.toString()}');
        print('   Error Type: ${e.runtimeType}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      
      // Only show snackbar if we have a valid context
      try {
        if (Get.isSnackbarOpen == false) {
          Get.snackbar('Error', 'Failed to fetch listings: ${e.toString()}');
        }
      } catch (snackbarError) {
        if (kDebugMode) {
          print('⚠️ Could not show error snackbar: $snackbarError');
        }
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Silent refresh without loading indicator - public method
  Future<void> refreshSilently() async {
    try {
      final authController = Get.find<global.AuthController>();
      final currentUser = authController.currentUser;
      final agentId = currentUser?.id;

      if (agentId == null || agentId.isEmpty) {
        return;
      }

      final authToken = _storage.read('auth_token');
      final endpoint = '/agent/getListingByAgentId/$agentId';
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        ...ApiConstants.ngrokHeaders,
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };
      
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        
        if (responseData is Map<String, dynamic>) {
          final success = responseData['success'] ?? false;
          final listingsData = responseData['listings'] as List<dynamic>? ?? [];

          if (success && listingsData.isNotEmpty) {
            final baseUrl = ApiConstants.baseUrl;
            final listings = listingsData
                .map((listingJson) {
                  try {
                    return _parseListingToProperty(
                      listingJson as Map<String, dynamic>,
                      baseUrl,
                      agentId,
                    );
                  } catch (e) {
                    if (kDebugMode) {
                      print('❌ Error parsing listing: $e');
                    }
                    return null;
                  }
                })
                .where((property) => property != null)
                .cast<PropertyModel>()
                .toList();

            _properties.value = listings; // This will trigger reactive update
            if (kDebugMode) {
              print('✅ Silently refreshed ${listings.length} listings');
            }
          } else {
            _properties.value = [];
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Silent refresh error: $e');
      }
      // Silent fail - don't show error to user
    }
  }

  PropertyModel _parseListingToProperty(
    Map<String, dynamic> json,
    String baseUrl,
    String agentId,
  ) {
    // Parse propertyDetails
    final propertyDetails = json['propertyDetails'] as Map<String, dynamic>? ?? {};
    final bedrooms = int.tryParse(propertyDetails['bedrooms']?.toString() ?? '0') ?? 0;
    final bathrooms = int.tryParse(propertyDetails['bathrooms']?.toString() ?? '0') ?? 0;
    // API uses 'squareFootage' but also check 'squareFeet' for compatibility
    final squareFeetStr = propertyDetails['squareFootage']?.toString() ?? 
                         propertyDetails['squareFeet']?.toString() ?? '0';
    final squareFeet = double.tryParse(squareFeetStr) ?? 0.0;
    // API uses 'type' in propertyDetails, not 'propertyType'
    final propertyType = propertyDetails['type']?.toString() ?? 
                         propertyDetails['propertyType']?.toString() ?? 'house';
    final yearBuilt = propertyDetails['yearBuilt'] != null
        ? int.tryParse(propertyDetails['yearBuilt'].toString())
        : null;

    // Parse price
    final priceString = json['price']?.toString() ?? '0';
    final price = double.tryParse(priceString) ?? 0.0;

    // Parse propertyPhotos and build full URLs
    final propertyPhotos = json['propertyPhotos'] as List<dynamic>? ?? [];
    final images = propertyPhotos
        .map((photo) {
          final photoPath = photo.toString();
          if (photoPath.isEmpty) return null;

          // If already a full URL, return as is
          if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
            return photoPath;
          }

          // Otherwise, prepend base URL
          String path = photoPath;
          if (!path.startsWith('/')) {
            path = '/$path';
          }
          return '$baseUrl$path';
        })
        .where((photo) => photo != null)
        .cast<String>()
        .toList();

    // Parse propertyFeatures as features map
    final propertyFeatures = json['propertyFeatures'] as List<dynamic>? ?? [];
    final features = <String, dynamic>{};
    for (var feature in propertyFeatures) {
      features[feature.toString()] = true;
    }

    // Parse status
    final statusString = json['status']?.toString() ?? 'draft';
    final status = statusString == 'active' ? 'active' : 
                   statusString == 'pending' ? 'pending' :
                   statusString == 'sold' ? 'sold' : 'draft';

    // Parse dates
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now();
    final updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : createdAt;

    return PropertyModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['propertyTitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: json['streetAddress']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      price: price,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      squareFeet: squareFeet,
      propertyType: propertyType.toLowerCase(),
      status: status,
      images: images,
      createdAt: createdAt,
      updatedAt: updatedAt,
      ownerId: agentId,
      agentId: json['id']?.toString() ?? agentId,
      features: features.isNotEmpty ? features : null,
      yearBuilt: yearBuilt,
    );
  }

  void _loadMockData() {
    _properties.value = [
      PropertyModel(
        id: 'prop_1',
        title: 'Beautiful Family Home',
        description:
            'Spacious 3-bedroom home with modern amenities and a large backyard perfect for families.',
        address: '123 Main Street',
        city: 'New York',
        state: 'NY',
        zipCode: '10001',
        price: 750000,
        bedrooms: 3,
        bathrooms: 2,
        squareFeet: 1800,
        propertyType: 'house',
        status: 'active',
        images: [
          'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&h=600&fit=crop',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ownerId: 'user_1',
        features: {
          'garage': true,
          'pool': false,
          'fireplace': true,
          'hardwood_floors': true,
        },
        lotSize: 0.25,
        yearBuilt: 2015,
        mlsNumber: 'MLS123456',
      ),
      PropertyModel(
        id: 'prop_2',
        title: 'Modern Downtown Condo',
        description:
            'Luxury condo in the heart of downtown with stunning city views and premium finishes.',
        address: '456 Downtown Ave',
        city: 'New York',
        state: 'NY',
        zipCode: '10002',
        price: 950000,
        bedrooms: 2,
        bathrooms: 2,
        squareFeet: 1200,
        propertyType: 'condo',
        status: 'pending',
        images: [
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&h=600&fit=crop',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ownerId: 'user_1',
        features: {
          'garage': true,
          'pool': true,
          'fireplace': false,
          'hardwood_floors': true,
          'balcony': true,
        },
        yearBuilt: 2020,
        mlsNumber: 'MLS789012',
      ),
      PropertyModel(
        id: 'prop_3',
        title: 'Charming Townhouse',
        description:
            'Historic townhouse with original character and modern updates throughout.',
        address: '789 Historic Lane',
        city: 'Brooklyn',
        state: 'NY',
        zipCode: '11201',
        price: 650000,
        bedrooms: 4,
        bathrooms: 3,
        squareFeet: 2200,
        propertyType: 'townhouse',
        status: 'draft',
        images: [
          'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800&h=600&fit=crop',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        ownerId: 'user_1',
        features: {
          'garage': false,
          'pool': false,
          'fireplace': true,
          'hardwood_floors': true,
          'garden': true,
        },
        lotSize: 0.15,
        yearBuilt: 1920,
      ),
    ];
  }

  void setSelectedStatus(String status) {
    _selectedStatus.value = status;
    // filteredProperties getter will automatically recompute when _selectedStatus changes
  }

  void setSelectedPropertyType(String type) {
    _selectedPropertyType.value = type;
  }

  void setSelectedPriceRange(String range) {
    _selectedPriceRange.value = range;
  }

  void setSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void clearFilters() {
    _selectedStatus.value = 'all';
    _selectedPropertyType.value = 'all';
    _selectedPriceRange.value = 'all';
    _searchQuery.value = '';
  }

  List<PropertyModel> get filteredProperties {
    var filtered = _properties.where((property) {
      // Status filter
      if (_selectedStatus.value != 'all' &&
          property.status != _selectedStatus.value) {
        return false;
      }

      // Property type filter
      if (_selectedPropertyType.value != 'all' &&
          property.propertyType != _selectedPropertyType.value) {
        return false;
      }

      // Price range filter
      if (_selectedPriceRange.value != 'all') {
        switch (_selectedPriceRange.value) {
          case 'under_500k':
            if (property.price >= 500000) return false;
            break;
          case '500k_1m':
            if (property.price < 500000 || property.price > 1000000)
              return false;
            break;
          case 'over_1m':
            if (property.price <= 1000000) return false;
            break;
        }
      }

      // Search query filter
      if (_searchQuery.value.isNotEmpty) {
        final query = _searchQuery.value.toLowerCase();
        if (!property.title.toLowerCase().contains(query) &&
            !property.description.toLowerCase().contains(query) &&
            !property.address.toLowerCase().contains(query) &&
            !property.city.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    return filtered;
  }

  // DISABLED: Buyer listing creation - buyers cannot create listings anymore
  // void createNewListing() async {
  //   // Navigate to create listing page
  //   try {
  //     final result = await Get.toNamed(AppPages.CREATE_LISTING);
  //     // Always refresh when coming back, regardless of result
  //     // This ensures we have the latest data even if user just navigated back
  //     await refreshSilently();
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Navigation error: $e');
  //     }
  //     try {
  //       Get.snackbar('Error', 'Failed to navigate to create listing page');
  //     } catch (snackbarError) {
  //       if (kDebugMode) print('Could not show snackbar: $snackbarError');
  //     }
  //   }
  // }
  
  // Placeholder method to prevent errors
  void createNewListing() {
    // Buyers cannot create listings anymore
    Get.snackbar('Info', 'Buyers cannot create listings. Please contact an agent.');
  }

  void editProperty(PropertyModel property) async {
    // Navigate to edit property page
    try {
      final result = await Get.toNamed(
        AppPages.EDIT_LISTING,
        arguments: {'property': property},
      );
      // Always refresh when coming back, regardless of result
      // This ensures we have the latest data even if user just navigated back
      await refreshSilently();
    } catch (e) {
      if (kDebugMode) {
        print('Navigation error: $e');
      }
      try {
        Get.snackbar('Error', 'Failed to navigate to edit listing page');
      } catch (snackbarError) {
        if (kDebugMode) print('Could not show snackbar: $snackbarError');
      }
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      _isDeleting.value = true;
      _isLoading.value = true;

      final authToken = _storage.read('auth_token');
      final endpoint = ApiConstants.getDeleteListingEndpoint(propertyId);

      if (kDebugMode) {
        print('🗑️ Deleting listing: $propertyId');
        print('📡 API Endpoint: $endpoint');
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        ...ApiConstants.ngrokHeaders,
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final response = await _dio.delete(
        endpoint.replaceFirst(ApiConstants.apiBaseUrl, ''),
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (kDebugMode) {
          print('✅ SUCCESS - Listing deleted');
          print('📥 Response: ${response.data}');
        }

        // Remove from local list immediately for instant UI update
        _properties.removeWhere((property) => property.id == propertyId);

        // Show success message
        try {
          Get.snackbar(
            'Success',
            'Property deleted successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            borderRadius: 12,
            duration: const Duration(seconds: 2),
            snackStyle: SnackStyle.FLOATING,
            icon: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
          );
        } catch (snackbarError) {
          if (kDebugMode) print('⚠️ Could not show snackbar: $snackbarError');
        }

        // Optionally refresh to ensure consistency
        await refreshSilently();
      } else {
        _isLoading.value = false;
        String errorMessage = 'Failed to delete property. Please try again.';
        
        if (response.statusCode == 404) {
          errorMessage = 'Property not found. It may have already been deleted.';
          // Remove from local list anyway
          _properties.removeWhere((property) => property.id == propertyId);
        } else if (response.statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (response.statusCode == 403) {
          errorMessage = 'You do not have permission to delete this property.';
        }

        try {
          Get.snackbar(
            'Error',
            errorMessage,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade600,
            colorText: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            borderRadius: 12,
            duration: const Duration(seconds: 3),
            snackStyle: SnackStyle.FLOATING,
          );
        } catch (snackbarError) {
          if (kDebugMode) print('⚠️ Could not show error snackbar: $snackbarError');
        }
      }
    } on DioException catch (e) {
      _isLoading.value = false;

      if (kDebugMode) {
        print('❌ ERROR - Status Code: ${e.response?.statusCode ?? "N/A"}');
        print('📥 Error Response:');
        print(e.response?.data ?? e.message);
      }

      String errorMessage = 'Failed to delete property. Please try again.';

      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Property not found. It may have already been deleted.';
          // Remove from local list anyway
          _properties.removeWhere((property) => property.id == propertyId);
        } else if (e.response?.statusCode == 403) {
          errorMessage = 'You do not have permission to delete this property.';
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      try {
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
          snackStyle: SnackStyle.FLOATING,
        );
      } catch (snackbarError) {
        if (kDebugMode) print('⚠️ Could not show error snackbar: $snackbarError');
      }
    } catch (e) {
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ Unexpected Error: ${e.toString()}');
      }
      try {
        Get.snackbar(
          'Error',
          'Failed to delete property: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
          snackStyle: SnackStyle.FLOATING,
        );
      } catch (snackbarError) {
        if (kDebugMode) print('⚠️ Could not show error snackbar: $snackbarError');
      }
    } finally {
      _isLoading.value = false;
      _isDeleting.value = false;
    }
  }

  final _isDeleting = false.obs;
  bool get isDeleting => _isDeleting.value;

  void showDeleteConfirmation(String propertyId, String propertyTitle) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Obx(
          () => Container(
            constraints: BoxConstraints(maxWidth: 320.w),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Compact Icon
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 28.sp,
                      color: Colors.red.shade600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // Title
                  Text(
                    'Delete Property?',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  
                  // Message
                  Text(
                    '"$propertyTitle"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.mediumGray,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'This action cannot be undone',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  
                  // Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: TextButton(
                          onPressed: _isDeleting.value
                              ? null
                              : () {
                                  try {
                                    if (Get.isDialogOpen == true) {
                                      // Use Navigator directly to avoid snackbar controller issues
                                      Navigator.of(Get.context!, rootNavigator: true).pop();
                                    }
                                  } catch (e) {
                                    if (kDebugMode) print('Error closing dialog: $e');
                                    // Try Get.back() as fallback
                                    try {
                                      if (Get.isDialogOpen == true) {
                                        Get.back();
                                      }
                                    } catch (_) {}
                                  }
                                },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              side: BorderSide(
                                color: AppTheme.mediumGray.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkGray,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      
                      // Delete Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isDeleting.value
                              ? null
                              : () async {
                                  _isDeleting.value = true;
                                  try {
                                    // Delete property first
                                    await deleteProperty(propertyId);
                                    // Close dialog after deletion completes
                                    if (Get.isDialogOpen == true) {
                                      try {
                                        // Use Navigator directly to avoid snackbar controller issues
                                        Navigator.of(Get.context!, rootNavigator: true).pop();
                                      } catch (e) {
                                        if (kDebugMode) print('Error closing dialog: $e');
                                        // Try Get.back() as fallback
                                        try {
                                          if (Get.isDialogOpen == true) {
                                            Get.back();
                                          }
                                        } catch (_) {}
                                      }
                                    }
                                  } catch (e) {
                                    if (kDebugMode) print('Error in delete: $e');
                                    _isDeleting.value = false;
                                    // Close dialog even on error
                                    if (Get.isDialogOpen == true) {
                                      try {
                                        // Use Navigator directly to avoid snackbar controller issues
                                        Navigator.of(Get.context!, rootNavigator: true).pop();
                                      } catch (closeError) {
                                        if (kDebugMode) print('Error closing dialog: $closeError');
                                        // Try Get.back() as fallback
                                        try {
                                          if (Get.isDialogOpen == true) {
                                            Get.back();
                                          }
                                        } catch (_) {}
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            elevation: 0,
                          ),
                          child: _isDeleting.value
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 14.sp,
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
        ),
      ),
      barrierDismissible: !_isDeleting.value,
      barrierColor: Colors.black.withOpacity(0.5),
    ).then((_) {
      // Reset deleting state when dialog closes
      _isDeleting.value = false;
    });
  }

  void updatePropertyStatus(String propertyId, String newStatus) {
    final index = _properties.indexWhere(
      (property) => property.id == propertyId,
    );
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
    }
  }

  String getStatusColor(String status) {
    switch (status) {
      case 'active':
        return '#4CAF50'; // Green
      case 'pending':
        return '#FF9800'; // Orange
      case 'sold':
        return '#2196F3'; // Blue
      case 'draft':
        return '#9E9E9E'; // Gray
      default:
        return '#9E9E9E';
    }
  }

  String getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'sold':
        return 'Sold';
      case 'draft':
        return 'Draft';
      default:
        return 'Unknown';
    }
  }

  String getPropertyTypeLabel(String type) {
    switch (type) {
      case 'house':
        return 'House';
      case 'condo':
        return 'Condo';
      case 'townhouse':
        return 'Townhouse';
      default:
        return 'Unknown';
    }
  }

  String getPriceRangeLabel(String range) {
    switch (range) {
      case 'under_500k':
        return 'Under \$500K';
      case '500k_1m':
        return '\$500K - \$1M';
      case 'over_1m':
        return 'Over \$1M';
      default:
        return 'All Prices';
    }
  }
}

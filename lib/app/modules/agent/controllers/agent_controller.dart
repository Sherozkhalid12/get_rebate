import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getrebate/app/models/zip_code_model.dart';
import 'package:getrebate/app/models/agent_listing_model.dart';
import 'package:getrebate/app/models/subscription_model.dart';
import 'package:getrebate/app/models/promo_code_model.dart';
import 'package:getrebate/app/models/lead_model.dart';
import 'package:getrebate/app/services/zip_code_pricing_service.dart';
import 'package:getrebate/app/services/leads_service.dart';
import 'package:getrebate/app/services/zip_codes_service.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/network_error_handler.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'dart:math';

class AgentController extends GetxController {
  // API
  final Dio _dio = Dio();
  final _storage = GetStorage();
  // Using ApiConstants for centralized URL management
  static String get _baseUrl => ApiConstants.apiBaseUrl;

  // Data
  final _claimedZipCodes = <ZipCodeModel>[].obs;
  final _availableZipCodes = <ZipCodeModel>[].obs;
  final _myListings = <AgentListingModel>[].obs;
  final _allListings = <AgentListingModel>[].obs; // All listings from API (unfiltered)
  final _leads = <LeadModel>[].obs;
  final _isLoading = false.obs;
  final _isLoadingLeads = false.obs;
  final _selectedTab = 0.obs; // 0: Dashboard, 1: ZIP Management, 2: My Listings, 3: Stats, 4: Billing, 5: Leads
  
  // Filters
  final _selectedStatusFilter = Rxn<MarketStatus>(); // null = all
  final _searchQuery = ''.obs;

  // Stats
  final _searchesAppearedIn = 0.obs;
  final _profileViews = 0.obs;
  final _contacts = 0.obs;
  final _websiteClicks = 0.obs;
  final _totalRevenue = 0.0.obs;

  // Subscription & Promo Code
  final _subscription = Rxn<SubscriptionModel>();
  final _generatedPromoCodes = <PromoCodeModel>[].obs;
  final _promoCodeInput = ''.obs;

  // Track per-ZIP claim/release operations for individual button loaders
  final RxSet<String> _processingZipCodes = <String>{}.obs;

  // State selection for ZIP codes
  final _selectedState = Rxn<String>();
  final _isLoadingZipCodes = false.obs;
  static const String _selectedStateStorageKey = 'agent_selected_state';
  static const String _zipCodesCachePrefix = 'agent_zip_codes_cache_';
  static const String _zipCodesCacheTimestampPrefix = 'agent_zip_codes_timestamp_';
  static const Duration _cacheExpirationDuration = Duration(hours: 24);

  // Standard pricing (deprecated - now using zip code population-based pricing)
  // Kept for backward compatibility, but pricing is now calculated from zip codes
  @Deprecated('Use ZipCodePricingService instead')
  static const double standardMonthlyPrice = 17.99;

  // Getters
  List<ZipCodeModel> get claimedZipCodes => _claimedZipCodes;
  List<ZipCodeModel> get availableZipCodes => _availableZipCodes;
  List<AgentListingModel> get myListings => _myListings; // Filtered listings
  List<AgentListingModel> get allListings => _allListings; // All listings
  List<LeadModel> get leads => _leads;
  bool get isLoading => _isLoading.value;
  bool get isLoadingLeads => _isLoadingLeads.value;
  bool get isLoadingZipCodes => _isLoadingZipCodes.value;
  String? get selectedState => _selectedState.value;
  int get selectedTab => _selectedTab.value;
  MarketStatus? get selectedStatusFilter => _selectedStatusFilter.value;
  String get searchQuery => _searchQuery.value;
  
  // Filter methods
  void setStatusFilter(MarketStatus? status) {
    _selectedStatusFilter.value = status;
    _applyFilters();
  }
  
  void setSearchQuery(String query) {
    _searchQuery.value = query;
    _applyFilters();
  }
  
  void clearFilters() {
    _selectedStatusFilter.value = null;
    _searchQuery.value = '';
    _applyFilters();
  }
  
  void _applyFilters() {
    var filtered = List<AgentListingModel>.from(_allListings);
    
    // Apply status filter
    if (_selectedStatusFilter.value != null) {
      filtered = filtered.where((listing) => 
        listing.marketStatus == _selectedStatusFilter.value
      ).toList();
    }
    
    // Apply search query filter
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered.where((listing) {
        return listing.title.toLowerCase().contains(query) ||
               listing.description.toLowerCase().contains(query) ||
               listing.address.toLowerCase().contains(query) ||
               listing.city.toLowerCase().contains(query) ||
               listing.state.toLowerCase().contains(query) ||
               listing.zipCode.contains(query);
      }).toList();
    }
    
    _myListings.value = filtered;
  }
  int get searchesAppearedIn => _searchesAppearedIn.value;
  int get profileViews => _profileViews.value;
  int get contacts => _contacts.value;
  int get websiteClicks => _websiteClicks.value;
  double get totalRevenue => _totalRevenue.value;

  // Subscription & Promo Code Getters
  SubscriptionModel? get subscription => _subscription.value;
  List<PromoCodeModel> get generatedPromoCodes => _generatedPromoCodes;
  String get promoCodeInput => _promoCodeInput.value;
  double get standardPrice => standardMonthlyPrice;
  bool get hasActivePromo => _subscription.value?.isPromoActive ?? false;
  bool get isCancelled => _subscription.value?.isCancelled ?? false;
  int get daysUntilCancellation =>
      _subscription.value?.daysUntilCancellation ?? 0;

  // Listing limits
  int get freeListingLimit => 3;
  int get currentListingCount => _allListings.length; // Use allListings for count
  int get remainingFreeListings =>
      (freeListingLimit - currentListingCount).clamp(0, freeListingLimit);
  bool get canAddFreeListing => remainingFreeListings > 0;
  double get additionalListingPrice => 9.99;

  @override
  void onInit() {
    super.onInit();
    _setupDio();
    _loadMockData(); // Keep mock data for ZIP codes - instant
    _initializeSubscription(); // Initialize subscription - instant
    checkPromoExpiration(); // Check if any promos have expired - instant
    
    // Restore selected state from storage and fetch ZIP codes if state exists
    _restoreSelectedState();
    
    // Fetch user stats from API
    Future.microtask(() => fetchUserStats());
    
    // Fetch listings in background without blocking UI
    Future.microtask(() => fetchAgentListings());
    
    // Preload chat threads for instant access when agent opens messages
    _preloadThreads();
  }

  /// Restores the selected state from storage and loads ZIP codes from cache if available
  Future<void> _restoreSelectedState() async {
    final savedState = _storage.read(_selectedStateStorageKey) as String?;
    if (savedState != null && savedState.isNotEmpty) {
      _selectedState.value = savedState;
      // Load ZIP codes from cache first (instant), then refresh in background if needed
      final stateCode = _getStateCodeFromName(savedState);
      await _loadZipCodesFromCache(stateCode);
      // Refresh in background if cache is expired or empty
      Future.microtask(() => fetchZipCodesForState(stateCode, forceRefresh: false));
    }
  }

  /// Loads ZIP codes from cache for the given state
  Future<void> _loadZipCodesFromCache(String stateCode) async {
    try {
      final cacheKey = '$_zipCodesCachePrefix$stateCode';
      final timestampKey = '$_zipCodesCacheTimestampPrefix$stateCode';
      
      final cachedData = _storage.read(cacheKey) as List<dynamic>?;
      final cachedTimestamp = _storage.read(timestampKey) as String?;
      
      if (cachedData != null && cachedTimestamp != null) {
        final cacheTime = DateTime.parse(cachedTimestamp);
        final now = DateTime.now();
        
        // Check if cache is still valid (not expired)
        if (now.difference(cacheTime) < _cacheExpirationDuration) {
          // Load from cache
          final zipCodes = cachedData
              .map((json) => ZipCodeModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          // Filter out already claimed ZIP codes
          final claimedZipCodesSet = _claimedZipCodes.map((z) => z.zipCode).toSet();
          final availableZips = zipCodes
              .where((zip) => !claimedZipCodesSet.contains(zip.zipCode))
              .toList();
          
          _availableZipCodes.value = availableZips;
          
          if (kDebugMode) {
            print('✅ Loaded ${availableZips.length} ZIP codes from cache for $stateCode');
          }
          return;
        } else {
          if (kDebugMode) {
            print('⏰ Cache expired for $stateCode, will fetch from API');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error loading ZIP codes from cache: $e');
      }
    }
  }

  /// Saves ZIP codes to cache for the given state
  void _saveZipCodesToCache(String stateCode, List<ZipCodeModel> zipCodes) {
    try {
      final cacheKey = '$_zipCodesCachePrefix$stateCode';
      final timestampKey = '$_zipCodesCacheTimestampPrefix$stateCode';
      
      final jsonData = zipCodes.map((zip) => zip.toJson()).toList();
      _storage.write(cacheKey, jsonData);
      _storage.write(timestampKey, DateTime.now().toIso8601String());
      
      if (kDebugMode) {
        print('💾 Cached ${zipCodes.length} ZIP codes for $stateCode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error saving ZIP codes to cache: $e');
      }
    }
  }

  /// Preloads chat threads for instant access when agent opens messages
  void _preloadThreads() {
    // Defer to next frame to avoid setState during build
    Future.microtask(() {
      try {
        // Initialize messages controller if not already registered
        if (!Get.isRegistered<MessagesController>()) {
          Get.put(MessagesController(), permanent: true);
        }
        final messagesController = Get.find<MessagesController>();
        
        // Load threads in background - don't wait for it
        messagesController.refreshThreads();
        
        // IMPORTANT: Ensure socket is connected for real-time message reception
        // The socket should be initialized when MessagesController is created,
        // but we'll ensure it's connected here as well
        if (kDebugMode) {
          print('🚀 Agent: Preloading chat threads and ensuring socket connection...');
        }
        
        // The socket will be initialized in MessagesController.onInit()
        // But we can also manually trigger it if needed
        // The MessagesController should handle this automatically
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Agent: Failed to preload threads: $e');
        }
        // Don't block initialization if preload fails
      }
    });
  }

  void _initializeSubscription() {
    // Initialize with default subscription (no promo)
    // Base price will be calculated from claimed zip codes
    final authController = Get.find<global.AuthController>();
    final userId = authController.currentUser?.id ?? 'agent_1';

    // Calculate base price from claimed zip codes using population-based pricing
    final basePrice = ZipCodePricingService.calculateTotalMonthlyPrice(
      _claimedZipCodes,
    );

    _subscription.value = SubscriptionModel(
      id: 'sub_${userId}',
      userId: userId,
      status: SubscriptionStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      baseMonthlyPrice: basePrice > 0
          ? basePrice
          : standardMonthlyPrice, // Fallback to old price if no zip codes
      currentMonthlyPrice: basePrice > 0 ? basePrice : standardMonthlyPrice,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  void _setupDio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Get auth token from storage
    final authToken = _storage.read('auth_token');
    _dio.options.headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  void setSelectedTab(int index) {
    _selectedTab.value = index;
    
    // Refresh listings when "My Listings" tab is selected
    if (index == 2) {
      Future.microtask(() => fetchAgentListings());
    }
    
    // Always refresh leads when switching to leads tab to get latest data
    // Fetch even if already on tab 5 (in case data needs refresh)
    if (index == 5 && !_isLoadingLeads.value) {
      // Fetch leads every time user visits the leads tab
      Future.microtask(() => refreshLeads());
    }
  }

  void _loadMockData() {
    // Mock claimed ZIP codes
    _claimedZipCodes.value = [
      ZipCodeModel(
        zipCode: '10001',
        state: 'NY',
        population: 50000,
        claimedByAgent: 'agent_1',
        claimedAt: DateTime.now().subtract(const Duration(days: 30)),
        price: 299.99,
        isAvailable: false,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        searchCount: 45,
      ),
      ZipCodeModel(
        zipCode: '10002',
        state: 'NY',
        population: 45000,
        claimedByAgent: 'agent_1',
        claimedAt: DateTime.now().subtract(const Duration(days: 15)),
        price: 249.99,
        isAvailable: false,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        searchCount: 32,
      ),
    ];

    // Mock available ZIP codes
    _availableZipCodes.value = [
      ZipCodeModel(
        zipCode: '10003',
        state: 'NY',
        population: 40000,
        price: 199.99,
        isAvailable: true,
        createdAt: DateTime.now(),
        searchCount: 0,
      ),
      ZipCodeModel(
        zipCode: '10004',
        state: 'NY',
        population: 35000,
        price: 179.99,
        isAvailable: true,
        createdAt: DateTime.now(),
        searchCount: 0,
      ),
      ZipCodeModel(
        zipCode: '10005',
        state: 'NY',
        population: 30000,
        price: 159.99,
        isAvailable: true,
        createdAt: DateTime.now(),
        searchCount: 0,
      ),
    ];

    // Mock listings
    _myListings.value = [
      AgentListingModel(
        id: 'listing_1',
        agentId: 'agent_1',
        title: 'Beautiful 3BR Condo in Manhattan',
        description:
            'Stunning 3-bedroom condo with city views, modern kitchen, and premium finishes.',
        priceCents: 125000000, // $1,250,000
        address: '123 Park Avenue',
        city: 'New York',
        state: 'NY',
        zipCode: '10001',
        photoUrls: [
          'https://images.unsplash.com/photo-1560185008-b033106af2fb?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1560185127-6c4a0b4b0b0b?w=800&h=600&fit=crop',
        ],
        bacPercent: 2.5,
        dualAgencyAllowed: true,
        isApproved: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        approvedAt: DateTime.now().subtract(const Duration(days: 28)),
        searchCount: 45,
        viewCount: 234,
        contactCount: 12,
        marketStatus: MarketStatus.forSale,
      ),
      AgentListingModel(
        id: 'listing_2',
        agentId: 'agent_1',
        title: 'Luxury Penthouse with Terrace',
        description:
            'Exclusive penthouse featuring private terrace, panoramic views, and luxury amenities.',
        priceCents: 250000000, // $2,500,000
        address: '456 Central Park West',
        city: 'New York',
        state: 'NY',
        zipCode: '10002',
        photoUrls: [
          'https://images.unsplash.com/photo-1560185008-b033106af2fb?w=800&h=600&fit=crop',
        ],
        bacPercent: 3.0,
        dualAgencyAllowed: false,
        isActive: true,
        isApproved: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        approvedAt: DateTime.now().subtract(const Duration(days: 12)),
        searchCount: 32,
        viewCount: 156,
        contactCount: 8,
        marketStatus: MarketStatus.pending,
      ),
      AgentListingModel(
        id: 'listing_3',
        agentId: 'agent_1',
        title: 'Modern Studio in SoHo',
        description:
            'Chic studio apartment in trendy SoHo neighborhood, perfect for young professionals.',
        priceCents: 75000000, // $750,000
        address: '789 Broadway',
        city: 'New York',
        state: 'NY',
        zipCode: '10003',
        photoUrls: [],
        bacPercent: 2.0,
        dualAgencyAllowed: true,
        isApproved: false,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        searchCount: 8,
        viewCount: 23,
        contactCount: 2,
        marketStatus: MarketStatus.sold,
        isActive: false,
      ),
    ];

    // Stats will be loaded from API in fetchUserStats()
    // Don't reset to 0 here to avoid overwriting API data
  }

  /// Fetches user stats from the API
  Future<void> fetchUserStats() async {
    try {
      final authController = Get.find<global.AuthController>();
      final userId = authController.currentUser?.id;

      if (userId == null || userId.isEmpty) {
        if (kDebugMode) {
          print('⚠️ Cannot fetch stats: User ID is null or empty');
        }
        return;
      }

      if (kDebugMode) {
        print('📡 Fetching user stats for userId: $userId');
        print('   Endpoint: $_baseUrl/auth/users/$userId');
      }

      // Get auth token from storage
      final authToken = _storage.read('auth_token');

      final response = await _dio.get(
        '/auth/users/$userId',
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (kDebugMode) {
        print('📥 API Response Status: ${response.statusCode}');
        print('📥 API Response Data: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        
        // Handle both response formats: {user: {...}} or direct user object
        final userData = responseData is Map && responseData.containsKey('user')
            ? responseData['user']
            : responseData;

        if (kDebugMode) {
          print('📥 Extracted userData:');
          print('   searches: ${userData['searches']}');
          print('   views: ${userData['views']}');
          print('   contacts: ${userData['contacts']}');
          print('   websiteclicks: ${userData['websiteclicks']}');
          print('   revenue: ${userData['revenue']}');
        }

        // Extract stats from API response
        _searchesAppearedIn.value = (userData['searches'] as num?)?.toInt() ?? 0;
        _profileViews.value = (userData['views'] as num?)?.toInt() ?? 0;
        _contacts.value = (userData['contacts'] as num?)?.toInt() ?? 0;
        _websiteClicks.value = (userData['websiteclicks'] as num?)?.toInt() ?? 0;
        _totalRevenue.value = (userData['revenue'] as num?)?.toDouble() ?? 0.0;

        // Extract claimed ZIP codes from user profile (if present)
        final claimedZipCodesData =
            userData['claimedZipCodes'] as List<dynamic>? ?? [];
        if (claimedZipCodesData.isNotEmpty) {
          if (kDebugMode) {
            print('📦 Loading claimed ZIP codes from user profile '
                '(${claimedZipCodesData.length} items)');
          }

          final claimedZips = claimedZipCodesData
              .whereType<Map<String, dynamic>>()
              .map((zipJson) {
            final zipCode = zipJson['postalCode']?.toString() ?? '';
            if (zipCode.isEmpty) return null;

            return ZipCodeModel(
              zipCode: zipCode,
              state: zipJson['state']?.toString() ?? '',
              population:
                  (zipJson['population'] as num?)?.toInt() ?? 0,
              price: (zipJson['price'] as num?)?.toDouble(),
              claimedByAgent: userId,
              claimedAt: DateTime.tryParse(
                    zipJson['claimedAt']?.toString() ?? '',
                  ) ??
                  DateTime.now(),
              isAvailable: false,
              createdAt: DateTime.tryParse(
                    zipJson['createdAt']?.toString() ?? '',
                  ) ??
                  DateTime.now(),
              searchCount: (zipJson['searchCount'] as num?)?.toInt() ?? 0,
            );
          }).whereType<ZipCodeModel>().toList();

          // Replace local claimed ZIP codes with those from API
          _claimedZipCodes
            ..clear()
            ..addAll(claimedZips);

          if (kDebugMode) {
            print('✅ Claimed ZIP codes synced from API: '
                '${_claimedZipCodes.length} items');
          }
        }

        if (kDebugMode) {
          print('✅ User stats fetched and updated successfully:');
          print('   Searches: ${_searchesAppearedIn.value}');
          print('   Views: ${_profileViews.value}');
          print('   Contacts: ${_contacts.value}');
          print('   Website Clicks: ${_websiteClicks.value}');
          print('   Revenue: ${_totalRevenue.value}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Unexpected status code: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException fetching user stats:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Response: ${e.response?.data}');
        print('   Status Code: ${e.response?.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching user stats: $e');
        print('   Error type: ${e.runtimeType}');
      }
    }
  }

  void updateListingMarketStatus(String listingId, MarketStatus status) {
    final index = _allListings.indexWhere((listing) => listing.id == listingId);
    if (index == -1) return;

    final currentListing = _allListings[index];
    final updatedListing = currentListing.copyWith(
      marketStatus: status,
      updatedAt: DateTime.now(),
      isActive: status != MarketStatus.sold,
    );

    _allListings[index] = updatedListing;
    _applyFilters(); // Apply filters to update displayed listings

    String message;
    switch (status) {
      case MarketStatus.forSale:
        message =
            'Status set to For Sale. Remember to move it to Pending once an offer is accepted.';
        break;
      case MarketStatus.pending:
        message =
            'Status set to Pending. Don\'t forget to mark it Sold after closing.';
        break;
      case MarketStatus.sold:
        message = 'Status set to Sold. Buyers will no longer see this listing.';
        break;
    }

    Get.snackbar(
      'Listing updated',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> claimZipCode(ZipCodeModel zipCode) async {
    try {
      if (_processingZipCodes.contains(zipCode.zipCode)) return;
      _processingZipCodes.add(zipCode.zipCode);
      _isLoading.value = true;

      // Check if agent can claim more ZIP codes (max 6)
      if (_claimedZipCodes.length >= 6) {
        Get.snackbar('Error', 'You can only claim up to 6 ZIP codes');
        _isLoading.value = false;
        return;
      }

      // Get auth token from storage
      final authToken = _storage.read('auth_token');
      final authController = Get.find<global.AuthController>();
      final userId = authController.currentUser?.id;

      if (userId == null || userId.isEmpty) {
        Get.snackbar('Error', 'User not authenticated. Please login again.');
        _isLoading.value = false;
        return;
      }

      // Prepare request body according to API specification
      // IMPORTANT: Backend expects the current agent's user ID in `id`
      final requestBody = {
        'id': userId, // agent's Mongo user _id
        'zipcode': zipCode.zipCode,
        'price': (zipCode.price ?? zipCode.calculatedPrice).toStringAsFixed(0), // Convert to string as per API
        'state': zipCode.state,
        'population': zipCode.population.toString(),
      };

      if (kDebugMode) {
        print('📡 Claiming ZIP code: ${zipCode.zipCode}');
        print('   Endpoint: $_baseUrl/zip-codes/claim');
        print('   Request body: $requestBody');
      }

      // Make API call to claim ZIP code
      final response = await _dio.post(
        '/zip-codes/claim',
        data: requestBody,
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ ZIP code claimed successfully');
          print('   Response: ${response.data}');
        }

        // Add to claimed ZIP codes
        final claimedZip = zipCode.copyWith(
          claimedByAgent: userId,
          claimedAt: DateTime.now(),
          isAvailable: false,
        );

        _claimedZipCodes.add(claimedZip);
        _availableZipCodes.removeWhere((zip) => zip.zipCode == zipCode.zipCode);

        // Update subscription price based on new zip code
        _updateSubscriptionPrice();

        // Invalidate cache for this state to ensure fresh data
        final stateCode = zipCode.state;
        _storage.remove('$_zipCodesCachePrefix$stateCode');
        _storage.remove('$_zipCodesCacheTimestampPrefix$stateCode');

        Get.snackbar(
          'Success',
          'ZIP code ${zipCode.zipCode} claimed successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Failed to claim ZIP code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Error claiming ZIP code: ${e.message}');
        print('   Response: ${e.response?.data}');
      }

      String errorMessage = 'Failed to claim ZIP code. Please try again.';
      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'Invalid request. Please check your input.';
        } else if (e.response?.statusCode == 409) {
          errorMessage = 'This ZIP code is already claimed.';
        }
      }

      Get.snackbar('Error', errorMessage);
    } catch (e) {
      NetworkErrorHandler.handleError(
        e,
        defaultMessage: 'Unable to claim ZIP code. Please check your internet connection and try again.',
      );
    } finally {
      _processingZipCodes.remove(zipCode.zipCode);
      _isLoading.value = false;
    }
  }

  Future<void> releaseZipCode(ZipCodeModel zipCode) async {
    try {
      if (_processingZipCodes.contains(zipCode.zipCode)) return;
      _processingZipCodes.add(zipCode.zipCode);
      _isLoading.value = true;

      // Get auth token from storage
      final authToken = _storage.read('auth_token');
      final authController = Get.find<global.AuthController>();
      final userId = authController.currentUser?.id;

      if (userId == null || userId.isEmpty) {
        Get.snackbar('Error', 'User not authenticated. Please login again.');
        _isLoading.value = false;
        return;
      }

      // Prepare request body according to API specification
      // Backend expects current agent ID and the zipcode being released
      final requestBody = {
        'id': userId,
        'zipcode': zipCode.zipCode,
      };

      if (kDebugMode) {
        print('📡 Releasing ZIP code: ${zipCode.zipCode}');
        print('   Endpoint: $_baseUrl/zip-codes/release');
        print('   Request body: $requestBody');
      }

      // Call release endpoint
      final response = await _dio.patch(
        '/zip-codes/release',
        data: requestBody,
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to release ZIP code: ${response.statusCode}');
      }

      // Remove from claimed ZIP codes
      _claimedZipCodes.removeWhere((zip) => zip.zipCode == zipCode.zipCode);

      // Add back to available ZIP codes
      final availableZip = zipCode.copyWith(
        claimedByAgent: null,
        claimedAt: null,
        isAvailable: true,
      );

      _availableZipCodes.add(availableZip);

      // Update subscription price after releasing zip code
      _updateSubscriptionPrice();

      Get.snackbar(
        'Success',
        'ZIP code ${zipCode.zipCode} released successfully!',
      );
    } catch (e) {
      NetworkErrorHandler.handleError(
        e,
        defaultMessage: 'Unable to release ZIP code. Please check your internet connection and try again.',
      );
    } finally {
      _processingZipCodes.remove(zipCode.zipCode);
      _isLoading.value = false;
    }
  }

  bool isZipProcessing(String zipCode) =>
      _processingZipCodes.contains(zipCode);

  /// Converts full state name (e.g., "California") to state code (e.g., "CA")
  String _getStateCodeFromName(String name) {
    final stateMap = {
      'Alabama': 'AL',
      'Alaska': 'AK',
      'Arizona': 'AZ',
      'Arkansas': 'AR',
      'California': 'CA',
      'Colorado': 'CO',
      'Connecticut': 'CT',
      'Delaware': 'DE',
      'Florida': 'FL',
      'Georgia': 'GA',
      'Hawaii': 'HI',
      'Idaho': 'ID',
      'Illinois': 'IL',
      'Indiana': 'IN',
      'Iowa': 'IA',
      'Kansas': 'KS',
      'Kentucky': 'KY',
      'Louisiana': 'LA',
      'Maine': 'ME',
      'Maryland': 'MD',
      'Massachusetts': 'MA',
      'Michigan': 'MI',
      'Minnesota': 'MN',
      'Mississippi': 'MS',
      'Missouri': 'MO',
      'Montana': 'MT',
      'Nebraska': 'NE',
      'Nevada': 'NV',
      'New Hampshire': 'NH',
      'New Jersey': 'NJ',
      'New Mexico': 'NM',
      'New York': 'NY',
      'North Carolina': 'NC',
      'North Dakota': 'ND',
      'Ohio': 'OH',
      'Oklahoma': 'OK',
      'Oregon': 'OR',
      'Pennsylvania': 'PA',
      'Rhode Island': 'RI',
      'South Carolina': 'SC',
      'South Dakota': 'SD',
      'Tennessee': 'TN',
      'Texas': 'TX',
      'Utah': 'UT',
      'Vermont': 'VT',
      'Virginia': 'VA',
      'Washington': 'WA',
      'West Virginia': 'WV',
      'Wisconsin': 'WI',
      'Wyoming': 'WY',
    };
    // If already a code (2 letters), return as is
    if (name.length == 2 && name == name.toUpperCase()) {
      return name;
    }
    // Otherwise, try to find the code from the name
    return stateMap[name] ?? name;
  }

  /// Sets the selected state and fetches ZIP codes for that state
  /// [stateName] can be either full state name (e.g., "Alabama") or state code (e.g., "AL")
  Future<void> selectStateAndFetchZipCodes(String stateName) async {
    if (stateName.isEmpty) {
      _selectedState.value = null;
      _availableZipCodes.clear();
      // Clear saved state from storage
      _storage.remove(_selectedStateStorageKey);
      return;
    }

    // Only fetch if state actually changed
    if (_selectedState.value == stateName) {
      // State hasn't changed, don't refetch (will use cache if available)
      return;
    }

    _selectedState.value = stateName;
    // Save selected state to storage for persistence
    _storage.write(_selectedStateStorageKey, stateName);
    
    // Convert state name to code for API call
    // Load from cache first (instant), then refresh in background if needed
    final stateCode = _getStateCodeFromName(stateName);
    await _loadZipCodesFromCache(stateCode);
    // Fetch from API in background (will use cache if valid, otherwise fetch)
    await fetchZipCodesForState(stateCode, forceRefresh: false);
  }

  /// Fetches ZIP codes from API for the selected state
  /// [forceRefresh] if true, will skip cache and fetch from API
  Future<void> fetchZipCodesForState(String stateCode, {bool forceRefresh = false}) async {
    if (stateCode.isEmpty) return;

    // Check cache first unless force refresh is requested
    if (!forceRefresh) {
      final cacheKey = '$_zipCodesCachePrefix$stateCode';
      final timestampKey = '$_zipCodesCacheTimestampPrefix$stateCode';

      final cachedData = _storage.read(cacheKey) as List<dynamic>?;
      final cachedTimestamp = _storage.read(timestampKey) as String?;

      if (cachedData != null && cachedTimestamp != null && cachedData.isNotEmpty) {
        final cacheTime = DateTime.parse(cachedTimestamp);
        final now = DateTime.now();

        // Check if cache is still valid (not expired)
        if (now.difference(cacheTime) < _cacheExpirationDuration) {
          // Load from cache - instant, no API call
          await _loadZipCodesFromCache(stateCode);
          if (kDebugMode) {
            print('✅ Using cached ZIP codes for $stateCode (instant load)');
          }
          return;
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ ZIP code cache empty for $stateCode – fetching from API');
        }
      }
    }

    // Cache miss or expired, fetch from API
    try {
      _isLoadingZipCodes.value = true;

      if (kDebugMode) {
        print('📡 Fetching ZIP codes from API for state: $stateCode');
      }

      final zipCodesService = ZipCodesService();
      final zipCodes = await zipCodesService.getZipCodesByState(state: stateCode);

      // Save to cache
      _saveZipCodesToCache(stateCode, zipCodes);

      // Filter out already claimed ZIP codes
      final claimedZipCodesSet = _claimedZipCodes.map((z) => z.zipCode).toSet();
      final availableZips = zipCodes
          .where((zip) => !claimedZipCodesSet.contains(zip.zipCode))
          .toList();

      _availableZipCodes.value = availableZips;

      if (kDebugMode) {
        print('✅ Loaded ${availableZips.length} available ZIP codes for $stateCode');
      }
    } on ZipCodesServiceException catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching ZIP codes: ${e.message}');
      }
      // Try to load from cache even if expired as fallback
      await _loadZipCodesFromCache(stateCode);
      if (_availableZipCodes.isEmpty) {
        Get.snackbar('Error', 'Failed to fetch ZIP codes: ${e.message}');
        _availableZipCodes.clear();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error fetching ZIP codes: $e');
      }
      // Try to load from cache even if expired as fallback
      await _loadZipCodesFromCache(stateCode);
      if (_availableZipCodes.isEmpty) {
        Get.snackbar('Error', 'Failed to fetch ZIP codes: ${e.toString()}');
        _availableZipCodes.clear();
      }
    } finally {
      _isLoadingZipCodes.value = false;
    }
  }

  Future<void> searchZipCodes(String query) async {
    // If no state is selected, show message
    if (_selectedState.value == null) {
      return;
    }

    try {
      // Filter available ZIP codes by query
      if (query.isEmpty) {
        // If query is empty, reload ZIP codes for selected state (from cache)
        if (_selectedState.value != null) {
          final stateCode = _getStateCodeFromName(_selectedState.value!);
          await fetchZipCodesForState(stateCode, forceRefresh: false);
        }
        return;
      }

      final filteredZips = _availableZipCodes
          .where(
            (zip) =>
                zip.zipCode.contains(query) ||
                zip.state.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      _availableZipCodes.value = filteredZips;
    } catch (e) {
      NetworkErrorHandler.handleError(
        e,
        defaultMessage: 'Unable to search ZIP codes. Please check your internet connection and try again.',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void notifyMeWhenAvailable(String zipCode) {
    Get.snackbar(
      'Notification Set',
      'You will be notified when ZIP code $zipCode becomes available',
    );
  }

  double calculateMonthlyCost() {
    // Calculate base cost from ZIP codes using population-based pricing tiers
    final zipCodeCost = ZipCodePricingService.calculateTotalMonthlyPrice(
      _claimedZipCodes,
    );

    // If subscription has promo, apply discount
    if (_subscription.value?.isPromoActive == true &&
        _subscription.value?.activePromoCode != null) {
      final promo = _subscription.value!.activePromoCode!;
      if (promo.type == PromoCodeType.agent70Off &&
          promo.discountPercent != null) {
        // Apply 70% discount
        return zipCodeCost * (1 - (promo.discountPercent! / 100));
      }
    }

    return zipCodeCost;
  }

  double getStandardMonthlyPrice() {
    return standardMonthlyPrice;
  }

  /// Update subscription base price based on claimed zip codes
  void _updateSubscriptionPrice() {
    if (_subscription.value == null) return;

    // Calculate new base price from claimed zip codes using population-based pricing
    final newBasePrice = ZipCodePricingService.calculateTotalMonthlyPrice(
      _claimedZipCodes,
    );

    // If no zip codes claimed, use fallback price
    final basePrice = newBasePrice > 0 ? newBasePrice : standardMonthlyPrice;

    // Calculate current price (apply promo discount if active)
    double currentPrice = basePrice;
    if (_subscription.value!.isPromoActive &&
        _subscription.value!.activePromoCode != null) {
      final promo = _subscription.value!.activePromoCode!;
      if (promo.type == PromoCodeType.agent70Off &&
          promo.discountPercent != null) {
        currentPrice = basePrice * (1 - (promo.discountPercent! / 100));
      }
    }

    _subscription.value = _subscription.value!.copyWith(
      baseMonthlyPrice: basePrice,
      currentMonthlyPrice: currentPrice,
      updatedAt: DateTime.now(),
    );
  }

  // Promo Code Methods
  Future<void> applyPromoCode(String code) async {
    try {
      _isLoading.value = true;

      // Validate promo code
      final promoCode = await _validatePromoCode(code);

      if (promoCode == null) {
        Get.snackbar('Error', 'Invalid or expired promo code');
        return;
      }

      if (promoCode.type != PromoCodeType.agent70Off) {
        Get.snackbar('Error', 'This promo code is not valid for agents');
        return;
      }

      // Check if promo is still valid (not expired, within 1 year limit)
      if (!promoCode.isValid) {
        Get.snackbar(
          'Error',
          'This promo code has expired or reached its usage limit',
        );
        return;
      }

      // Calculate expiration date (1 year from now)
      final expiresAt = DateTime.now().add(const Duration(days: 365));

      // Apply promo to subscription
      final currentSub = _subscription.value!;

      // Ensure base price is up to date before applying promo
      final basePrice = ZipCodePricingService.calculateTotalMonthlyPrice(
        _claimedZipCodes,
      );
      final finalBasePrice = basePrice > 0 ? basePrice : standardMonthlyPrice;
      final discountedPrice = finalBasePrice * 0.3; // 70% off = 30% of original

      _subscription.value = currentSub.copyWith(
        status: SubscriptionStatus.promo,
        activePromoCode: promoCode,
        promoExpiresAt: expiresAt,
        isPromoActive: true,
        baseMonthlyPrice: finalBasePrice, // Update base price from zip codes
        currentMonthlyPrice: discountedPrice,
        updatedAt: DateTime.now(),
      );

      // Mark promo code as used
      // TODO: Save to backend
      // await _dio.post('/subscription/apply-promo', data: {
      //   'promoCode': promoCode.code,
      //   'userId': currentSub.userId,
      //   'usedAt': DateTime.now().toIso8601String(),
      // });

      _promoCodeInput.value = '';

      Get.snackbar(
        'Success',
        'Promo code applied! You now have 70% off for up to 1 year.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      NetworkErrorHandler.handleError(
        e,
        defaultMessage: 'Unable to apply promo code. Please check your internet connection and try again.',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<PromoCodeModel?> _validatePromoCode(String code) async {
    // Simulate API call - in production, this would validate against backend
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock validation - check if code matches format and is valid
    // In production, this would be an API call
    if (code.isEmpty) return null;

    // For now, accept any code starting with "AGENT70" as valid
    // In production, this would check against database
    if (code.toUpperCase().startsWith('AGENT70') ||
        code.toUpperCase().startsWith('AGENT')) {
      return PromoCodeModel(
        id: 'promo_${DateTime.now().millisecondsSinceEpoch}',
        code: code.toUpperCase(),
        type: PromoCodeType.agent70Off,
        status: PromoCodeStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 365)),
        discountPercent: 70.0,
        description: '70% Off for Agents',
      );
    }

    return null;
  }

  Future<void> generatePromoCodeForLoanOfficer() async {
    try {
      _isLoading.value = true;

      final authController = Get.find<global.AuthController>();
      final agentId = authController.currentUser?.id ?? 'agent_1';

      // Generate unique promo code
      final random = Random();
      final code =
          'LO${random.nextInt(9000) + 1000}${agentId.substring(0, 3).toUpperCase()}';

      final promoCode = PromoCodeModel(
        id: 'promo_${DateTime.now().millisecondsSinceEpoch}',
        code: code,
        type: PromoCodeType.loanOfficer6MonthsFree,
        status: PromoCodeStatus.active,
        createdBy: agentId,
        createdAt: DateTime.now(),
        expiresAt: null, // No expiration for agent-generated codes
        maxUses: 1, // Single use per loan officer
        currentUses: 0,
        freeMonths: 6,
        description: '6 Months Free for Loan Officers',
      );

      _generatedPromoCodes.add(promoCode);

      // TODO: Save to backend
      // await _dio.post('/promo-codes/generate', data: promoCode.toJson());

      Get.snackbar(
        'Success',
        'Promo code generated: $code\nShare this with loan officers for 6 months free!',
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      NetworkErrorHandler.handleError(
        e,
        defaultMessage: 'Unable to generate promo code. Please check your internet connection and try again.',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> cancelSubscription() async {
    try {
      _isLoading.value = true;

      final currentSub = _subscription.value;
      if (currentSub == null) {
        Get.snackbar('Error', 'No active subscription found');
        return;
      }

      if (currentSub.isCancelled) {
        Get.snackbar('Info', 'Subscription is already cancelled');
        return;
      }

      // Calculate cancellation effective date (30 days from now)
      final cancellationDate = DateTime.now();
      final effectiveDate = cancellationDate.add(const Duration(days: 30));

      _subscription.value = currentSub.copyWith(
        status: SubscriptionStatus.cancelled,
        cancellationDate: cancellationDate,
        cancellationEffectiveDate: effectiveDate,
        updatedAt: DateTime.now(),
      );

      // TODO: Save to backend
      // await _dio.post('/subscription/cancel', data: {...});

      Get.snackbar(
        'Success',
        'Subscription will be cancelled on ${effectiveDate.toString().split(' ')[0]}. You will continue to have access until then.',
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel subscription: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  void setPromoCodeInput(String value) {
    _promoCodeInput.value = value;
  }

  void checkPromoExpiration() {
    final sub = _subscription.value;
    if (sub?.isPromoActive == true && sub?.promoExpiresAt != null) {
      if (DateTime.now().isAfter(sub!.promoExpiresAt!)) {
        // Promo expired, revert to normal pricing
        _subscription.value = sub.copyWith(
          status: SubscriptionStatus.active,
          isPromoActive: false,
          activePromoCode: null,
          currentMonthlyPrice: sub.baseMonthlyPrice,
          promoExpiresAt: null,
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  List<Map<String, dynamic>> getStatsData() {
    return [
      {'label': 'Searches', 'value': searchesAppearedIn, 'icon': Icons.search},
      {
        'label': 'Profile Views',
        'value': profileViews,
        'icon': Icons.visibility,
      },
      {'label': 'Contacts', 'value': contacts, 'icon': Icons.phone},
      {'label': 'Revenue', 'value': totalRevenue, 'icon': Icons.attach_money},
    ];
  }

  // Listing Management Methods
  Future<void> addListing(AgentListingModel listing) async {
    try {
      _isLoading.value = true;

      // Check if agent can add more listings
      // Note: Agents can always add listings for $9.99 per listing, even without subscription
      // The free limit only applies to the first 3 listings
      if (!canAddFreeListing) {
        // This case shouldn't block adding listings, but we'll show info
        // The UI will handle showing the purchase option
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Add new listing
      _myListings.add(listing);

      Get.snackbar(
        'Success',
        'Listing added successfully! It will be reviewed before going live.',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to add listing: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateListing(AgentListingModel listing) async {
    try {
      _isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Update listing
      final index = _myListings.indexWhere((l) => l.id == listing.id);
      if (index != -1) {
        _myListings[index] = listing;
        Get.snackbar('Success', 'Listing updated successfully!');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update listing: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteListing(String listingId) async {
    try {
      _isLoading.value = true;

      // Get auth token from storage
      final authToken = _storage.read('auth_token');

      print('🚀 Deleting listing with ID: $listingId');
      print('📡 API Endpoint: $_baseUrl/buyer/delete/$listingId');

      // Make API call to delete listing with listing ID as path parameter
      final response = await _dio.delete(
        '/buyer/delete/$listingId',
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      // Handle successful response
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        print(
          '✅ SUCCESS - Listing deleted. Status Code: ${response.statusCode}',
        );
        print('📥 Response Data:');
        print(response.data);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Remove listing from local list
        _allListings.removeWhere((listing) => listing.id == listingId);
        
        // Apply filters to update displayed listings
        _applyFilters();

        Get.snackbar(
          'Success',
          'Listing deleted successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh listings from API to ensure consistency
        await fetchAgentListings();
      }
    } on DioException catch (e) {
      // Handle Dio errors
      print('❌ ERROR - Status Code: ${e.response?.statusCode ?? "N/A"}');
      print('📥 Error Response:');
      print(e.response?.data ?? e.message);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      String errorMessage = 'Failed to delete listing. Please try again.';

      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Listing not found. It may have already been deleted.';
          // Still remove from local list if 404 and refresh
          _allListings.removeWhere((listing) => listing.id == listingId);
          _applyFilters();
          await fetchAgentListings();
        } else if (e.response?.statusCode == 403) {
          errorMessage = 'You do not have permission to delete this listing.';
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
      print('❌ Unexpected Error: ${e.toString()}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      Get.snackbar('Error', 'Failed to delete listing: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> toggleListingStatus(String listingId) async {
    try {
      _isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Toggle listing status
      final index = _allListings.indexWhere((l) => l.id == listingId);
      if (index != -1) {
        final listing = _allListings[index];
        _allListings[index] = listing.copyWith(
          isActive: !listing.isActive,
          updatedAt: DateTime.now(),
        );

        final status = _allListings[index].isActive
            ? 'activated'
            : 'deactivated';
        Get.snackbar('Success', 'Listing $status successfully!');

        // Apply filters to update displayed listings
        _applyFilters();
        
        // Refresh listings from API
        await fetchAgentListings();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update listing status: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> purchaseAdditionalListing() async {
    try {
      _isLoading.value = true;

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // In a real app, this would process payment for a new listing
      // The $9.99 fee covers the listing until it sells (one-time fee)
      Get.snackbar(
        'Success',
        'Listing payment processed! You can now add your listing. This one-time fee covers your listing until it sells.',
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process listing payment: ${e.toString()}',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Legacy method name for backwards compatibility
  Future<void> purchaseAdditionalListingSlot() async {
    return purchaseAdditionalListing();
  }

  // Listing stats
  int get totalListingViews =>
      _myListings.fold(0, (sum, listing) => sum + listing.viewCount);
  int get totalListingContacts =>
      _myListings.fold(0, (sum, listing) => sum + listing.contactCount);
  int get totalListingSearches =>
      _myListings.fold(0, (sum, listing) => sum + listing.searchCount);
  int get activeListingsCount =>
      _allListings.where((l) => l.marketStatus == MarketStatus.forSale).length;
  int get pendingListingsCount =>
      _allListings.where((l) => l.marketStatus == MarketStatus.pending).length;
  int get soldListingsCount =>
      _allListings.where((l) => l.marketStatus == MarketStatus.sold).length;
  int get staleListingsCount => _allListings.where((l) => l.isStale).length;

  // Fetch listings from API
  Future<void> fetchAgentListings() async {
    try {
      // Don't show global loading indicator - let listings load in background
      // Each screen can show its own loading indicator if needed
      if (kDebugMode) {
        print('🚀 Fetching agent listings in background...');
      }

      // Get agent ID from AuthController
      final authController = Get.find<global.AuthController>();
      final agentId = authController.currentUser?.id;

      if (agentId == null || agentId.isEmpty) {
        print('⚠️ No agent ID found. Cannot fetch listings.');
        // Don't show snackbar on initial load - just fail silently
        return;
      }

      print('🚀 Fetching listings for agent ID: $agentId');
      print('📡 API Endpoint: $_baseUrl/agent/getListingByAgentId/$agentId');

      // Make API call
      final response = await _dio.get(
        '/agent/getListingByAgentId/$agentId',
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
          },
        ),
      );

      // Handle successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ SUCCESS - Status Code: ${response.statusCode}');
        print('📥 Response Data:');
        print(response.data);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        final responseData = response.data;
        final success = responseData['success'] ?? false;
        final listingsData = responseData['listings'] as List<dynamic>? ?? [];

        if (success && listingsData.isNotEmpty) {
          // Parse listings from API response
          // First, update photo URLs with base URL before parsing
          final baseUrl = ApiConstants.baseUrl;
          final listings = listingsData
              .map((listingJson) {
                final listingMap = Map<String, dynamic>.from(listingJson as Map<String, dynamic>);
                
                // Update propertyPhotos URLs with base URL
                if (listingMap['propertyPhotos'] != null) {
                  final photos = listingMap['propertyPhotos'] as List<dynamic>;
                  listingMap['propertyPhotos'] = photos.map((photo) {
                    final photoPath = photo.toString();
                    if (photoPath.isEmpty) return photo;
                    
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
                  }).toList();
                }
                
                return AgentListingModel.fromApiJson(listingMap);
              })
              .toList();

          _allListings.value = listings;
          _applyFilters(); // Apply current filters
          print('✅ Loaded ${listings.length} listings from API');
        } else {
          // No listings found
          _allListings.value = [];
          _myListings.value = [];
          print('ℹ️ No listings found for this agent');
        }
      }
    } on DioException catch (e) {
      // Handle Dio errors
      print('❌ ERROR - Status Code: ${e.response?.statusCode ?? "N/A"}');
      print('📥 Error Response:');
      print(e.response?.data ?? e.message);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (e.response != null) {
        if (e.response?.statusCode == 404) {
          // 404 is okay - just means no listings found
          _myListings.value = [];
          print('ℹ️ No listings found (404)');
          return;
        }
      }

      // Don't show error snackbar on initial background load
      // Only log to console
      if (kDebugMode && e.response?.statusCode != 404) {
        print('⚠️ Failed to fetch listings on initial load (will retry later)');
      }
    } catch (e) {
      print('❌ Unexpected Error: ${e.toString()}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // Don't show snackbar on initial background load
    } finally {
      if (kDebugMode) {
        print('✅ Background listing fetch complete');
      }
    }
  }

  /// Fetches leads for the current agent
  Future<void> fetchLeads() async {
    // Prevent multiple simultaneous calls
    if (_isLoadingLeads.value) {
      if (kDebugMode) {
        print('⚠️ Leads already loading, skipping duplicate call');
      }
      return;
    }

    final authController = Get.find<global.AuthController>();
    final user = authController.currentUser;
    if (user == null || user.id.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Cannot fetch leads: User not logged in');
      }
      return;
    }

    _isLoadingLeads.value = true;

    try {
      if (kDebugMode) {
        print('📡 Fetching leads for agent: ${user.id}');
      }

      final leadsService = LeadsService();
      final response = await leadsService.getLeadsByAgentId(user.id);

      _leads.value = response.leads;

      if (kDebugMode) {
        print('✅ Fetched ${response.leads.length} leads');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching leads: $e');
      }
      // Don't show error snackbar on initial background load
    } finally {
      _isLoadingLeads.value = false;
    }
  }

  /// Refreshes leads (called when user switches to leads tab or manually refreshes)
  Future<void> refreshLeads() async {
    await fetchLeads();
  }

  /// Contacts a buyer from a lead
  Future<void> contactBuyerFromLead(LeadModel lead) async {
    final buyerInfo = lead.buyerInfo;
    if (buyerInfo == null) {
      Get.snackbar('Error', 'Buyer information not available');
      return;
    }

    // Get or create messages controller
    if (!Get.isRegistered<MessagesController>()) {
      Get.put(MessagesController(), permanent: true);
    }
    final messagesController = Get.find<MessagesController>();

    // Start chat with buyer - navigate directly to messages without replacing stack
    // Start chat with buyer - navigate directly to messages without replacing stack
    await messagesController.startChatWithUser(
      otherUserId: buyerInfo.id,
      otherUserName: buyerInfo.fullname ?? 'Buyer',
      otherUserProfilePic: buyerInfo.profilePic,
      otherUserRole: buyerInfo.role ?? 'user',
      navigateToMessages: false, // Don't use _navigateToMessages which replaces stack
    );
  }
}

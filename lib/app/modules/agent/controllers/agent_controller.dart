import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart' as dio show FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/widgets/payment_web_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:io';
import 'dart:convert';

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
  final _allListings =
      <AgentListingModel>[].obs; // All listings from API (unfiltered)
  final _leads = <LeadModel>[].obs;
  final _isLoading = false.obs;
  final _isLoadingLeads = false.obs;
  final _selectedTab = 0
      .obs; // 0: Dashboard, 1: ZIP Management, 2: My Listings, 3: Stats, 4: Billing, 5: Leads
  final _recentlyActivatedListingId = Rxn<String>();

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
  final _subscriptions =
      <Map<String, dynamic>>[].obs; // Payment history subscriptions

  // Track per-ZIP claim/release operations for individual button loaders
  final RxSet<String> _processingZipCodes = <String>{}.obs;

  // State selection for ZIP codes
  final _selectedState = Rxn<String>();
  final _isLoadingZipCodes = false.obs;
  static const String _selectedStateStorageKey = 'agent_selected_state';
  static const String _zipCodesCachePrefix = 'agent_zip_codes_cache_';
  static const String _zipCodesCacheTimestampPrefix =
      'agent_zip_codes_timestamp_';
  static const Duration _cacheExpirationDuration = Duration(hours: 24);
  static const String _claimedZipCodesStorageKey = 'agent_claimed_zip_codes';

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
  String? get recentlyActivatedListingId => _recentlyActivatedListingId.value;
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
      filtered = filtered
          .where(
            (listing) => listing.marketStatus == _selectedStatusFilter.value,
          )
          .toList();
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

  void _markListingRecentlyActivated(String listingId) {
    _recentlyActivatedListingId.value = listingId;
    Future.delayed(const Duration(seconds: 3), () {
      if (_recentlyActivatedListingId.value == listingId) {
        _recentlyActivatedListingId.value = null;
      }
    });
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
  List<Map<String, dynamic>> get subscriptions => _subscriptions;

  // Get active (non-canceled) subscriptions from API data
  List<Map<String, dynamic>> get activeSubscriptions {
    if (_subscriptions.isEmpty) return [];

    return _subscriptions.where((sub) {
      final status = sub['subscriptionStatus']?.toString().toLowerCase() ?? '';
      // Include active, paid, trialing subscriptions, exclude canceled/cancelled
      return status != 'canceled' && status != 'cancelled' && status.isNotEmpty;
    }).toList();
  }

  /// Get the active subscription from API (not canceled/cancelled)
  Map<String, dynamic>? get activeSubscriptionFromAPI {
    if (_subscriptions.isEmpty) return null;

    // Find the most recent subscription that is not canceled/cancelled
    for (final sub in _subscriptions) {
      final status = sub['subscriptionStatus']?.toString().toLowerCase() ?? '';
      if (status != 'canceled' && status != 'cancelled') {
        return sub;
      }
    }

    // If all are canceled, return the most recent one
    return _subscriptions.isNotEmpty ? _subscriptions.first : null;
  }

  // Listing limits
  int get freeListingLimit => 3;
  int get currentListingCount =>
      _allListings.length; // Use allListings for count
  int get remainingFreeListings =>
      (freeListingLimit - currentListingCount).clamp(0, freeListingLimit);
  bool get canAddFreeListing => remainingFreeListings > 0;
  double get additionalListingPrice => 9.99;

  @override
  void onInit() {
    super.onInit();
    _setupDio();
    _restoreClaimedZipCodesFromStorage();
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
      Future.microtask(
        () => fetchZipCodesForState(stateCode, forceRefresh: false),
      );
    }
  }

  Future<void> _restoreClaimedZipCodesFromStorage() async {
    try {
      final storedData =
          _storage.read(_claimedZipCodesStorageKey) as List<dynamic>?;
      if (storedData == null || storedData.isEmpty) {
        return;
      }

      final cachedZips = storedData
          .map((json) => ZipCodeModel.fromJson(json as Map<String, dynamic>))
          .toList();

      _claimedZipCodes
        ..clear()
        ..addAll(cachedZips);

      if (kDebugMode) {
        print(
          '💾 Restored ${_claimedZipCodes.length} claimed ZIP codes from storage',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to restore claimed ZIP codes from storage: $e');
      }
    }
  }

  /// Loads ZIP codes from cache for the given state
  Future<List<ZipCodeModel>?> _loadZipCodesFromCache(String stateCode) async {
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
              .map(
                (json) => ZipCodeModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();

          // Filter out invalid ZIP codes (zero population / already claimed)
          final availableZips = _filterAvailableZipCodes(zipCodes);
          _availableZipCodes.value = availableZips;

          if (kDebugMode) {
            print(
              '✅ Loaded ${availableZips.length} ZIP codes from cache for $stateCode',
            );
          }
          return availableZips;
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

    return null;
  }

  void _persistClaimedZipCodesToStorage() {
    try {
      final jsonData = _claimedZipCodes.map((zip) => zip.toJson()).toList();
      _storage.write(_claimedZipCodesStorageKey, jsonData);
      if (kDebugMode) {
        print('💾 Persisted ${jsonData.length} claimed ZIP codes to storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to persist claimed ZIP codes to storage: $e');
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

  List<ZipCodeModel> _filterAvailableZipCodes(List<ZipCodeModel> zipCodes) {
    final claimedZipCodesSet = _claimedZipCodes.map((z) => z.zipCode).toSet();
    return zipCodes
        .where(
          (zip) =>
              zip.population > 0 && !claimedZipCodesSet.contains(zip.zipCode),
        )
        .toList();
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
          print(
            '🚀 Agent: Preloading chat threads and ensuring socket connection...',
          );
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

    // Refresh user stats (including subscriptions) when "Billing" tab is selected
    if (index == 4) {
      Future.microtask(() => fetchUserStats());
    }

    // Always refresh leads when switching to leads tab to get latest data
    // Fetch even if already on tab 5 (in case data needs refresh)
    if (index == 5 && !_isLoadingLeads.value) {
      // Fetch leads every time user visits the leads tab
      Future.microtask(() => refreshLeads());
    }
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
        _searchesAppearedIn.value =
            (userData['searches'] as num?)?.toInt() ?? 0;
        _profileViews.value = (userData['views'] as num?)?.toInt() ?? 0;
        _contacts.value = (userData['contacts'] as num?)?.toInt() ?? 0;
        _websiteClicks.value =
            (userData['websiteclicks'] as num?)?.toInt() ?? 0;
        _totalRevenue.value = (userData['revenue'] as num?)?.toDouble() ?? 0.0;

        // Extract claimed ZIP codes from user profile (if present)
        final claimedZipCodesData =
            userData['claimedZipCodes'] as List<dynamic>? ?? [];
        if (claimedZipCodesData.isNotEmpty) {
          if (kDebugMode) {
            print(
              '📦 Loading claimed ZIP codes from user profile '
              '(${claimedZipCodesData.length} items)',
            );
          }

          final claimedZips = claimedZipCodesData
              .whereType<Map<String, dynamic>>()
              .map((zipJson) {
                final zipCode = zipJson['postalCode']?.toString() ?? '';
                if (zipCode.isEmpty) return null;

                return ZipCodeModel(
                  zipCode: zipCode,
                  state: zipJson['state']?.toString() ?? '',
                  population: (zipJson['population'] as num?)?.toInt() ?? 0,
                  price: (zipJson['price'] as num?)?.toDouble(),
                  claimedByAgent: true,
                  claimedAt:
                      DateTime.tryParse(
                        zipJson['claimedAt']?.toString() ?? '',
                      ) ??
                      DateTime.now(),
                  isAvailable: false,
                  createdAt:
                      DateTime.tryParse(
                        zipJson['createdAt']?.toString() ?? '',
                      ) ??
                      DateTime.now(),
                  searchCount: (zipJson['searchCount'] as num?)?.toInt() ?? 0,
                );
              })
              .whereType<ZipCodeModel>()
              .toList();

          // Replace local claimed ZIP codes with those from API
          _claimedZipCodes
            ..clear()
            ..addAll(claimedZips);
          _persistClaimedZipCodesToStorage();
          if (kDebugMode) {
            print(
              '✅ Claimed ZIP codes synced from API: '
              '${_claimedZipCodes.length} items',
            );
          }
        } else {
          _claimedZipCodes.clear();
          _persistClaimedZipCodesToStorage();
        }

        // Extract subscriptions from user profile (if present)
        final subscriptionsData =
            userData['subscriptions'] as List<dynamic>? ?? [];
        if (subscriptionsData.isNotEmpty) {
          if (kDebugMode) {
            print(
              '📦 Loading subscriptions from user profile '
              '(${subscriptionsData.length} items)',
            );
          }

          final subscriptions = subscriptionsData
              .whereType<Map<String, dynamic>>()
              .map(
                (subJson) => {
                  'stripeCustomerId': subJson['stripeCustomerId']?.toString(),
                  'stripeSubscriptionId': subJson['stripeSubscriptionId']
                      ?.toString(),
                  'subscriptionStatus':
                      subJson['subscriptionStatus']?.toString() ?? '',
                  'subscriptionRole': subJson['subscriptionRole']?.toString(),
                  'subscriptionTier': subJson['subscriptionTier']?.toString(),
                  'population': (subJson['population'] as num?)?.toInt(),
                  'subscriptionStart': subJson['subscriptionStart']?.toString(),
                  'subscriptionEnd': subJson['subscriptionEnd']?.toString(),
                  'priceId': subJson['priceId']?.toString(),
                  'amountPaid': (subJson['amountPaid'] as num?)?.toDouble(),
                  'createdAt': subJson['createdAt']?.toString(),
                  '_id': subJson['_id']?.toString(),
                },
              )
              .toList();

          // Sort by createdAt descending (most recent first)
          subscriptions.sort((a, b) {
            final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '');
            final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '');
            if (dateA == null || dateB == null) return 0;
            return dateB.compareTo(dateA);
          });

          _subscriptions.value = subscriptions;

          if (kDebugMode) {
            print(
              '✅ Subscriptions synced from API: '
              '${_subscriptions.length} items',
            );
          }
        } else {
          // Clear subscriptions if none found
          _subscriptions.clear();
        }

        if (kDebugMode) {
          print('✅ User stats fetched and updated successfully:');
          print('   Searches: ${_searchesAppearedIn.value}');
          print('   Views: ${_profileViews.value}');
          print('   Contacts: ${_contacts.value}');
          print('   Website Clicks: ${_websiteClicks.value}');
          print('   Revenue: ${_totalRevenue.value}');
          print('   Subscriptions: ${_subscriptions.length}');
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

  /// Initiates ZIP code payment flow
  /// First creates a checkout session, then shows payment web view
  Future<void> claimZipCode(ZipCodeModel zipCode) async {
    try {
      if (_processingZipCodes.contains(zipCode.zipCode)) return;
      _processingZipCodes.add(zipCode.zipCode);

      // Check if agent can claim more ZIP codes (max 6)
      if (_claimedZipCodes.length >= 6) {
        _showSnackbarSafely(
          'You can only claim up to 6 ZIP codes',
          isError: true,
        );
        _processingZipCodes.remove(zipCode.zipCode);
        return;
      }

      // Check if ZIP code is already claimed locally
      final isAlreadyClaimedLocally = _claimedZipCodes.any(
        (zip) => zip.zipCode == zipCode.zipCode,
      );
      if (isAlreadyClaimedLocally) {
        _showSnackbarSafely(
          'This ZIP code is already claimed by you.',
          isError: true,
        );
        _processingZipCodes.remove(zipCode.zipCode);
        return;
      }

      // Get auth token from storage
      final authToken = _storage.read('auth_token');
      final authController = Get.find<global.AuthController>();
      final userId = authController.currentUser?.id;

      if (userId == null || userId.isEmpty) {
        _showSnackbarSafely(
          'User not authenticated. Please login again.',
          isError: true,
        );
        _processingZipCodes.remove(zipCode.zipCode);
        return;
      }

      // Step 1: Create checkout session
      final zipCodePrice = zipCode.calculatedPrice.toStringAsFixed(2);

      // Prepare request body
      final requestBody = {
        'role': 'agent',
        'population': zipCode.population.toString(),
        'userId': userId,
        'zipcode': zipCode.zipCode,
        'price': zipCodePrice,
        'state': zipCode.state,
      };

      if (kDebugMode) {
        print('💳 Creating checkout session for ZIP code: ${zipCode.zipCode}');
        print('   Population: ${zipCode.population}');
        print('   Price: $zipCodePrice');
        print('   State: ${zipCode.state}');
        print('   Request Body: $requestBody');
        print('   Endpoint: /subscription/create-checkout-session');
      }

      final checkoutResponse = await _dio.post(
        '/subscription/create-checkout-session',
        data: requestBody,
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (checkoutResponse.statusCode == 200) {
        final checkoutData = checkoutResponse.data;
        final checkoutUrl = checkoutData['url'] as String?;
        final checkoutSessionId = checkoutData['sessionId'] as String?;

        if (checkoutUrl == null || checkoutUrl.isEmpty) {
          throw Exception('Invalid checkout URL received from server');
        }

        // Extract checkout session ID from URL if not provided in response
        final sessionId =
            checkoutSessionId ?? _extractCheckoutSessionId(checkoutUrl);

        if (kDebugMode) {
          print('✅ Checkout session created: $checkoutUrl');
          print('   Checkout Session ID: $sessionId');
        }

        // Step 2: Open payment URL in in-app web view
        final paymentSuccess = await Get.to<bool>(
          () => PaymentWebView(checkoutUrl: checkoutUrl),
          fullscreenDialog: true,
        );

        // Step 3: If payment successful, call paymentSuccess API first, then claim the ZIP code
        if (paymentSuccess == true) {
          if (sessionId != null && sessionId.isNotEmpty) {
            // Call paymentSuccess API and wait for it to complete successfully
            final paymentSuccessResult = await _callPaymentSuccessAPI(
              sessionId,
              authToken,
            );
            if (!paymentSuccessResult) {
              SnackbarHelper.showError(
                'Payment verification failed. Please contact support.',
              );
              _processingZipCodes.remove(zipCode.zipCode);
              return;
            }
          } else {
            if (kDebugMode) {
              print(
                '⚠️ No checkout session ID found, skipping paymentSuccess API',
              );
            }
          }
          // After paymentSuccess API succeeds, claim the ZIP code
          await _completeZipCodeClaim(zipCode, userId, authToken);
        } else {
          SnackbarHelper.showError('Payment was cancelled or failed');
        }
      } else {
        throw Exception(
          'Failed to create checkout session: ${checkoutResponse.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Error in payment flow: ${e.message}');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
      }

      String errorMessage = 'Failed to initiate payment. Please try again.';
      bool isAlreadyClaimed = false;

      if (e.response != null) {
        final responseData = e.response?.data;

        // Try to extract error message from HTML response
        if (responseData is String && responseData.contains('Error:')) {
          final errorMatch = RegExp(r'Error: ([^<]+)').firstMatch(responseData);
          if (errorMatch != null) {
            errorMessage = errorMatch.group(1)?.trim() ?? errorMessage;
            // Decode HTML entities
            errorMessage = errorMessage
                .replaceAll('&#39;', "'")
                .replaceAll('&nbsp;', ' ')
                .replaceAll('<br>', '\n');

            // Provide user-friendly message for Stripe price errors
            if (errorMessage.contains('No such price')) {
              errorMessage =
                  'Payment configuration error. The selected price is not available in the payment system. Please contact support to resolve this issue.';
            }
          }
        } else if (responseData is Map) {
          if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          } else if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          }
        }

        // Check if ZIP code is already claimed
        final lowerErrorMessage = errorMessage.toLowerCase();
        if (lowerErrorMessage.contains('already claimed') ||
            lowerErrorMessage.contains('already claimed by another agent')) {
          isAlreadyClaimed = true;
          errorMessage = 'This ZIP code is already claimed by another agent.';
        }

        if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (e.response?.statusCode == 400) {
          // If already claimed, keep that message
          if (!isAlreadyClaimed) {
            // Keep the extracted error message if we got one, otherwise use generic
            if (errorMessage ==
                'Failed to initiate payment. Please try again.') {
              errorMessage =
                  'Invalid request. The payment could not be processed. Please contact support.';
            }
          }
        } else if (e.response?.statusCode == 500) {
          errorMessage =
              'Server error. Please try again later or contact support.';
        }
      }

      if (kDebugMode) {
        print('❌ Final error message to user: $errorMessage');
        print('   Is already claimed: $isAlreadyClaimed');
      }

      // Remove from available list if already claimed
      if (isAlreadyClaimed) {
        _availableZipCodes.removeWhere((zip) => zip.zipCode == zipCode.zipCode);
        _persistClaimedZipCodesToStorage();
      }

      // Show snackbar immediately with proper context handling
      _showSnackbarSafely(
        errorMessage,
        isError: !isAlreadyClaimed,
        isAlreadyClaimed: isAlreadyClaimed,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in claimZipCode: $e');
      }
      NetworkErrorHandler.handleError(
        e,
        defaultMessage:
            'Unable to process payment. Please check your internet connection and try again.',
      );
    } finally {
      _processingZipCodes.remove(zipCode.zipCode);
    }
  }

  /// Extracts checkout session ID from Stripe checkout URL
  String? _extractCheckoutSessionId(String checkoutUrl) {
    try {
      final uri = Uri.parse(checkoutUrl);
      final pathSegments = uri.pathSegments;

      // Look for segment starting with 'cs_' (checkout session)
      for (final segment in pathSegments) {
        if (segment.startsWith('cs_')) {
          return segment;
        }
      }

      // If not found in path, try extracting from URL string directly
      final regex = RegExp(r'cs_(test|live)_[A-Za-z0-9]+');
      final match = regex.firstMatch(checkoutUrl);
      if (match != null) {
        return match.group(0);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error extracting checkout session ID: $e');
      }
      return null;
    }
  }

  /// Calls the paymentSuccess API after successful payment
  /// Returns true if successful, false otherwise
  Future<bool> _callPaymentSuccessAPI(
    String checkoutSessionId,
    String? authToken,
  ) async {
    try {
      if (kDebugMode) {
        print('📡 Calling paymentSuccess API');
        print('   Checkout Session ID: $checkoutSessionId');
        print('   Endpoint: /subscription/paymentSuccess/$checkoutSessionId');
      }

      final response = await _dio.get(
        '/subscription/paymentSuccess/$checkoutSessionId',
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (kDebugMode) {
        print('📥 PaymentSuccess API response:');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if response indicates success
        final responseData = response.data;
        if (responseData is Map) {
          final success = responseData['success'] as bool? ?? true;
          if (success) {
            if (kDebugMode) {
              print('✅ PaymentSuccess API completed successfully');
            }
            return true;
          }
        } else {
          // If response is not a map, assume success for 200/201 status
          return true;
        }
      }

      if (kDebugMode) {
        print(
          '⚠️ PaymentSuccess API returned non-success status: ${response.statusCode}',
        );
      }
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Error calling paymentSuccess API:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Response: ${e.response?.data}');
        print('   Status Code: ${e.response?.statusCode}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error calling paymentSuccess API: $e');
      }
      return false;
    }
  }

  /// Completes the ZIP code claim after successful payment
  Future<void> _completeZipCodeClaim(
    ZipCodeModel zipCode,
    String userId,
    String? authToken,
  ) async {
    try {
      _isLoading.value = true;

      // Prepare request body according to API specification
      final formattedPrice = zipCode.calculatedPrice.toStringAsFixed(2);
      final requestBody = {
        'id': userId, // agent's Mongo user _id
        'zipcode': zipCode.zipCode,
        'price': formattedPrice,
        'state': zipCode.state,
        'population': zipCode.population.toString(),
      };

      if (kDebugMode) {
        print('📡 Claiming ZIP code after payment: ${zipCode.zipCode}');
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
          claimedByAgent: true,
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

        SnackbarHelper.showSuccess(
          'ZIP code ${zipCode.zipCode} claimed successfully!',
          title: 'Success',
        );
      } else {
        throw Exception('Failed to claim ZIP code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Error claiming ZIP code: ${e.message}');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
      }

      String errorMessage =
          'Payment successful but failed to claim ZIP code. Please contact support.';
      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map) {
          // Check for 'error' field first (as seen in logs)
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          } else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          }
        }

        // Handle "already claimed" error specifically
        final lowerErrorMessage = errorMessage.toLowerCase();
        if (e.response?.statusCode == 409 ||
            lowerErrorMessage.contains('already claimed') ||
            lowerErrorMessage.contains('already claimed by another agent')) {
          errorMessage =
              'This ZIP code is already claimed by another agent. Your payment was successful, but the ZIP code was claimed by someone else. Please contact support for a refund.';
        } else if (e.response?.statusCode == 400) {
          // For 400 errors, check if it's the "already claimed" message
          if (lowerErrorMessage.contains('already claimed') ||
              lowerErrorMessage.contains('already claimed by another agent')) {
            errorMessage =
                'This ZIP code is already claimed by another agent. Your payment was successful, but the ZIP code was claimed by someone else. Please contact support for a refund.';
          } else if (errorMessage ==
              'Payment successful but failed to claim ZIP code. Please contact support.') {
            errorMessage =
                'Invalid request. The ZIP code could not be claimed. Please contact support.';
          }
        }
      }

      // Determine if it's an "already claimed" error
      final isAlreadyClaimed = errorMessage.toLowerCase().contains(
        'already claimed',
      );

      // Remove from available list if already claimed
      if (isAlreadyClaimed) {
        _availableZipCodes.removeWhere((zip) => zip.zipCode == zipCode.zipCode);
      }

      // Show snackbar with proper context handling
      _showSnackbarSafely(
        errorMessage,
        isError: !isAlreadyClaimed,
        isAlreadyClaimed: isAlreadyClaimed,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in _completeZipCodeClaim: $e');
      }

      // Wait a bit to ensure context is available after navigation
      await Future.delayed(const Duration(milliseconds: 500));

      // Use Get.snackbar for better reliability after navigation
      Get.snackbar(
        'Error',
        'Payment successful but unable to claim ZIP code. Please contact support.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
      );
    } finally {
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
      final requestBody = {'id': userId, 'zipcode': zipCode.zipCode};

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
      _persistClaimedZipCodesToStorage();

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
        defaultMessage:
            'Unable to release ZIP code. Please check your internet connection and try again.',
      );
    } finally {
      _processingZipCodes.remove(zipCode.zipCode);
      _isLoading.value = false;
    }
  }

  bool isZipProcessing(String zipCode) => _processingZipCodes.contains(zipCode);

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

  /// Forces fetching ZIP codes from the API regardless of cache
  Future<void> refreshZipCodesFromApi() async {
    final stateName = _selectedState.value;
    if (stateName == null || stateName.isEmpty) return;

    final stateCode = _getStateCodeFromName(stateName);
    await fetchZipCodesForState(stateCode, forceRefresh: true);
  }

  /// Fetches ZIP codes from API for the selected state
  /// [forceRefresh] if true, will skip cache and fetch from API
  Future<void> fetchZipCodesForState(
    String stateCode, {
    bool forceRefresh = false,
  }) async {
    if (stateCode.isEmpty) return;

    // Check cache first unless force refresh is requested
    if (!forceRefresh) {
      final cacheKey = '$_zipCodesCachePrefix$stateCode';
      final timestampKey = '$_zipCodesCacheTimestampPrefix$stateCode';

      final cachedData = _storage.read(cacheKey) as List<dynamic>?;
      final cachedTimestamp = _storage.read(timestampKey) as String?;

      if (cachedData != null &&
          cachedTimestamp != null &&
          cachedData.isNotEmpty) {
        final cacheTime = DateTime.parse(cachedTimestamp);
        final now = DateTime.now();

        // Check if cache is still valid (not expired)
        if (now.difference(cacheTime) < _cacheExpirationDuration) {
          // Load from cache - instant, no API call (unless cache yields zero available entries)
          final availableFromCache = await _loadZipCodesFromCache(stateCode);
          if (availableFromCache != null && availableFromCache.isNotEmpty) {
            if (kDebugMode) {
              print('✅ Using cached ZIP codes for $stateCode (instant load)');
            }
            return;
          }
          if (kDebugMode) {
            print(
              'ℹ️ Cache had 0 available ZIP codes for $stateCode, fetching from API.',
            );
          }
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
      final authController = Get.find<global.AuthController>();
      final userId = authController.currentUser?.id ?? '';
      final zipCodes = await zipCodesService.getZipCodesByState(
        state: stateCode,
        userId: userId,
      );

      // Save to cache
      _saveZipCodesToCache(stateCode, zipCodes);

      // Filter out invalid ZIP codes (zero population / already claimed)
      final availableZips = _filterAvailableZipCodes(zipCodes);
      _availableZipCodes.value = availableZips;

      if (kDebugMode) {
        print(
          '✅ Loaded ${availableZips.length} available ZIP codes for $stateCode',
        );
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
        defaultMessage:
            'Unable to search ZIP codes. Please check your internet connection and try again.',
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
    // First, try to use amountPaid from active subscription in API
    final activeSub = activeSubscriptionFromAPI;
    if (activeSub != null) {
      final amountPaid = activeSub['amountPaid'] as double?;
      if (amountPaid != null && amountPaid > 0) {
        return amountPaid;
      }
    }

    // Fallback: Calculate base cost from ZIP codes using population-based pricing tiers
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
    // Try to get standard price from active subscription's amountPaid
    // This represents the base price before any discounts
    final activeSub = activeSubscriptionFromAPI;
    if (activeSub != null) {
      final amountPaid = activeSub['amountPaid'] as double?;
      if (amountPaid != null && amountPaid > 0) {
        // If there's a promo active, the amountPaid might already be discounted
        // So we calculate what the original price would be
        if (_subscription.value?.isPromoActive == true &&
            _subscription.value?.activePromoCode != null) {
          final promo = _subscription.value!.activePromoCode!;
          if (promo.type == PromoCodeType.agent70Off &&
              promo.discountPercent != null) {
            // Reverse calculate: if 70% off, then original = amountPaid / 0.3
            return amountPaid / (1 - (promo.discountPercent! / 100));
          }
        }
        // If no promo, amountPaid is the standard price
        return amountPaid;
      }
    }

    // Fallback: Calculate from ZIP codes
    final zipCodeCost = ZipCodePricingService.calculateTotalMonthlyPrice(
      _claimedZipCodes,
    );
    if (zipCodeCost > 0) {
      return zipCodeCost;
    }

    // Final fallback: use hardcoded price
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
        defaultMessage:
            'Unable to apply promo code. Please check your internet connection and try again.',
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
        defaultMessage:
            'Unable to generate promo code. Please check your internet connection and try again.',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cancels a specific subscription by stripeCustomerId
  Future<void> cancelSubscription([String? stripeCustomerId]) async {
    try {
      _isLoading.value = true;

      // If no stripeCustomerId provided, use active subscription
      String? customerId = stripeCustomerId;

      if (customerId == null || customerId.isEmpty) {
        // Get active subscription from API to get stripeCustomerId
        final activeSub = activeSubscriptionFromAPI;
        if (activeSub == null) {
          SnackbarHelper.showError('No active subscription found');
          return;
        }
        customerId = activeSub['stripeCustomerId']?.toString();
      }

      if (customerId == null || customerId.isEmpty) {
        SnackbarHelper.showError('Stripe customer ID not found');
        return;
      }

      // Find the subscription to check its status
      final subscription = _subscriptions.firstWhere(
        (sub) => sub['stripeCustomerId']?.toString() == customerId,
        orElse: () => <String, dynamic>{},
      );

      // Check if already cancelled
      final status =
          subscription['subscriptionStatus']?.toString().toLowerCase() ?? '';
      if (status == 'canceled' || status == 'cancelled') {
        SnackbarHelper.showError('Subscription is already cancelled');
        return;
      }

      if (kDebugMode) {
        print('📡 Cancelling subscription');
        print('   Stripe Customer ID: $customerId');
        print('   Endpoint: /subscription/cancelSubscription');
      }

      // Get auth token from storage
      final authToken = _storage.read('auth_token');

      // Call the cancel subscription API
      final response = await _dio.post(
        '/subscription/cancelSubscription',
        data: {'customerId': customerId},
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (kDebugMode) {
        print('📥 Cancel subscription response:');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final billingPortalUrl = responseData['url'] as String?;

        if (billingPortalUrl != null && billingPortalUrl.isNotEmpty) {
          if (kDebugMode) {
            print('🌐 Opening Stripe billing portal: $billingPortalUrl');
          }

          // Open billing portal in browser
          // TODO: Replace with proper WebView widget when PaymentWebView is implemented
          final uri = Uri.parse(billingPortalUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }

          // Refresh user stats after user completes cancellation in portal
          await fetchUserStats();

          // Show success message safely using post-frame callback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              SnackbarHelper.showSuccess(
                'Subscription cancellation processed. Your subscription status has been updated.',
                title: 'Success',
              );
            });
          });
        } else {
          // If no URL, assume direct cancellation
          // Refresh user stats to get updated subscription status from API
          await fetchUserStats();

          // Show success message safely using post-frame callback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              SnackbarHelper.showSuccess(
                'Subscription will be cancelled. You will continue to have access until the end of your billing period.',
                title: 'Success',
              );
            });
          });
        }
      } else {
        throw Exception(
          'Failed to cancel subscription: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling subscription:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Response: ${e.response?.data}');
        print('   Status Code: ${e.response?.statusCode}');
      }

      String errorMessage = 'Failed to cancel subscription. Please try again.';
      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Subscription not found.';
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'Invalid request. Please contact support.';
        }
      }

      SnackbarHelper.showError(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error cancelling subscription: $e');
      }
      SnackbarHelper.showError(
        'Failed to cancel subscription: ${e.toString()}',
      );
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
      {
        'label': 'Total Listings',
        'value': _allListings.length,
        'icon': Icons.home,
      },
    ];
  }

  // ============================================================================
  // DYNAMIC STATS METHODS FOR STATS SCREEN
  // ============================================================================

  /// Get total leads count
  int get totalLeads => _leads.length;

  /// Get accepted/converted leads count
  int get conversions => _leads.where((lead) => lead.isAccepted).length;

  /// Get completed leads count
  int get completedLeads => _leads.where((lead) => lead.isCompleted).length;

  /// Calculate close rate (completed leads / total leads * 100)
  double get closeRate {
    if (totalLeads == 0) return 0.0;
    return (completedLeads / totalLeads) * 100;
  }

  /// Get formatted revenue string
  String get formattedRevenue {
    if (totalRevenue >= 1000) {
      return '\$${(totalRevenue / 1000).toStringAsFixed(1)}K';
    }
    return '\$${totalRevenue.toStringAsFixed(0)}';
  }

  /// Get monthly leads data for the last 7 months
  Map<String, dynamic> getMonthlyLeadsData() {
    final now = DateTime.now();
    final monthlyData = <String, int>{};
    final months = <String>[];

    // Initialize last 7 months with 0
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final monthLabel = _getMonthLabel(date.month);
      monthlyData[monthKey] = 0;
      months.add(monthLabel);
    }

    // Count leads by month
    for (final lead in _leads) {
      try {
        final createdAt = lead.createdAt;
        if (createdAt != null) {
          final monthKey =
              '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
          if (monthlyData.containsKey(monthKey)) {
            monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error parsing lead date: $e');
        }
      }
    }

    final values = monthlyData.values.toList();
    return {'values': values, 'labels': months, 'count': values.length};
  }

  /// Get monthly revenue data (estimated from leads or use actual revenue)
  Map<String, dynamic> getMonthlyRevenueData() {
    final now = DateTime.now();
    final monthlyData = <String, double>{};

    // Initialize last 7 months with 0
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = 0.0;
    }

    // For now, distribute total revenue evenly across months with leads
    // In a real app, you'd track revenue per transaction/lead
    final monthlyLeads = getMonthlyLeadsData();
    final leadsValues = (monthlyLeads['values'] as List<dynamic>)
        .map<int>((v) => v as int)
        .toList();
    final totalLeadsInPeriod = leadsValues.fold<int>(
      0,
      (int sum, int v) => sum + v,
    );

    if (totalLeadsInPeriod > 0) {
      final revenuePerLead = totalRevenue / totalLeadsInPeriod;
      int index = 0;
      for (final key in monthlyData.keys) {
        if (index < leadsValues.length) {
          final leadsCount = leadsValues[index];
          monthlyData[key] = leadsCount * revenuePerLead;
        }
        index++;
      }
    }

    final values = monthlyData.values.toList();
    return {'values': values, 'total': totalRevenue};
  }

  /// Calculate percentage change from previous month
  String calculateMonthOverMonthChange(String metric) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final previousMonth = DateTime(now.year, now.month - 1, 1);

    int currentValue = 0;
    int previousValue = 0;

    switch (metric) {
      case 'leads':
        currentValue = _getLeadsForMonth(currentMonth);
        previousValue = _getLeadsForMonth(previousMonth);
        break;
      case 'conversions':
        currentValue = _getAcceptedLeadsForMonth(currentMonth);
        previousValue = _getAcceptedLeadsForMonth(previousMonth);
        break;
      case 'revenue':
        // For revenue, we'd need actual revenue per month data
        // For now, estimate based on leads
        currentValue = _getLeadsForMonth(currentMonth);
        previousValue = _getLeadsForMonth(previousMonth);
        break;
      case 'closeRate':
        // Close rate change would need historical data
        return '+0%';
    }

    if (previousValue == 0) {
      return currentValue > 0 ? '+100%' : '0%';
    }

    final change = ((currentValue - previousValue) / previousValue) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(0)}%';
  }

  /// Get leads count for a specific month
  int _getLeadsForMonth(DateTime month) {
    return _leads.where((lead) {
      if (lead.createdAt == null) return false;
      final leadDate = lead.createdAt!;
      return leadDate.year == month.year && leadDate.month == month.month;
    }).length;
  }

  /// Get accepted leads count for a specific month
  int _getAcceptedLeadsForMonth(DateTime month) {
    return _leads.where((lead) {
      if (lead.createdAt == null || !lead.isAccepted) return false;
      final leadDate = lead.createdAt!;
      return leadDate.year == month.year && leadDate.month == month.month;
    }).length;
  }

  /// Get month label (short form)
  String _getMonthLabel(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Get activity breakdown data
  Map<String, int> getActivityBreakdown() {
    return {
      'Property Views': profileViews,
      'Inquiries': contacts,
      'Showings': conversions, // Using conversions as showings estimate
      'Offers': completedLeads, // Using completed leads as offers estimate
    };
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

  /// Updates listing via API with form data
  Future<void> updateListingViaAPI(
    String listingId,
    String propertyTitle,
    String description,
    String price,
    String streetAddress,
    String city,
    String state,
    String zipCode,
    String bacPercentage,
    bool listingAgent,
    bool dualAgencyAllowed, {
    List<String>? remainingImageUrls,
    List<File>? newImageFiles,
  }) async {
    try {
      _isLoading.value = true;

      // Get auth token
      final authToken = _storage.read('auth_token');
      if (authToken == null) {
        throw Exception('Not authenticated');
      }

      // Create FormData for multipart/form-data request
      final formData = dio.FormData.fromMap({
        'propertyTitle': propertyTitle,
        'description': description,
        'price': price,
        'BACPercentage': bacPercentage,
        'listingAgent': listingAgent.toString(),
        'dualAgencyAllowed': dualAgencyAllowed.toString(),
        'streetAddress': streetAddress,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'status': 'active', // Default to active
        'createdByRole': 'agent',
      });

      // Add remaining existing image URLs (if any) - send as JSON array
      if (remainingImageUrls != null && remainingImageUrls.isNotEmpty) {
        formData.fields.add(
          MapEntry('existingPropertyPhotos', jsonEncode(remainingImageUrls)),
        );
        if (kDebugMode) {
          print('📸 Remaining existing images (${remainingImageUrls.length}):');
          for (int i = 0; i < remainingImageUrls.length; i++) {
            print('   [$i] ${remainingImageUrls[i]}');
          }
        }
      } else if (remainingImageUrls != null && remainingImageUrls.isEmpty) {
        // If all images were deleted, send empty array
        formData.fields.add(MapEntry('existingPropertyPhotos', jsonEncode([])));
        if (kDebugMode) {
          print('📸 All existing images deleted - sending empty array');
        }
      }

      // Add new image files
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        for (int i = 0; i < newImageFiles.length; i++) {
          final file = newImageFiles[i];
          final fileName = file.path.split('/').last;
          formData.files.add(
            MapEntry(
              'propertyPhotos',
              await dio.MultipartFile.fromFile(file.path, filename: fileName),
            ),
          );
        }
        if (kDebugMode) {
          print('📸 New images to upload (${newImageFiles.length}):');
          for (int i = 0; i < newImageFiles.length; i++) {
            print('   [$i] ${newImageFiles[i].path}');
          }
        }
      }

      if (kDebugMode) {
        print('🚀 Updating listing: $listingId');
        print(
          '📡 API Endpoint: ${ApiConstants.getUpdateListingEndpoint(listingId)}',
        );
      }

      // Setup Dio
      _dio.options.baseUrl = _baseUrl;
      _dio.options.headers = {
        'ngrok-skip-browser-warning': 'true',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      // Make PUT request
      final response = await _dio.put(
        ApiConstants.getUpdateListingEndpoint(
          listingId,
        ).replaceFirst(_baseUrl, ''),
        data: formData,
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Listing updated successfully');
        }

        // Refresh listings
        await fetchAgentListings();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating listing: $e');
      }
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> deleteListing(String listingId) async {
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

        // Refresh listings from API to ensure consistency
        await fetchAgentListings();
        return true;
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
    return false;
  }

  Future<void> toggleListingStatus(String listingId) async {
    try {
      _isLoading.value = true;

      // Find the listing to get current status
      final index = _allListings.indexWhere((l) => l.id == listingId);
      if (index == -1) {
        Get.snackbar('Error', 'Listing not found');
        return;
      }

      final listing = _allListings[index];
      final newStatus = listing.isActive ? 'inactive' : 'active';

      if (kDebugMode) {
        print('📡 Updating listing status');
        print('   Listing ID: $listingId');
        print('   Current status: ${listing.isActive ? "active" : "inactive"}');
        print('   New status: $newStatus');
      }

      // Get auth token
      final authToken = _storage.read('auth_token');

      // Call the API to update listing status
      // Use just the path since baseUrl is already set in _setupDio()
      final endpoint = '/agent/updateListingStatus';

      if (kDebugMode) {
        print('   Endpoint: $endpoint');
        print('   Full URL: ${_dio.options.baseUrl}$endpoint');
      }

      final response = await _dio.post(
        endpoint,
        data: {'id': listingId, 'status': newStatus},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...ApiConstants.ngrokHeaders,
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (kDebugMode) {
        print('✅ Listing status updated');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update local listing
        _allListings[index] = listing.copyWith(
          isActive: newStatus == 'active',
          updatedAt: DateTime.now(),
        );

        final statusText = newStatus == 'active' ? 'activated' : 'deactivated';
        Get.snackbar('Success', 'Listing $statusText successfully!');

        if (newStatus == 'active') {
          _markListingRecentlyActivated(listingId);
        } else {
          _recentlyActivatedListingId.value = null;
        }

        // Apply filters to update displayed listings
        _applyFilters();

        // Refresh listings from API to ensure sync
        await fetchAgentListings();
      } else {
        throw Exception(
          'Failed to update listing status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException updating listing status:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Response: ${e.response?.data}');
        print('   Status Code: ${e.response?.statusCode}');
      }

      final errorMessage =
          e.response?.data?['message']?.toString() ??
          'Failed to update listing status. Please try again.';
      Get.snackbar('Error', errorMessage);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating listing status: $e');
      }
      Get.snackbar('Error', 'Failed to update listing status: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> purchaseAdditionalListing() async {
    try {
      _isLoading.value = true;

      final authController = Get.find<global.AuthController>();
      final userId = authController.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        SnackbarHelper.showError(
          'Unable to identify the user. Please login again.',
        );
        return;
      }

      final response = await _dio.post(
        '/subscription/create-listing-checkout',
        data: {
          'role': 'agent',
          'userId': userId,
          'price': 9.99.toStringAsFixed(2),
        },
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
          },
        ),
      );

      final checkoutUrl = response.data['url'] as String?;

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Invalid checkout URL received from server');
      }

      final paymentSuccess = await Get.to<bool>(
        () => PaymentWebView(checkoutUrl: checkoutUrl),
        fullscreenDialog: true,
      );

      if (paymentSuccess == true) {
        SnackbarHelper.showSuccess(
          'Payment completed! You can now add your listing.',
        );
        await Future.delayed(const Duration(milliseconds: 200));
        Get.toNamed('/add-listing');
      } else {
        SnackbarHelper.showInfo('Payment was cancelled.');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print(
          '❌ Error creating listing checkout session: ${e.response?.data ?? e.message}',
        );
      }
      final message =
          e.response?.data?['message']?.toString() ??
          'Failed to initiate listing payment. Please try again.';
      SnackbarHelper.showError(message);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing listing payment: $e');
      }
      SnackbarHelper.showError(
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
          // Use image paths directly from API without prepending base URL
          final listings = listingsData.map((listingJson) {
            final listingMap = Map<String, dynamic>.from(
              listingJson as Map<String, dynamic>,
            );

            // Update propertyPhotos URLs - use paths directly from API
            if (listingMap['propertyPhotos'] != null) {
              final photos = listingMap['propertyPhotos'] as List<dynamic>;
              final listingId =
                  listingMap['_id'] ?? listingMap['id'] ?? 'unknown';
              final propertyTitle =
                  listingMap['propertyTitle'] ??
                  listingMap['title'] ??
                  'Unknown';

              if (kDebugMode) {
                print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                print('🖼️ LISTING IMAGE URLs:');
                print('   Listing ID: $listingId');
                print('   Property Title: $propertyTitle');
                print('   Total Images: ${photos.length}');
                print('');
                print('   📋 Image URLs (directly from API):');
                for (int i = 0; i < photos.length; i++) {
                  final photoPath = photos[i].toString();
                  print('      [$i] $photoPath');
                }
                print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              }

              listingMap['propertyPhotos'] = photos.map((photo) {
                final photoPath = photo.toString();
                if (photoPath.isEmpty) return photo;
                // Use path directly from API - no modification
                return photoPath;
              }).toList();
            }

            return AgentListingModel.fromApiJson(listingMap);
          }).toList();

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
  /// Shows a form dialog first (if not already accepted), then calls the respondToLead API, then navigates to chat
  /// If lead is already accepted, skips dialog and goes directly to chat
  Future<void> contactBuyerFromLead(LeadModel lead) async {
    final buyerInfo = lead.buyerInfo;
    if (buyerInfo == null) {
      SnackbarHelper.showError('Buyer information not available');
      return;
    }

    // Get current agent ID
    final authController = Get.find<global.AuthController>();
    final currentUser = authController.currentUser;
    if (currentUser == null || currentUser.id.isEmpty) {
      SnackbarHelper.showError('Agent not logged in');
      return;
    }

    // If lead is already accepted, go directly to chat
    if (lead.isAccepted) {
      if (kDebugMode) {
        print('✅ Lead already accepted, opening chat directly');
      }
      await _openChatDirectly(buyerInfo);
      return;
    }

    // Show form dialog first for new leads
    _showRespondToLeadDialog(lead, currentUser.id, buyerInfo);
  }

  /// Opens chat directly without showing dialog (for already accepted leads)
  Future<void> _openChatDirectly(dynamic buyerInfo) async {
    try {
      // Get or create messages controller
      if (!Get.isRegistered<MessagesController>()) {
        Get.put(MessagesController(), permanent: true);
      }
      final messagesController = Get.find<MessagesController>();

      // Start chat with buyer - navigate directly to messages without replacing stack
      await messagesController.startChatWithUser(
        otherUserId: buyerInfo.id,
        otherUserName: buyerInfo.fullname ?? 'Buyer',
        otherUserProfilePic: buyerInfo.profilePic,
        otherUserRole: buyerInfo.role ?? 'user',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening chat: $e');
      }
      SnackbarHelper.showError('Failed to open chat. Please try again.');
    }
  }

  /// Shows a dialog form for responding to a lead
  void _showRespondToLeadDialog(
    LeadModel lead,
    String agentId,
    dynamic buyerInfo,
  ) {
    final noteController = TextEditingController();
    final action = 'accept'.obs; // Default to accept when contacting buyer
    bool isDisposed = false;

    Get.dialog(
      barrierDismissible: !_isLoading.value,
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24.w),
          constraints: BoxConstraints(
            maxWidth: 400.w,
            maxHeight: Get.height * 0.85, // Limit height to 85% of screen
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: AppTheme.primaryBlue,
                      size: 28.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Contact Buyer',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.black,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        // Just close the dialog - controller will be disposed in .then() callback
                        Get.back();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Buyer Info
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buyer: ${buyerInfo.fullname ?? "Unknown"}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.black,
                        ),
                      ),
                      if (buyerInfo.email != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          buyerInfo.email!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Action Selection (hidden since we're always accepting when contacting)
                // Keeping it in case we need it later, but defaulting to 'accept'

                // Note Field
                Text(
                  'Note (Optional)',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'I\'ll contact them tomorrow',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppTheme.mediumGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppTheme.mediumGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Just close the dialog - controller will be disposed in .then() callback
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: AppTheme.mediumGray),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppTheme.darkGray,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: Obx(() {
                        return ElevatedButton(
                          onPressed: _isLoading.value
                              ? null
                              : () async {
                                  // Get note text before closing dialog
                                  final note = noteController.text.trim();

                                  // Close dialog first - don't dispose controller here
                                  // It will be disposed in the .then() callback after dialog fully closes
                                  Get.back();

                                  // Wait for dialog to fully close before proceeding
                                  await Future.delayed(
                                    const Duration(milliseconds: 500),
                                  );

                                  // Now submit and navigate
                                  await _submitRespondToLead(
                                    lead,
                                    agentId,
                                    action.value,
                                    note,
                                    buyerInfo,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            disabledBackgroundColor: AppTheme.primaryBlue
                                .withOpacity(0.6),
                          ),
                          child: _isLoading.value
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: SpinKitThreeBounce(
                                    color: Colors.white,
                                    size: 12.sp,
                                  ),
                                )
                              : Text(
                                  'Contact Buyer',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      // Wait for dialog animation to complete before disposing controller
      // Use post-frame callback to ensure dialog is fully closed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed) {
          isDisposed = true;
          noteController.dispose();
        }
      });
    });
  }

  /// Submits the respond to lead form, calls API, then navigates to chat
  /// Note: Dialog should already be closed before calling this method
  Future<void> _submitRespondToLead(
    LeadModel lead,
    String agentId,
    String action,
    String note,
    dynamic buyerInfo,
  ) async {
    try {
      _isLoading.value = true;

      if (kDebugMode) {
        print('📡 Calling respondToLead API for lead: ${lead.id}');
        print('   Agent ID: $agentId');
        print('   Action: $action');
        print('   Note: ${note.isNotEmpty ? note : "Not provided"}');
      }

      // Call the respondToLead API with form data
      final leadsService = LeadsService();
      await leadsService.respondToLead(
        lead.id,
        agentId,
        action: action,
        note: note.isNotEmpty ? note : null,
      );

      if (kDebugMode) {
        print('✅ Successfully responded to lead');
      }

      // Dialog should already be closed at this point
      // Wait a moment to ensure dialog is fully disposed
      await Future.delayed(const Duration(milliseconds: 200));

      // Show success message
      SnackbarHelper.showSuccess('Lead accepted! Opening chat...');

      // Wait a bit more before navigating
      await Future.delayed(const Duration(milliseconds: 300));

      // Get or create messages controller
      if (!Get.isRegistered<MessagesController>()) {
        Get.put(MessagesController(), permanent: true);
      }
      final messagesController = Get.find<MessagesController>();

      // Start chat with buyer - navigate directly to messages without replacing stack
      await messagesController.startChatWithUser(
        otherUserId: buyerInfo.id,
        otherUserName: buyerInfo.fullname ?? 'Buyer',
        otherUserProfilePic: buyerInfo.profilePic,
        otherUserRole: buyerInfo.role ?? 'user',
      );
    } catch (e) {
      _isLoading.value = false;

      if (kDebugMode) {
        print('❌ Error responding to lead: $e');
      }

      // Handle "Already responded" error gracefully - still navigate to chat
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('already responded')) {
        // Close dialog if still open
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        // Wait for dialog to close
        await Future.delayed(const Duration(milliseconds: 300));

        // Still navigate to chat since lead was already accepted
        if (!Get.isRegistered<MessagesController>()) {
          Get.put(MessagesController(), permanent: true);
        }
        final messagesController = Get.find<MessagesController>();

        await messagesController.startChatWithUser(
          otherUserId: buyerInfo.id,
          otherUserName: buyerInfo.fullname ?? 'Buyer',
          otherUserProfilePic: buyerInfo.profilePic,
          otherUserRole: buyerInfo.role ?? 'user',
        );
        return;
      }

      // For other errors, show error message
      // Wait a bit if dialog is closing
      if (Get.isDialogOpen ?? false) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final errorMsg =
          e.toString().contains('Not authorized') ||
              e.toString().contains('403')
          ? 'You are not authorized to contact this buyer. Please check your permissions.'
          : 'Failed to contact buyer. Please try again.';

      SnackbarHelper.showError(errorMsg);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Marks a lead as complete
  Future<void> markLeadComplete(LeadModel lead) async {
    try {
      _isLoading.value = true;

      // Check if lead is already completed
      if (lead.isCompleted) {
        SnackbarHelper.showError('This lead is already completed');
        return;
      }

      final buyerInfo = lead.buyerInfo;
      if (buyerInfo == null) {
        SnackbarHelper.showError('Buyer information not available');
        return;
      }

      final userId = buyerInfo.id;
      final role = buyerInfo.role ?? 'buyer/seller';

      if (kDebugMode) {
        print('📡 Marking lead as complete: ${lead.id}');
        print('   User ID: $userId');
        print('   Role: $role');
      }

      final leadsService = LeadsService();
      await leadsService.markLeadComplete(lead.id, userId, role);

      if (kDebugMode) {
        print('✅ Lead marked as complete successfully');
        print('📋 Completed Lead ID: ${lead.id}');
      }

      // Refresh leads to update the UI
      await fetchLeads();

      SnackbarHelper.showSuccess(
        'Lead marked as complete!\nLead ID: ${lead.id}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking lead as complete: $e');
      }

      final errorMsg =
          e.toString().contains('Not authorized') ||
              e.toString().contains('403')
          ? 'You are not authorized to complete this lead.'
          : 'Failed to mark lead as complete. Please try again.';

      SnackbarHelper.showError(errorMsg);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Helper method to show snackbar safely with proper context handling
  void _showSnackbarSafely(
    String message, {
    bool isError = true,
    bool isAlreadyClaimed = false,
  }) {
    final snackbarTitle = isAlreadyClaimed
        ? 'ZIP Code Already Claimed'
        : (isError ? 'Error' : 'Success');
    final snackbarColor = isAlreadyClaimed
        ? Colors.orange.shade700
        : (isError ? Colors.red.shade600 : Colors.green.shade600);
    final snackbarDuration = isAlreadyClaimed
        ? const Duration(seconds: 4)
        : const Duration(seconds: 3);

    // Use WidgetsBinding to ensure overlay is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Get.snackbar(
          snackbarTitle,
          message,
          snackPosition: SnackPosition.BOTTOM,
          duration: snackbarDuration,
          backgroundColor: snackbarColor,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          isDismissible: true,
          dismissDirection: DismissDirection.horizontal,
          icon: Icon(
            isAlreadyClaimed
                ? Icons.warning_rounded
                : (isError ? Icons.error_rounded : Icons.check_circle_rounded),
            color: Colors.white,
            size: 24,
          ),
        );
      } catch (overlayError) {
        // Fallback if overlay is not available - try again after a delay
        if (kDebugMode) {
          print('⚠️ Could not show snackbar, retrying: $overlayError');
        }
        Future.delayed(const Duration(milliseconds: 800), () {
          try {
            Get.snackbar(
              snackbarTitle,
              message,
              snackPosition: SnackPosition.BOTTOM,
              duration: snackbarDuration,
              backgroundColor: snackbarColor,
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
            );
          } catch (e) {
            if (kDebugMode) {
              print('❌ Failed to show snackbar even after delay: $e');
            }
          }
        });
      }
    });
  }
}

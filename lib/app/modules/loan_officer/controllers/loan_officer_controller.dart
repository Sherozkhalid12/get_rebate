import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/models/loan_officer_zip_code_model.dart';
import 'package:getrebate/app/models/loan_model.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/models/subscription_model.dart';
import 'package:getrebate/app/models/promo_code_model.dart';
import 'package:getrebate/app/services/loan_officer_zip_code_pricing_service.dart';
import 'package:getrebate/app/services/loan_officer_zip_code_service.dart';
import 'package:getrebate/app/services/rebate_states_service.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/controllers/location_controller.dart';
import 'package:getrebate/app/controllers/current_loan_officer_controller.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/models/waiting_list_entry_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/storage_keys.dart';

import 'package:getrebate/app/utils/network_error_handler.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/widgets/payment_web_view.dart';
import 'package:url_launcher/url_launcher.dart';

class LoanOfficerController extends GetxController {
  final LocationController _locationController = Get.find<LocationController>();
  // Services - using separate loan officer zip code service
  final LoanOfficerZipCodeService _loanOfficerZipCodeService;
  final RebateStatesService _rebateStatesService = RebateStatesService();
  final GetStorage _storage;
  final Dio _dio = Dio();

  // Using ApiConstants for centralized URL management
  static String get _baseUrl => ApiConstants.apiBaseUrl;

  // Storage keys
  static const String _zipCodesCacheKeyPrefix = 'loan_officer_zip_codes_cache_';
  static const String _lastStateKey = 'loan_officer_zip_codes_last_state';
  static const Duration _apiTimeout = Duration(seconds: 60);

  LoanOfficerController({
    LoanOfficerZipCodeService? loanOfficerZipCodeService,
    GetStorage? storage,
  }) : _loanOfficerZipCodeService =
           loanOfficerZipCodeService ?? LoanOfficerZipCodeService(),
       _storage = storage ?? GetStorage();

  // Data - using LoanOfficerZipCodeModel instead of ZipCodeModel
  final _claimedZipCodes = <LoanOfficerZipCodeModel>[].obs;
  final _availableZipCodes = <LoanOfficerZipCodeModel>[].obs;
  final _allZipCodes =
      <LoanOfficerZipCodeModel>[].obs; // All zip codes from API
  final _stateZipCodesFromApi = <LoanOfficerZipCodeModel>[]; // getstateZip result
  final _filteredAvailableZipCodes = <LoanOfficerZipCodeModel>[]
      .obs; // Filtered available zip codes for search
  final _filteredClaimedZipCodes =
      <LoanOfficerZipCodeModel>[].obs; // Filtered claimed zip codes for search
  final _searchQuery = ''.obs; // Current search query
  final zipSearchController = TextEditingController();
  Timer? _zipVerifyDebounce;
  final _loans = <LoanModel>[].obs;
  final _isLoading = false.obs;
  final _isLoadingZipCodes = false.obs;
  final _hasLoadedZipCodes = false.obs; // Cache flag to prevent reloading
  final _loadingZipCodeIds =
      <String>{}.obs; // Track which zip codes are being processed
  final _currentState = ''.obs; // Track current state for cache invalidation
  final _selectedState = Rxn<String>(); // Selected state for ZIP code filtering
  final _selectedTab =
      0.obs; // 0: Dashboard, 1: Messages, 2: ZIP Management, 3: Billing
  /// Session-only flag: user tapped Skip on ZIP selection screen (no persistence).
  final _hasSkippedZipSelection = false.obs;
  /// From API: true = old user (has claimed before), false = new user. Null = not yet loaded, fallback to claimedZipCodes.isEmpty.
  final _firstZipCodeClaimed = Rxn<bool>();

  // Stats
  final _searchesAppearedIn = 0.obs;
  final _profileViews = 0.obs;
  final _contacts = 0.obs;
  final _totalRevenue = 0.0.obs;

  // Subscription & Promo Code
  final _subscription = Rxn<SubscriptionModel>();
  final _promoCodeInput = ''.obs;
  final _subscriptions =
      <Map<String, dynamic>>[].obs; // Payment history subscriptions
  final Set<String> _profileClaimedZipCodes =
      <String>{}; // Claimed ZIPs from user profile

  // Waiting List State
  final _waitingListRequests = <String>{}.obs;
  final _waitingListEntries = <String, List<WaitingListEntry>>{}.obs;
  final _waitingListLoading = <String>{}.obs;

  // Standard pricing (deprecated - now using zip code population-based pricing)
  // Kept for backward compatibility, but pricing is now calculated from zip codes
  @Deprecated('Use LoanOfficerZipCodePricingService instead')
  static const double standardMonthlyPrice = 17.99;

  // Getters
  List<LoanOfficerZipCodeModel> get claimedZipCodes => _claimedZipCodes;
  List<LoanOfficerZipCodeModel> get availableZipCodes => _availableZipCodes;
  List<LoanOfficerZipCodeModel> get filteredClaimedZipCodes =>
      _filteredClaimedZipCodes;
  List<LoanOfficerZipCodeModel> get filteredAvailableZipCodes =>
      _filteredAvailableZipCodes;
  List<LoanModel> get loans => _loans;
  bool get isLoading => _isLoading.value;
  bool get isLoadingZipCodes => _isLoadingZipCodes.value;
  bool get hasLoadedZipCodes => _hasLoadedZipCodes.value;
  String get searchQuery => _searchQuery.value;

  // Waiting List Getters
  bool isWaitingListProcessing(String zipCode) =>
      _waitingListRequests.contains(zipCode);

  bool isWaitingListLoading(String zipCodeId) =>
      _waitingListLoading.contains(zipCodeId);

  bool hasWaitingListEntries(String zipCodeId) =>
      (_waitingListEntries[zipCodeId]?.isNotEmpty ?? false);

  List<WaitingListEntry> waitingListEntries(String zipCodeId) =>
      _waitingListEntries[zipCodeId] ?? [];

  /// True if current user's ID is in the zip's WaitingUsers list (from API).
  bool isCurrentUserInWaitingList(LoanOfficerZipCodeModel zip) {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return false;
    return zip.waitingUsers.contains(uid);
  }

  /// Check if a specific zip code is being processed
  bool isZipCodeLoading(String zipCode) => _loadingZipCodeIds.contains(zipCode);

  /// Get user ID for API calls
  String? get _userId {
    final authController = Get.isRegistered<global.AuthController>()
        ? Get.find<global.AuthController>()
        : null;
    return authController?.currentUser?.id;
  }

  String? get selectedState => _selectedState.value;
  int get selectedTab => _selectedTab.value;
  /// True once we've received firstZipCodeClaimed from API. Use to avoid flicker: show loading until known.
  bool get isZipClaimStatusKnown => _firstZipCodeClaimed.value != null;

  /// Only new loan officers (firstZipCodeClaimed==false) see ZIP claim screen before home.
  /// firstZipCodeClaimed: false = new user (show), true = old user (skip).
  /// When null (API hasn't returned yet), do NOT show - avoid showing to all users.
  bool get showZipSelectionFirst {
    final firstClaimed = _firstZipCodeClaimed.value;
    // Only show when API explicitly says firstZipCodeClaimed is false (new user)
    if (firstClaimed != false) return false;
    return !_hasSkippedZipSelection.value;
  }
  int get searchesAppearedIn => _searchesAppearedIn.value;
  int get profileViews => _profileViews.value;
  int get contacts => _contacts.value;
  double get totalRevenue => _totalRevenue.value;

  // Subscription & Promo Code Getters
  SubscriptionModel? get subscription => _subscription.value;
  String get promoCodeInput => _promoCodeInput.value;
  double get standardPrice => standardMonthlyPrice;
  bool get hasActivePromo => _subscription.value?.isPromoActive ?? false;
  bool get isInFreePeriod => _subscription.value?.isInFreePeriod ?? false;
  bool get isCancelled => _subscription.value?.isCancelled ?? false;
  int get daysUntilCancellation =>
      _subscription.value?.daysUntilCancellation ?? 0;
  DateTime? get freePeriodEndsAt => _subscription.value?.freePeriodEndsAt;
  int? get freeMonthsRemaining => _subscription.value?.freeMonthsRemaining;
  List<Map<String, dynamic>> get subscriptions => _subscriptions;

  // Get active (non-canceled) subscriptions from API data
  List<Map<String, dynamic>> get activeSubscriptions {
    if (_subscriptions.isEmpty) return [];
    return _subscriptions.where((sub) {
      final status = sub['subscriptionStatus']?.toString().toLowerCase() ?? '';
      return status != 'canceled' && status != 'cancelled';
    }).toList();
  }

  /// Get the active subscription from API (not canceled/cancelled)
  Map<String, dynamic>? get activeSubscriptionFromAPI {
    if (_subscriptions.isEmpty) return null;
    for (final sub in _subscriptions) {
      final status = sub['subscriptionStatus']?.toString().toLowerCase() ?? '';
      if (status != 'canceled' && status != 'cancelled') {
        return sub;
      }
    }
    return _subscriptions.isNotEmpty ? _subscriptions.first : null;
  }

  @override
  void onInit() {
    super.onInit();
    _setupDio();
    // Read firstZipCodeClaimed pre-fetched during splash to avoid loading flicker
    final stored = _storage.read(kFirstZipCodeClaimedStorageKey);
    if (stored is bool) {
      _firstZipCodeClaimed.value = stored;
    }
    // Load filtered licensed states
    _loadFilteredLicensedStates();
    // IMPORTANT: Clear any existing data first to prevent stale/mock data
    _claimedZipCodes.clear();
    _availableZipCodes.clear();
    _pendingClaimedZipCodes.clear();
    _pendingReleasedZipCodes.clear();

    _initializeSubscription();
    checkPromoExpiration(); // Check if free period has ended

    // Load billing/subscription data from API
    Future.microtask(() => fetchUserStats());

    // Preload chat threads for instant access when loan officer opens messages
    _preloadThreads();

    // Listen to loan officer changes to sync ZIP codes
    _setupLoanOfficerListener();

    // IMPORTANT: Load claimed zip codes FIRST from backend to prevent mock data interference
    // This will also fetch fresh data from backend to ensure sync
    _loadInitialClaimedZipCodes().then((_) {
      // Only load mock data AFTER we've loaded real data
      // This ensures mock data doesn't interfere with real claimed zip codes
      _loadMockData();
    });

    // Load zip codes AFTER page renders (deferred for instant page load)
    // Use Future.delayed to ensure page renders first, then loads data
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadZipCodes();
    });
  }

  /// Loads initial claimed zip codes from current loan officer if available
  /// Also fetches fresh data from backend to ensure sync
  Future<void> _loadInitialClaimedZipCodes() async {
    try {
      // IMPORTANT: Clear lists FIRST to prevent any mock data from showing
      _claimedZipCodes.clear();
      _availableZipCodes.clear();
      _pendingClaimedZipCodes.clear();
      _pendingReleasedZipCodes.clear();

      final currentLoanOfficerController =
          Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;

      if (currentLoanOfficerController == null) {
        if (kDebugMode) {
          print('⚠️ CurrentLoanOfficerController not available');
        }
        return;
      }

      // First, try to get existing data
      var officer = currentLoanOfficerController.currentLoanOfficer.value;

      // If we have an ID but no data, or if we want to ensure fresh data, fetch from backend
      final authController = Get.isRegistered<global.AuthController>()
          ? Get.find<global.AuthController>()
          : null;

      final userId = authController?.currentUser?.id ?? officer?.id;

      if (userId != null && userId.isNotEmpty) {
        if (kDebugMode) {
          print(
            '📡 Fetching fresh loan officer data from backend to sync claimed zip codes...',
          );
        }

        try {
          // IMPORTANT: Force refresh to always get latest data from backend
          await currentLoanOfficerController.refreshData(userId, true);
          officer = currentLoanOfficerController.currentLoanOfficer.value;

          if (kDebugMode && officer != null) {
            print('✅ Fetched loan officer data from backend');
            print(
              '   Claimed ZIP codes from backend: ${officer.claimedZipCodes}',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Failed to fetch fresh loan officer data: $e');
            print('   Using existing cached data if available');
          }
        }
      }

      // Now sync with the model (whether from fresh fetch or cached)
      if (officer != null) {
        if (kDebugMode) {
          print('📦 Syncing claimed zip codes with backend data');
          print('   Claimed ZIP codes: ${officer.claimedZipCodes}');
        }
        _syncZipCodesFromBackend(officer);
      } else {
        if (kDebugMode) {
          print('ℹ️ No loan officer data available yet');
        }
        // IMPORTANT: If no officer data, ensure lists stay empty (no mock data)
        _claimedZipCodes.clear();
        _availableZipCodes.clear();
        _pendingClaimedZipCodes.clear();
        _pendingReleasedZipCodes.clear();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to load initial claimed zip codes: $e');
      }
      // On error, ensure lists are cleared to prevent showing stale/mock data
      _claimedZipCodes.clear();
      _availableZipCodes.clear();
      _pendingClaimedZipCodes.clear();
      _pendingReleasedZipCodes.clear();
    }
  }

  /// Sets up a listener to sync ZIP codes when loan officer data changes
  void _setupLoanOfficerListener() {
    try {
      final currentLoanOfficerController =
          Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;

      if (currentLoanOfficerController != null) {
        // Listen to changes in currentLoanOfficer and update ZIP code lists
        ever(currentLoanOfficerController.currentLoanOfficer, (
          LoanOfficerModel? officer,
        ) {
          if (officer != null) {
            if (kDebugMode) {
              print('🔄 Loan officer data updated, syncing ZIP codes...');
              print(
                '   Claimed ZIP codes from model: ${officer.claimedZipCodes}',
              );
            }
            // IMPORTANT: Only sync from backend - never use mock data
            // Load claimed zip codes immediately from the model
            _syncZipCodesFromBackend(officer);
            // Update ZIP code lists to reflect claimed ZIP codes from the model
            if (_allZipCodes.isNotEmpty) {
              _updateZipCodeLists();
            }
          } else {
            // IMPORTANT: If officer is null, clear lists to prevent showing mock data
            _claimedZipCodes.clear();
            _availableZipCodes.clear();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to setup loan officer listener: $e');
      }
    }
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    _zipVerifyDebounce?.cancel();
    zipSearchController.dispose();
    super.onClose();
  }

  /// Gets the cache key for zip codes based on country and state
  String _getCacheKey(String country, String state) {
    return '$_zipCodesCacheKeyPrefix${country}_$state';
  }

  // Only includes states where rebates are allowed
  static const Map<String, String> _stateNameToCode = {
    'Arizona': 'AZ', 'Arkansas': 'AR',
    'California': 'CA', 'Colorado': 'CO', 'Connecticut': 'CT', 'Delaware': 'DE',
    'Florida': 'FL', 'Georgia': 'GA', 'Hawaii': 'HI', 'Idaho': 'ID',
    'Illinois': 'IL', 'Indiana': 'IN',
    'Kentucky': 'KY', 'Maine': 'ME', 'Maryland': 'MD',
    'Massachusetts': 'MA', 'Michigan': 'MI', 'Minnesota': 'MN',
    'Montana': 'MT', 'Nebraska': 'NE', 'Nevada': 'NV',
    'New Hampshire': 'NH', 'New Jersey': 'NJ', 'New Mexico': 'NM', 'New York': 'NY',
    'North Carolina': 'NC', 'North Dakota': 'ND', 'Ohio': 'OH',
    'Pennsylvania': 'PA', 'Rhode Island': 'RI', 'South Carolina': 'SC',
    'South Dakota': 'SD', 'Texas': 'TX', 'Utah': 'UT',
    'Vermont': 'VT', 'Virginia': 'VA', 'Washington': 'WA', 'West Virginia': 'WV',
    'Wisconsin': 'WI', 'Wyoming': 'WY',
  };

  /// Normalize state to two-letter code. Prevents wrong zips (e.g. AL vs Alaska).
  String _normalizeStateToCode(String s) {
    if (s.trim().length == 2) return s.trim().toUpperCase();
    return _stateNameToCode[s.trim()] ?? s.trim().toUpperCase();
  }

  /// Licensed states as two-letter codes for dropdown and API. Use these instead of raw licensedStates.
  List<String> get licensedStateCodes {
    final currentLoanOfficerController =
        Get.isRegistered<CurrentLoanOfficerController>()
            ? Get.find<CurrentLoanOfficerController>()
            : null;
    final states = currentLoanOfficerController?.currentLoanOfficer.value?.licensedStates ?? [];
    final codes = states.map((s) => _normalizeStateToCode(s)).toList();
    return codes.toSet().toList()..sort((a, b) => a.compareTo(b));
  }

  /// Licensed states filtered to only include rebate-allowed states
  /// Returns a reactive observable list that updates when states are loaded
  final _filteredLicensedStateCodes = <String>[].obs;
  List<String> get filteredLicensedStateCodes => _filteredLicensedStateCodes;

  /// Loads and filters licensed states to only include rebate-allowed states
  Future<void> _loadFilteredLicensedStates() async {
    try {
      final allowedStates = await _rebateStatesService.getAllowedStates();
      final allowedStatesSet = allowedStates.map((s) => s.toUpperCase()).toSet();
      final codes = licensedStateCodes.where((code) => 
        allowedStatesSet.contains(code.toUpperCase())
      ).toList();
      _filteredLicensedStateCodes.value = codes..sort((a, b) => a.compareTo(b));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error filtering licensed states: $e');
      }
      // On error, use all licensed states (fallback)
      _filteredLicensedStateCodes.value = licensedStateCodes;
    }
  }

  /// Loads zip codes from cache or API using the new loan officer endpoint
  /// ALWAYS checks GetStorage first, only fetches from API if cache is empty or invalid
  /// Uses GetX reactive state management for optimal performance
  Future<void> _loadZipCodes({bool forceRefresh = false}) async {
    // Prevent multiple simultaneous loads
    if (_isLoadingZipCodes.value && !forceRefresh) {
      if (kDebugMode) {
        print('⏳ Zip codes already loading, skipping duplicate request');
      }
      return;
    }

    try {
      // Get current loan officer to determine state
      final currentLoanOfficerController =
          Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;

      final loanOfficer =
          currentLoanOfficerController?.currentLoanOfficer.value;

      // Country is always US, only state changes. Use selected state or first licensed (as code).
      const country = 'US';
      final codes = licensedStateCodes;
      final state = _selectedState.value != null && _selectedState.value!.isNotEmpty
          ? _normalizeStateToCode(_selectedState.value!)
          : (codes.isNotEmpty ? codes.first : 'CA');

      final stateKey = '${country}_$state';
      final cacheKey = _getCacheKey(country, state);

      // ALWAYS check memory cache first (fastest)
      if (!forceRefresh &&
          _hasLoadedZipCodes.value &&
          _currentState.value == stateKey) {
        if (_allZipCodes.isNotEmpty) {
          if (kDebugMode) {
            print('📦 Zip codes already loaded in memory, using cached data');
          }
          return;
        }
      }

      // ALWAYS check GetStorage cache second (before API)
      if (!forceRefresh) {
        try {
          final cachedZipCodes = _readCachedZipCodes(cacheKey);
          if (cachedZipCodes != null && cachedZipCodes.isNotEmpty) {
            _stateZipCodesFromApi.clear();
            _stateZipCodesFromApi.addAll(cachedZipCodes);
            _allZipCodes.value = List.from(_stateZipCodesFromApi);
            _currentState.value = stateKey;
            _updateZipCodeLists();
            _hasLoadedZipCodes.value = true;

            if (kDebugMode) {
              print(
                '✅ Loaded ${cachedZipCodes.length} zip codes from GetStorage',
              );
              print('   State: $state');
            }

            try {
              final lastCacheTimeStr = _storage.read<String>(
                '${cacheKey}_timestamp',
              );
              DateTime? lastCacheTime;
              if (lastCacheTimeStr != null) {
                lastCacheTime = DateTime.tryParse(lastCacheTimeStr);
              }
              final shouldRefresh =
                  lastCacheTime == null ||
                  DateTime.now().difference(lastCacheTime).inHours >= 1;

              if (shouldRefresh) {
                Future.delayed(const Duration(seconds: 5), () {
                  _refreshCacheInBackground(country, state).catchError((e) {
                    if (kDebugMode) {
                      print('⚠️ Background refresh failed: $e');
                    }
                  });
                });
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Error checking cache timestamp: $e');
              }
            }
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error reading from GetStorage: $e');
          }
        }
      }

      // Only fetch from API if cache is empty or force refresh
      _isLoadingZipCodes.value = true;

      if (kDebugMode) {
        print('📡 Loading zip codes from API (getstateZip)');
        print('   Country: $country');
        print('   State: $state');
        print('   Force refresh: $forceRefresh');
      }

      final zipCodes = await _loanOfficerZipCodeService.getStateZipCodes(
        country,
        state,
      );

      if (zipCodes.isEmpty) {
        if (kDebugMode) {
          print('⚠️ API returned empty zip codes list');
        }
        _isLoadingZipCodes.value = false;
        return;
      }

      _stateZipCodesFromApi.clear();
      _stateZipCodesFromApi.addAll(zipCodes);
      _allZipCodes.value = List.from(_stateZipCodesFromApi);
      _currentState.value = stateKey;

      Future.microtask(() {
        _saveZipCodesToCache(cacheKey, zipCodes, stateKey);
      });

      _updateZipCodeLists();

      _hasLoadedZipCodes.value = true;

      if (kDebugMode) {
        print('✅ Loaded ${zipCodes.length} zip codes from API');
        print('   Claimed: ${_claimedZipCodes.length}');
        print('   Available: ${_availableZipCodes.length}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Failed to load zip codes: $e');
        print('   Stack trace: $stackTrace');
      }

      if (_allZipCodes.isEmpty) {
        SnackbarHelper.showError(
          'Failed to load zip codes. Please check your connection.',
          title: 'Error',
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      _isLoadingZipCodes.value = false;
    }
  }

  /// Saves zip codes to GetStorage cache with error handling
  /// Optimized for large datasets with chunked processing
  void _saveZipCodesToCache(
    String cacheKey,
    List<LoanOfficerZipCodeModel> zipCodes,
    String stateKey,
  ) {
    if (zipCodes.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Cannot save empty zip codes list to cache');
      }
      return;
    }

    try {
      // For very large datasets (1864+ items), use efficient JSON encoding
      // Direct mapping is more efficient than chunking for GetStorage
      final jsonList = zipCodes.map((zip) => zip.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      // Write to storage with error handling
      // GetStorage handles large strings efficiently
      _storage.write(cacheKey, jsonString);
      _storage.write(_lastStateKey, stateKey);
      _storage.write(
        '${cacheKey}_timestamp',
        DateTime.now().toIso8601String(),
      ); // Cache timestamp as string

      if (kDebugMode) {
        final sizeKB = (jsonString.length / 1024).toStringAsFixed(2);
        print(
          '💾 Saved ${zipCodes.length} zip codes to GetStorage ($sizeKB KB)',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('⚠️ Failed to save zip codes to cache: $e');
        print('   Stack trace: $stackTrace');
      }
      // Don't throw - cache failure shouldn't break the app
      // Try to save a smaller subset if full save fails (fallback)
      try {
        if (zipCodes.length > 1000) {
          final subset = zipCodes.take(1000).toList();
          final jsonList = subset.map((zip) => zip.toJson()).toList();
          final jsonString = jsonEncode(jsonList);
          _storage.write(cacheKey, jsonString);
          _storage.write(_lastStateKey, stateKey);
          if (kDebugMode) {
            print(
              '💾 Saved subset (${subset.length} zip codes) to cache as fallback',
            );
          }
        }
      } catch (e2) {
        if (kDebugMode) {
          print('⚠️ Fallback cache save also failed: $e2');
        }
      }
    }
  }

  List<LoanOfficerZipCodeModel>? _readCachedZipCodes(String cacheKey) {
    final cachedData = _storage.read(cacheKey);
    return _decodeZipCodesFromCache(cachedData, cacheKey);
  }

  List<LoanOfficerZipCodeModel>? _decodeZipCodesFromCache(
    dynamic cachedData,
    String cacheKey,
  ) {
    if (cachedData == null) return null;

    List<dynamic> jsonList = [];

    if (cachedData is String && cachedData.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedData);
        if (decoded is List) {
          jsonList = decoded;
        } else {
          if (kDebugMode) {
            print(
              '⚠️ Cached zip codes for $cacheKey are not a list (${decoded.runtimeType})',
            );
          }
          return null;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Failed to parse cached zip codes: $e');
        }
        _storage.remove(cacheKey);
        return null;
      }
    } else if (cachedData is List) {
      jsonList = cachedData;
    } else {
      if (kDebugMode) {
        print(
          '⚠️ Unexpected cached data type for $cacheKey: ${cachedData.runtimeType}, clearing cache',
        );
      }
      _storage.remove(cacheKey);
      return null;
    }

    final zipCodes = jsonList
        .map((json) {
          try {
            return LoanOfficerZipCodeModel.fromJson(
              json as Map<String, dynamic>,
            );
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Failed to parse zip code item: $e');
            }
            return null;
          }
        })
        .whereType<LoanOfficerZipCodeModel>()
        .toList();

    return zipCodes.isNotEmpty ? zipCodes : null;
  }

  /// Refreshes cache in background without blocking UI
  /// Uses GetX reactive updates only when state matches
  /// Prevents multiple simultaneous background refreshes
  static bool _isBackgroundRefreshRunning = false;

  Future<void> _refreshCacheInBackground(String country, String state) async {
    // Prevent multiple simultaneous background refreshes
    if (_isBackgroundRefreshRunning || _isLoadingZipCodes.value) {
      if (kDebugMode) {
        print('⏸️ Background refresh already running, skipping');
      }
      return;
    }

    _isBackgroundRefreshRunning = true;

    try {
      // Add delay to avoid conflicts with initial load
      await Future.delayed(const Duration(seconds: 3));

      if (_isLoadingZipCodes.value) {
        return;
      }

      final zipCodes = await _loanOfficerZipCodeService.getStateZipCodes(
        country,
        state,
      );

      if (zipCodes.isEmpty) {
        return;
      }

      final cacheKey = _getCacheKey(country, state);
      final stateKey = '${country}_$state';

      if (_currentState.value == stateKey && !_isLoadingZipCodes.value) {
        _saveZipCodesToCache(cacheKey, zipCodes, stateKey);

        if (_selectedTab.value == 2 && zipCodes.length != _allZipCodes.length) {
          _stateZipCodesFromApi.clear();
          _stateZipCodesFromApi.addAll(zipCodes);
          _allZipCodes.value = List.from(_stateZipCodesFromApi);
          _updateZipCodeLists();
        }

        if (kDebugMode) {
          print('🔄 Background cache refresh completed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Background cache refresh failed: $e');
      }
      // Silently fail - user already has cached data
    } finally {
      _isBackgroundRefreshRunning = false;
    }
  }

  /// Syncs zip codes from backend model - alias for _loadClaimedZipCodesFromModel
  void _syncZipCodesFromBackend(LoanOfficerModel officer) {
    _loadClaimedZipCodesFromModel(officer);
  }

  /// Loads claimed zip codes directly from the loan officer model
  /// This ensures claimed zip codes are shown immediately even before state selection
  /// IMPORTANT: Only loads from backend model - never adds mock data
  void _loadClaimedZipCodesFromModel(LoanOfficerModel officer) {
    try {
      // Update firstZipCodeClaimed from API
      if (officer.firstZipCodeClaimed != null) {
        _firstZipCodeClaimed.value = officer.firstZipCodeClaimed;
      }

      final claimedZipCodesFromModel = officer.claimedZipCodes;

      // IMPORTANT: If model has no claimed zip codes, clear ALL claimed zip codes
      // unless we already have claimed ZIP codes from the user profile.
      if (claimedZipCodesFromModel.isEmpty) {
        if (kDebugMode) {
          print(
            'ℹ️ No claimed zip codes in loan officer model - clearing ALL claimed zip codes',
          );
        }
        if (_profileClaimedZipCodes.isEmpty) {
          // Clear ALL claimed zip codes (not just for this officer, in case of data inconsistency)
          _claimedZipCodes.clear();
        }
        return;
      }

      if (kDebugMode) {
        print(
          '📦 Loading ${claimedZipCodesFromModel.length} claimed zip codes from model',
        );
      }

      // Create LoanOfficerZipCodeModel objects for claimed zip codes
      final claimedZips = <LoanOfficerZipCodeModel>[];
      final existingClaimedCodes = _claimedZipCodes
          .map((z) => z.postalCode)
          .toSet();

      for (final zipCodeString in claimedZipCodesFromModel) {
        // Skip if already in claimed list
        if (existingClaimedCodes.contains(zipCodeString)) {
          continue;
        }

        // Try to find in _allZipCodes first
        final existingZipIndex = _allZipCodes.indexWhere(
          (zip) => zip.postalCode == zipCodeString,
        );

        if (existingZipIndex != -1) {
          // If found in _allZipCodes, use it but mark as claimed
          final existingZip = _allZipCodes[existingZipIndex];
          final updatedZip = existingZip.copyWith(claimedByOfficer: true);
          _allZipCodes[existingZipIndex] = updatedZip;
          claimedZips.add(updatedZip);
        } else {
          // Create new LoanOfficerZipCodeModel for claimed zip code not in current state
          final newZip = LoanOfficerZipCodeModel(
            postalCode: zipCodeString,
            state: officer.licensedStates.isNotEmpty
                ? officer.licensedStates.first
                : 'CA',
            population: 0,
            claimedByOfficer: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          claimedZips.add(newZip);
        }
      }

      // IMPORTANT: Remove any claimed zip codes that are NOT in the model's claimedZipCodes array
      // This prevents showing stale/incorrect claimed zip codes
      final modelClaimedSet = claimedZipCodesFromModel.toSet();
      _claimedZipCodes.removeWhere(
        (zip) =>
            zip.claimedByOfficer && !modelClaimedSet.contains(zip.postalCode),
      );

      // Add to claimed list (avoid duplicates)
      for (final zip in claimedZips) {
        if (!_claimedZipCodes.any((z) => z.postalCode == zip.postalCode)) {
          _claimedZipCodes.add(zip);
        }
      }

      if (kDebugMode) {
        print('✅ Loaded ${claimedZips.length} claimed zip codes from model');
        print(
          '   Total claimed: ${_claimedZipCodes.length} (model has ${claimedZipCodesFromModel.length})',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error loading claimed zip codes from model: $e');
        print('   Stack trace: $stackTrace');
      }
    }
  }

  // Track pending claims/releases to preserve instant updates
  final _pendingClaimedZipCodes = <String>{};
  final _pendingReleasedZipCodes = <String>{};

  /// Updates the claimed and available zip code lists based on all zip codes
  /// Uses GetX reactive state management for optimal performance
  /// Also includes claimed zip codes from the loan officer model that may not be in _allZipCodes
  /// IMPORTANT: Uses backend model as source of truth, but preserves pending claims/releases
  void _updateZipCodeLists() {
    try {
      final currentLoanOfficerController =
          Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;

      final loanOfficerId =
          currentLoanOfficerController?.currentLoanOfficer.value?.id;

      if (loanOfficerId == null || loanOfficerId.isEmpty) {
        // If no loan officer, treat all as available
        // IMPORTANT: Clear lists first to prevent stale/mock data
        _claimedZipCodes.clear();
        _availableZipCodes.clear();
        _availableZipCodes.addAll(_allZipCodes);
        _applySearchFilter(); // Apply search if active
        return;
      }

      // Get the loan officer's claimedZipCodes array from the model
      final loanOfficer =
          currentLoanOfficerController?.currentLoanOfficer.value;
      final claimedZipCodesFromModel =
          loanOfficer?.claimedZipCodes ?? <String>[];
      final effectiveClaimedZipCodes = claimedZipCodesFromModel.isNotEmpty
          ? claimedZipCodesFromModel
          : _profileClaimedZipCodes.toList();

      // IMPORTANT: If model has 0 claimed zip codes, clear all claimed zip codes immediately
      // BUT preserve pending claims (just claimed but not yet in backend)
      if (effectiveClaimedZipCodes.isEmpty && _pendingClaimedZipCodes.isEmpty) {
        if (kDebugMode) {
          print(
            '🗑️ Model has 0 claimed zip codes - clearing all claimed zip codes',
          );
        }
        _claimedZipCodes.clear();
        _availableZipCodes.clear();
        _availableZipCodes.addAll(_allZipCodes);
        _applySearchFilter();
        return;
      }

      // Create a set of all zip codes we have in _allZipCodes for quick lookup
      final allZipCodesSet = _allZipCodes.map((z) => z.postalCode).toSet();

      // Separate claimed and available zip codes efficiently
      final claimed = <LoanOfficerZipCodeModel>[];
      final available = <LoanOfficerZipCodeModel>[];

      // First, process all zip codes from _allZipCodes
      for (final zip in _allZipCodes) {
        // Check if this zip code is claimed by the current loan officer
        // Only use the model's claimed zip codes list as the source of truth for what *I* have claimed
        final isClaimedInModel = effectiveClaimedZipCodes.contains(
          zip.postalCode,
        );

        if (isClaimedInModel) {
          // If claimed in model, ensure the zip code object has claimedByOfficer=true
          // even if the API didn't return it that way (e.g. slight sync delay)
          if (!zip.claimedByOfficer) {
            final updatedZip = zip.copyWith(claimedByOfficer: true);
            final index = _allZipCodes.indexWhere(
              (z) => z.postalCode == zip.postalCode,
            );
            if (index != -1) {
              _allZipCodes[index] = updatedZip;
            }
            claimed.add(updatedZip);
          } else {
            claimed.add(zip);
          }
        } else {
          // Available (or claimed by someone else)
          available.add(zip);
        }
      }

      // Now, add any claimed zip codes from the model that are not in _allZipCodes
      // This ensures we show all claimed zip codes even if they're not in the current state's list
      for (final claimedZipCodeString in effectiveClaimedZipCodes) {
        // Only add if not already in our claimed list
        final alreadyInClaimed = claimed.any(
          (z) => z.postalCode == claimedZipCodeString,
        );
        if (!alreadyInClaimed &&
            !allZipCodesSet.contains(claimedZipCodeString)) {
          // Create a basic LoanOfficerZipCodeModel for this claimed zip code
          // We'll use default values since we don't have full data from API
          try {
            final claimedZip = LoanOfficerZipCodeModel(
              postalCode: claimedZipCodeString,
              state: loanOfficer?.licensedStates.isNotEmpty == true
                  ? loanOfficer!.licensedStates.first
                  : 'CA', // Default state
              population: 0, // Will be updated when full data is loaded
              claimedByOfficer: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            claimed.add(claimedZip);

            if (kDebugMode) {
              print(
                '📦 Added claimed ZIP code from model: $claimedZipCodeString',
              );
            }
          } catch (e) {
            if (kDebugMode) {
              print(
                '⚠️ Failed to create ZipCodeModel for claimed zip: $claimedZipCodeString, error: $e',
              );
            }
          }
        }
      }

      // IMPORTANT: Use backend claimedZipCodes as the source of truth
      // BUT preserve pending claims/releases for instant UI updates

      // Add pending claimed zip codes that aren't in backend yet (just claimed)
      for (final pendingZip in _pendingClaimedZipCodes) {
        if (!effectiveClaimedZipCodes.contains(pendingZip)) {
          // Find in _allZipCodes or available list
          final pendingZipModel = _allZipCodes.firstWhere(
            (z) => z.postalCode == pendingZip,
            orElse: () => available.firstWhere(
              (z) => z.postalCode == pendingZip,
              orElse: () => LoanOfficerZipCodeModel(
                postalCode: pendingZip,
                state: loanOfficer?.licensedStates.isNotEmpty == true
                    ? loanOfficer!.licensedStates.first
                    : 'CA',
                population: 0,
                claimedByOfficer: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          );

          // Mark as claimed
          final claimedPending = pendingZipModel.copyWith(
            claimedByOfficer: true,
          );

          // Remove from available if there
          available.removeWhere((z) => z.postalCode == pendingZip);
          // Add to claimed if not already there
          if (!claimed.any((z) => z.postalCode == pendingZip)) {
            claimed.add(claimedPending);
          }
        }
      }

      // Remove pending released zip codes from claimed (just released)
      for (final pendingZip in _pendingReleasedZipCodes) {
        if (effectiveClaimedZipCodes.contains(pendingZip)) {
          // Backend still has it, but we just released it - remove from claimed
          claimed.removeWhere((z) => z.postalCode == pendingZip);
          // Find and add to available
          final releasedZip = _allZipCodes.firstWhere(
            (z) => z.postalCode == pendingZip,
            orElse: () => LoanOfficerZipCodeModel(
              postalCode: pendingZip,
              state: loanOfficer?.licensedStates.isNotEmpty == true
                  ? loanOfficer!.licensedStates.first
                  : 'CA',
              population: 0,
              claimedByOfficer: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final availableReleased = releasedZip.copyWith(
            claimedByOfficer: false,
          );

          if (!available.any((z) => z.postalCode == pendingZip)) {
            available.add(availableReleased);
          }
        }
      }

      // IMPORTANT: Clear lists and rebuild ONLY from backend model + pending changes
      _claimedZipCodes.clear();
      _availableZipCodes.clear();

      // Update reactive state using GetX - add items to trigger reactivity
      _claimedZipCodes.addAll(claimed);
      _availableZipCodes.addAll(available);

      if (kDebugMode) {
        print('📊 Updated zip code lists from backend:');
        print(
          '   Claimed: ${_claimedZipCodes.length} (backend model has ${claimedZipCodesFromModel.length}, pending: ${_pendingClaimedZipCodes.length})',
        );
        print('   Available: ${_availableZipCodes.length}');
        print('   Backend claimed ZIP codes: $claimedZipCodesFromModel');
        print('   Pending claimed: $_pendingClaimedZipCodes');
        print('   Pending released: $_pendingReleasedZipCodes');
      }

      // Apply search filter if active
      _applySearchFilter();

      // Prefetch waiting lists for claimed zip codes
      _prefetchWaitingLists(_allZipCodes);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error updating zip code lists: $e');
        print('   Stack trace: $stackTrace');
      }
      // Fallback to empty lists to prevent crashes
      _claimedZipCodes.clear();
      _availableZipCodes.clear();
      _availableZipCodes.addAll(_allZipCodes);
    }
  }

  /// Applies search filter to the lists
  void _applySearchFilter() {
    if (_searchQuery.value.isEmpty) {
      _filteredClaimedZipCodes.value = [];
      _filteredAvailableZipCodes.value = [];
      return;
    }

    final query = _searchQuery.value.toLowerCase();

    _filteredClaimedZipCodes.value = _claimedZipCodes
        .where(
          (zip) =>
              zip.postalCode.contains(query) ||
              zip.state.toLowerCase().contains(query),
        )
        .toList();

    _filteredAvailableZipCodes.value = _availableZipCodes
        .where(
          (zip) =>
              zip.postalCode.contains(query) ||
              zip.state.toLowerCase().contains(query),
        )
        .toList();
  }

  /// Preloads chat threads for instant access when loan officer opens messages
  void _preloadThreads() {
    // Defer to next frame to avoid setState during build
    Future.microtask(() {
      try {
        // Initialize messages controller if not already registered
        // This will also initialize the socket connection for real-time messages
        if (!Get.isRegistered<MessagesController>()) {
          Get.put(MessagesController(), permanent: true);
          if (kDebugMode) {
            print(
              '🚀 Loan Officer: Created MessagesController - socket will be initialized',
            );
          }
        }
        final messagesController = Get.find<MessagesController>();

        // Load threads in background - don't wait for it
        messagesController.refreshThreads();

        // Ensure socket is connected for real-time message reception
        // The socket should be initialized in MessagesController.onInit()
        // which is called when the controller is created above
        if (kDebugMode) {
          print(
            '🚀 Loan Officer: Preloading chat threads and ensuring socket connection...',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Loan Officer: Failed to preload threads: $e');
        }
        // Don't block initialization if preload fails
      }
    });
  }

  void _initializeSubscription() {
    // Initialize with default subscription (no promo)
    // Base price will be calculated from claimed zip codes
    final authController = Get.find<global.AuthController>();
    final userId = authController.currentUser?.id ?? 'loan_1';

    // Calculate base price from claimed zip codes using loan officer population-based pricing
    final basePrice =
        LoanOfficerZipCodePricingService.calculateTotalMonthlyPrice(
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
    _dio.options.connectTimeout = _apiTimeout;
    _dio.options.receiveTimeout = _apiTimeout;

    // Get auth token from storage
    final authToken = _storage.read('auth_token');
    _dio.options.headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  /// Allows access to dashboard without claiming a ZIP; screen will show again on next login.
  void skipZipSelection() {
    _hasSkippedZipSelection.value = true;
  }

  void setSelectedTab(int index) {
    _selectedTab.value = index;

    // Refresh subscription data when "Billing" tab is selected
    if (index == 3) {
      Future.microtask(() => fetchUserStats());
    } else if (index == 2) {
      // Refresh user stats (claimed ZIPs from /auth/users) then zip codes when ZIP tab is selected
      Future.microtask(() async {
        await fetchUserStats();
        await refreshZipCodes();
      });
    }
  }

  void _loadMockData() {
    // Only load mock data if we don't have real data from API
    // This prevents mock data from interfering with real claimed zip codes
    try {
      final currentLoanOfficerController =
          Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;

      final officer = currentLoanOfficerController?.currentLoanOfficer.value;

      // IMPORTANT: NEVER load mock ZIP codes - only load mock loans and stats
      // ZIP codes should ONLY come from backend API
      if (officer != null) {
        if (kDebugMode) {
          print(
            'ℹ️ Skipping mock ZIP code data - real loan officer data exists (${officer.claimedZipCodes.length} claimed zip codes)',
          );
        }
        // Don't load mock ZIP codes, but still load mock loans and stats below
      } else {
        // Only load mock data if no real data exists at all
        if (kDebugMode) {
          print('ℹ️ Loading mock data - no real loan officer data found');
        }
      }

      // IMPORTANT: NEVER add mock ZIP codes to _claimedZipCodes or _availableZipCodes
      // These lists should ONLY be populated from backend API
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error in _loadMockData: $e');
      }
    }

    // Mock loans
    _loans.value = [
      LoanModel(
        id: 'loan_1',
        loanOfficerId: 'loan_1',
        borrowerName: 'John Smith',
        borrowerEmail: 'john.smith@email.com',
        borrowerPhone: '(555) 123-4567',
        loanAmount: 450000.0,
        interestRate: 6.25,
        termInMonths: 360,
        loanType: 'conventional',
        status: 'approved',
        propertyAddress: '123 Main Street, New York, NY 10001',
        notes: 'Pre-approved buyer, excellent credit score',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      LoanModel(
        id: 'loan_2',
        loanOfficerId: 'loan_1',
        borrowerName: 'Emily Johnson',
        borrowerEmail: 'emily.j@email.com',
        borrowerPhone: '(555) 234-5678',
        loanAmount: 320000.0,
        interestRate: 5.75,
        termInMonths: 240,
        loanType: 'FHA',
        status: 'pending',
        propertyAddress: '456 Oak Avenue, Brooklyn, NY 11201',
        notes: 'First-time homebuyer, needs assistance',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      LoanModel(
        id: 'loan_3',
        loanOfficerId: 'loan_1',
        borrowerName: 'Michael Davis',
        borrowerEmail: 'michael.davis@email.com',
        borrowerPhone: '(555) 345-6789',
        loanAmount: 750000.0,
        interestRate: 6.50,
        termInMonths: 360,
        loanType: 'jumbo',
        status: 'funded',
        propertyAddress: '789 Park Place, Manhattan, NY 10021',
        notes: 'Jumbo loan, closed last month',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];

    // Mock stats
    _searchesAppearedIn.value = 67;
    _profileViews.value = 289;
    _contacts.value = 134;
    _totalRevenue.value = 599.99;
  }

  /// Fetches user stats (including subscriptions) from the API
  Future<void> fetchUserStats() async {
    const maxAttempts = 2;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
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

          // Handle response formats: {user: {...}}, {agent: {...}}, {officer: {...}}, or direct object
          final userData = responseData is Map
              ? (responseData['user'] ??
                  responseData['agent'] ??
                  responseData['officer'] ??
                  responseData['loanOfficer'] ??
                  responseData)
              : responseData;

          // Extract firstZipCodeClaimed from API (false = new user, true = old user)
          final firstZipCodeClaimedRaw = userData['firstZipCodeClaimed'];
          if (firstZipCodeClaimedRaw is bool) {
            _firstZipCodeClaimed.value = firstZipCodeClaimedRaw;
          }

          // Extract claimed ZIP codes from user profile (if present)
          final claimedZipCodesData =
              userData['claimedZipCodes'] as List<dynamic>? ?? [];
          if (claimedZipCodesData.isNotEmpty) {
            _syncClaimedZipCodesFromProfile(claimedZipCodesData, userId);
          } else {
            _profileClaimedZipCodes.clear();
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
                    'subscriptionStart': subJson['subscriptionStart']
                        ?.toString(),
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
        } else {
          if (kDebugMode) {
            print('⚠️ Unexpected status code: ${response.statusCode}');
          }
        }
        return;
      } on DioException catch (e) {
        final isTimeout =
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;
        if (kDebugMode) {
          print('❌ DioException fetching user stats (attempt $attempt):');
          print('   Type: ${e.type}');
          print('   Message: ${e.message}');
          print('   Response: ${e.response?.data}');
          print('   Status Code: ${e.response?.statusCode}');
        }
        if (isTimeout && attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error fetching user stats: $e');
          print('   Error type: ${e.runtimeType}');
        }
      }
      return;
    }
  }

  void _syncClaimedZipCodesFromProfile(
    List<dynamic> claimedZipCodesData,
    String userId,
  ) {
    final claimedZips = claimedZipCodesData
        .whereType<Map<String, dynamic>>()
        .map((zipJson) {
          final zipCode = zipJson['postalCode']?.toString() ?? '';
          if (zipCode.isEmpty) return null;

          final pop = zipJson['population'];
          final population = pop is int
              ? pop
              : (pop is num
                    ? pop.toInt()
                    : (int.tryParse(pop?.toString() ?? '') ?? 0));
          return LoanOfficerZipCodeModel(
            postalCode: zipCode,
            state: zipJson['state']?.toString() ?? '',
            population: population,
            claimedByOfficer: true,
            createdAt:
                DateTime.tryParse(zipJson['createdAt']?.toString() ?? '') ??
                DateTime.now(),
            updatedAt:
                DateTime.tryParse(zipJson['updatedAt']?.toString() ?? '') ??
                DateTime.now(),
          );
        })
        .whereType<LoanOfficerZipCodeModel>()
        .toList();

    if (claimedZips.isEmpty) return;

    _profileClaimedZipCodes
      ..clear()
      ..addAll(claimedZips.map((z) => z.postalCode));

    // Merge profile claimed ZIPs into local claimed list
    for (final zip in claimedZips) {
      if (!_claimedZipCodes.any((z) => z.postalCode == zip.postalCode)) {
        _claimedZipCodes.add(zip);
      }
    }

    // Ensure available list excludes claimed zip codes
    _availableZipCodes.removeWhere(
      (zip) => _profileClaimedZipCodes.contains(zip.postalCode),
    );

    if (kDebugMode) {
      print(
        '✅ Claimed ZIP codes synced from user profile: ${_profileClaimedZipCodes.length} items',
      );
    }
  }

  Future<void> claimZipCode(LoanOfficerZipCodeModel zipCode) async {
    // Prevent multiple simultaneous claims of the same zip code
    if (_loadingZipCodeIds.contains(zipCode.postalCode)) {
      return;
    }

    try {
      // Add to loading set for this specific zip code
      _loadingZipCodeIds.add(zipCode.postalCode);

      // Check if loan officer can claim more ZIP codes (max 6)
      if (_claimedZipCodes.length >= 6) {
        SnackbarHelper.showError('You can only claim up to 6 ZIP codes');
        return;
      }

      // Get current loan officer ID
      final currentLoanOfficerController =
          Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;

      final loanOfficerId =
          currentLoanOfficerController?.currentLoanOfficer.value?.id;

      if (loanOfficerId == null || loanOfficerId.isEmpty) {
        SnackbarHelper.showError('Loan officer information not available');
        return;
      }

      // Check if ZIP code is already claimed locally
      final isAlreadyClaimedLocally = _claimedZipCodes.any(
        (zip) => zip.postalCode == zipCode.postalCode,
      );
      if (isAlreadyClaimedLocally) {
        _showSnackbarSafely(
          'This ZIP code is already claimed by you.',
          isAlreadyClaimed: true,
        );
        return;
      }

      // Step 1: Proceed directly to payment (promo code is optional via bottom sheet)
      // Promo code can be entered via "Have a promo code?" link in the UI

      _setupDio();
      final authToken = _storage.read('auth_token');

      // Validate that rebates are allowed in this state before checkout
      final stateCode = _normalizeStateToCode(zipCode.state);
      final isStateAllowed = await _rebateStatesService.isStateAllowed(stateCode);
      if (!isStateAllowed) {
        SnackbarHelper.showError(
          'Real estate rebates are not permitted in ${zipCode.state}. Only states that allow rebates are available for subscription.',
        );
        _loadingZipCodeIds.remove(zipCode.postalCode);
        return;
      }

      // Step 1: Create checkout session
      final zipCodePrice = zipCode.calculatedPrice.toStringAsFixed(2);

      final requestBody = {
        'role': 'loanofficer',
        'population': zipCode.population.toString(),
        'userId': loanOfficerId,
        'zipcode': zipCode.postalCode,
        'price': zipCodePrice,
        'state': zipCode.state,
      };

      if (kDebugMode) {
        print(
          '💳 Creating checkout session for ZIP code: ${zipCode.postalCode}',
        );
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

        final sessionId =
            checkoutSessionId ?? _extractCheckoutSessionId(checkoutUrl);

        if (kDebugMode) {
          print('✅ Checkout session created: $checkoutUrl');
          print('   Checkout Session ID: $sessionId');
        }

        // Step 3: Open payment URL in in-app web view
        final paymentSuccess = await Get.to<bool>(
          () => PaymentWebView(checkoutUrl: checkoutUrl),
          fullscreenDialog: true,
        );

        // Step 4: If payment successful, call paymentSuccess API first,
        // then claim the ZIP code
        if (paymentSuccess == true) {
          if (sessionId != null && sessionId.isNotEmpty) {
            final paymentSuccessResult = await _callPaymentSuccessAPI(
              sessionId,
              authToken,
            );
            if (!paymentSuccessResult) {
              SnackbarHelper.showError(
                'Payment verification failed. Please contact support.',
              );
              return;
            }
          } else {
            if (kDebugMode) {
              print(
                '⚠️ No checkout session ID found, skipping paymentSuccess API',
              );
            }
          }

          await _completeZipCodeClaim(
            zipCode,
            loanOfficerId,
            currentLoanOfficerController,
          );
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
            lowerErrorMessage.contains('already claimed by another')) {
          isAlreadyClaimed = true;
          errorMessage =
              'This ZIP code is already claimed by another loan officer.';
        }

        if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (e.response?.statusCode == 400) {
          if (!isAlreadyClaimed &&
              errorMessage == 'Failed to initiate payment. Please try again.') {
            errorMessage =
                'Invalid request. The payment could not be processed. Please contact support.';
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

      if (isAlreadyClaimed) {
        _availableZipCodes.removeWhere(
          (zip) => zip.postalCode == zipCode.postalCode,
        );
      }

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
      // Remove from loading set
      _loadingZipCodeIds.remove(zipCode.postalCode);
    }
  }

  Future<void> _completeZipCodeClaim(
    LoanOfficerZipCodeModel zipCode,
    String loanOfficerId,
    CurrentLoanOfficerController? currentLoanOfficerController,
  ) async {
    try {
      // Prepare claim API body with all required fields
      // Required: id, zipcode, price, state, population
      final price = zipCode.calculatedPrice.toStringAsFixed(2);
      final population = zipCode.population.toString();
      final state = zipCode.state;

      await _loanOfficerZipCodeService.claimZipCode(
        loanOfficerId,
        zipCode.postalCode,
        price,
        state,
        population,
      );

      // IMPORTANT: Mark as pending claim to preserve instant update
      _pendingClaimedZipCodes.add(zipCode.postalCode);
      _pendingReleasedZipCodes.remove(zipCode.postalCode);

      // Update local state IMMEDIATELY for instant UI update
      final claimedZip = zipCode.copyWith(
        claimedByOfficer: true,
        updatedAt: DateTime.now(),
      );

      // INSTANTLY move from available to claimed (reactive update)
      _availableZipCodes.removeWhere(
        (zip) => zip.postalCode == zipCode.postalCode,
      );
      if (!_claimedZipCodes.any((z) => z.postalCode == zipCode.postalCode)) {
        _claimedZipCodes.add(claimedZip);
      }
      _firstZipCodeClaimed.value = true; // Mark as old user (has claimed)

      // Update the zip code in all zip codes list efficiently
      final index = _allZipCodes.indexWhere(
        (zip) => zip.postalCode == zipCode.postalCode,
      );
      if (index != -1) {
        _allZipCodes[index] = claimedZip;
      }

      // Reapply search filter if active
      _applySearchFilter();

      // Update cache with new data (only if state is valid)
      if (_currentState.value.isNotEmpty && _allZipCodes.isNotEmpty) {
        try {
          final parts = _currentState.value.split('_');
          if (parts.length == 2) {
            final cacheKey = _getCacheKey(parts[0], parts[1]);
            _saveZipCodesToCache(cacheKey, _allZipCodes, _currentState.value);
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Failed to update cache after claim: $e');
          }
        }
      }

      // Update subscription price based on new zip code
      _updateSubscriptionPrice();

      // IMPORTANT: Force refresh loan officer data to get updated claimedZipCodes
      if (currentLoanOfficerController != null && loanOfficerId.isNotEmpty) {
        currentLoanOfficerController
            .refreshData(loanOfficerId, true)
            .then((_) {
              final refreshedOfficer =
                  currentLoanOfficerController.currentLoanOfficer.value;
              if (refreshedOfficer != null) {
                final refreshedClaimed = refreshedOfficer.claimedZipCodes;
                if (refreshedClaimed.contains(zipCode.postalCode)) {
                  if (kDebugMode) {
                    print(
                      '✅ Backend confirmed claimed zip code: ${zipCode.postalCode}',
                    );
                  }
                  _pendingClaimedZipCodes.remove(zipCode.postalCode);
                } else {
                  if (kDebugMode) {
                    print(
                      '⚠️ Backend does not have claimed zip code yet: ${zipCode.postalCode} - keeping as pending',
                    );
                  }
                }
                _updateZipCodeLists();
              }
            })
            .catchError((e) {
              if (kDebugMode) {
                print('⚠️ Failed to refresh loan officer data after claim: $e');
              }
            });
      }

      SnackbarHelper.showSuccess(
        'ZIP code ${zipCode.postalCode} claimed successfully!',
      );
    } on LoanOfficerZipCodeServiceException catch (e) {
      SnackbarHelper.showError(e.message);
    } catch (e) {
      SnackbarHelper.showError('Failed to claim ZIP code: ${e.toString()}');
    }
  }

  /// Extracts checkout session ID from Stripe checkout URL
  String? _extractCheckoutSessionId(String checkoutUrl) {
    try {
      final uri = Uri.parse(checkoutUrl);
      final pathSegments = uri.pathSegments;

      for (final segment in pathSegments) {
        if (segment.startsWith('cs_')) {
          return segment;
        }
      }

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

  /// Helper method to show snackbar safely with proper context handling
  void _showSnackbarSafely(
    String message, {
    bool isError = true,
    bool isAlreadyClaimed = false,
  }) {
    if (isAlreadyClaimed) {
      SnackbarHelper.showWarning(message);
      return;
    }

    if (isError) {
      SnackbarHelper.showError(message);
      return;
    }

    SnackbarHelper.showSuccess(message);
  }

  /// Shows a promo code dialog before payment
  /// Returns the promo code if entered, or null if skipped/cancelled
  /// Shows a bottom sheet for entering promo code
  /// Returns the promo code if entered, null otherwise
  Future<String?> showPromoCodeBottomSheet() async {
    final promoCodeController = TextEditingController();

    final result = await Get.bottomSheet<String>(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Promo code',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.black,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    promoCodeController.dispose();
                    Get.back(result: null);
                  },
                  icon: Icon(Icons.close, color: AppTheme.black),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Text input field
            TextField(
              controller: promoCodeController,
              decoration: InputDecoration(
                hintText: 'Enter promo code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.mediumGray.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.mediumGray.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final code = promoCodeController.text.trim();
                  promoCodeController.dispose();
                  Get.back(result: code.isEmpty ? null : code);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Informational text
            Text(
              'Promo codes are optional. Apply before claiming to lock in 70% off.',
              style: TextStyle(fontSize: 12, color: AppTheme.mediumGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );

    return result;
  }

  Future<void> releaseZipCode(LoanOfficerZipCodeModel zipCode) async {
    // Prevent multiple simultaneous releases of the same zip code
    if (_loadingZipCodeIds.contains(zipCode.postalCode)) {
      return;
    }

    // Declare variables outside try block so they're accessible in catch block
    final currentLoanOfficerController =
        Get.isRegistered<CurrentLoanOfficerController>()
        ? Get.find<CurrentLoanOfficerController>()
        : null;

    final loanOfficerId =
        currentLoanOfficerController?.currentLoanOfficer.value?.id;

    try {
      // Add to loading set for this specific zip code
      _loadingZipCodeIds.add(zipCode.postalCode);

      if (loanOfficerId == null) {
        Get.snackbar(
          'Error',
          'Loan officer information not available',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // IMPORTANT: Verify zip code is actually claimed before attempting release
      // Check both local state and backend state
      final isClaimedLocally = _claimedZipCodes.any(
        (z) => z.postalCode == zipCode.postalCode,
      );
      final loanOfficer =
          currentLoanOfficerController?.currentLoanOfficer.value;
      final isClaimedOnBackend =
          loanOfficer?.claimedZipCodes.contains(zipCode.postalCode) ?? false;

      if (!isClaimedOnBackend && !isClaimedLocally) {
        // Not claimed anywhere, just remove from local state if it's there
        _claimedZipCodes.removeWhere(
          (zip) => zip.postalCode == zipCode.postalCode,
        );
        Get.snackbar(
          'Info',
          'ZIP code ${zipCode.postalCode} is not claimed',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // Call cancelSubscription API first; only on 200 OK proceed to release
      final authController = Get.find<global.AuthController>();
      final userId = authController.currentUser?.id ?? loanOfficerId;
      final activeSub = activeSubscriptionFromAPI;
      final stripeSubscriptionId = activeSub?['stripeSubscriptionId']?.toString() ??
          activeSub?['_id']?.toString() ??
          '';

      if (stripeSubscriptionId.isNotEmpty) {
        try {
          await _callCancelSubscriptionApi(stripeSubscriptionId, userId);
        } on DioException catch (e) {
          final statusCode = e.response?.statusCode;
          final data = e.response?.data;
          final message = data is Map
              ? (data['message'] ?? data['error'] ?? data['msg'])?.toString()
              : null;
          if (kDebugMode) {
            print('❌ Cancel subscription before release failed: $statusCode');
            print('   Message: $message');
            print('   Response: $data');
          }
          SnackbarHelper.showError(
            message?.isNotEmpty == true
                ? message!
                : 'Could not cancel subscription. Release aborted. Please try again.',
          );
          return;
        } catch (e) {
          if (kDebugMode) {
            print('❌ Cancel subscription before release failed: $e');
          }
          SnackbarHelper.showError(
            'Could not cancel subscription. Release aborted. Please try again.',
          );
          return;
        }
      }

      // Call API to release zip code
      await _loanOfficerZipCodeService.releaseZipCode(
        loanOfficerId,
        zipCode.postalCode,
      );

      // IMPORTANT: Mark as pending release to preserve instant update
      _pendingReleasedZipCodes.add(zipCode.postalCode);
      _pendingClaimedZipCodes.remove(
        zipCode.postalCode,
      ); // Remove from pending claims if there

      // Update local state - mark as available and remove claim
      final availableZip = zipCode.copyWith(
        claimedByOfficer: false,
        updatedAt: DateTime.now(),
      );

      // INSTANTLY move from claimed to available (reactive update)
      _claimedZipCodes.removeWhere(
        (zip) => zip.postalCode == zipCode.postalCode,
      );
      if (!_availableZipCodes.any((z) => z.postalCode == zipCode.postalCode)) {
        _availableZipCodes.add(availableZip);
      }

      // Update the zip code in all zip codes list efficiently
      final index = _allZipCodes.indexWhere(
        (zip) => zip.postalCode == zipCode.postalCode,
      );
      if (index != -1) {
        _allZipCodes[index] = availableZip;
      }

      // Reapply search filter if active
      _applySearchFilter();

      if (kDebugMode) {
        print('📊 After release update:');
        print('   Claimed: ${_claimedZipCodes.length}');
        print('   Available: ${_availableZipCodes.length}');
      }

      // Update cache with new data (only if state is valid)
      if (_currentState.value.isNotEmpty && _allZipCodes.isNotEmpty) {
        try {
          final parts = _currentState.value.split('_');
          if (parts.length == 2) {
            final cacheKey = _getCacheKey(parts[0], parts[1]);
            _saveZipCodesToCache(cacheKey, _allZipCodes, _currentState.value);
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Failed to update cache after release: $e');
          }
        }
      }

      // Update subscription price after releasing zip code
      _updateSubscriptionPrice();

      // Refresh the current loan officer data to get updated claimedZipCodes from backend (in background)
      if (currentLoanOfficerController != null && loanOfficerId.isNotEmpty) {
        // Don't await - let it run in background so UI stays responsive
        currentLoanOfficerController
            .refreshData(loanOfficerId, true)
            .then((_) {
              // Sync with backend - pending release will be preserved
              final refreshedOfficer =
                  currentLoanOfficerController.currentLoanOfficer.value;
              if (refreshedOfficer != null) {
                final refreshedClaimed = refreshedOfficer.claimedZipCodes;
                // If backend confirmed the release (not in claimed list), remove from pending
                if (!refreshedClaimed.contains(zipCode.postalCode)) {
                  if (kDebugMode) {
                    print(
                      '✅ Backend confirmed released zip code: ${zipCode.postalCode}',
                    );
                  }
                  _pendingReleasedZipCodes.remove(zipCode.postalCode);
                } else {
                  if (kDebugMode) {
                    print(
                      '⚠️ Backend still has released zip code: ${zipCode.postalCode} - keeping as pending',
                    );
                  }
                  // Keep as pending - backend might have a delay
                }
                // Update lists - pending releases will be preserved
                _updateZipCodeLists();
              }
            })
            .catchError((e) {
              if (kDebugMode) {
                print(
                  '⚠️ Failed to refresh loan officer data after release: $e',
                );
              }
            });
      }

      // Use SnackbarHelper + post-frame to avoid "No Overlay widget found" after async work
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackbarHelper.showSuccess(
          'ZIP code ${zipCode.postalCode} released successfully!',
        );
      });
    } on LoanOfficerZipCodeServiceException catch (e) {
      // If backend says zip code is not claimed, sync local state with backend
      if (e.message.contains('not claimed') ||
          e.message.contains('You have not claimed')) {
        if (kDebugMode) {
          print(
            '🔄 Backend says zip code is not claimed - syncing local state',
          );
        }

        // Remove from local claimed list
        _claimedZipCodes.removeWhere(
          (zip) => zip.postalCode == zipCode.postalCode,
        );

        // IMPORTANT: Force refresh loan officer data to get accurate state from backend
        // Clear all claimed zip codes first, then refresh
        _claimedZipCodes.clear();

        if (currentLoanOfficerController != null &&
            loanOfficerId != null &&
            loanOfficerId.isNotEmpty) {
          // Force refresh to bypass cache and get latest data
          currentLoanOfficerController
              .refreshData(loanOfficerId, true)
              .then((_) {
                // Update zip code lists with fresh data from backend
                _updateZipCodeLists();
              })
              .catchError((refreshError) {
                if (kDebugMode) {
                  print(
                    '⚠️ Failed to refresh after release error: $refreshError',
                  );
                }
                // Even if refresh fails, update lists to reflect cleared state
                _updateZipCodeLists();
              });
        } else {
          // If no controller, just update lists to reflect cleared state
          _updateZipCodeLists();
        }

        Get.snackbar(
          'Info',
          'ZIP code ${zipCode.postalCode} is not claimed on the server. Local state has been updated.',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar('Error', e.message, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to release ZIP code: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      // Remove from loading set
      _loadingZipCodeIds.remove(zipCode.postalCode);
    }
  }

  // Debounce timer for search optimization
  Timer? _searchDebounceTimer;

  /// Searches zip codes with debouncing for optimal performance
  void searchZipCodes(String query) {
    _searchQuery.value = query;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applySearchFilter();
    });
  }

  /// Filter displayed ZIPs by search prefix (from state list).
  void filterZipCodesBySearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _allZipCodes.value = List.from(_stateZipCodesFromApi);
      _updateZipCodeLists();
      return;
    }
    final filtered = _stateZipCodesFromApi
        .where((z) => z.postalCode.toLowerCase().startsWith(q))
        .toList();
    _allZipCodes.value = filtered;
    _updateZipCodeLists();
  }

  /// Uses cached current location zip for the ZIP search field (instant, no fetch on tap).
  void useCurrentLocationForZip() {
    final zipCode = _locationController.currentZipCode;
    if (zipCode != null &&
        zipCode.length == 5 &&
        RegExp(r'^\d+$').hasMatch(zipCode)) {
      zipSearchController.text = zipCode;
      zipSearchController.selection = TextSelection.collapsed(offset: zipCode.length);
      onZipSearchChanged(zipCode);
    } else {
      SnackbarHelper.showInfo(
        'Location not ready yet. Please wait a moment and try again, or enter ZIP manually.',
        title: 'Location',
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Search bar onChanged: filter by prefix, or when 5 digits typed auto validate → fetch.
  void onZipSearchChanged(String query) {
    _zipVerifyDebounce?.cancel();
    final q = query.trim();
    if (q.length < 5) {
      filterZipCodesBySearch(query);
      return;
    }
    if (q.length == 5 && RegExp(r'^\d{5}$').hasMatch(q)) {
      _zipVerifyDebounce = Timer(const Duration(milliseconds: 400), _validateAndFetchZip);
      return;
    }
    filterZipCodesBySearch(query);
  }

  /// Validate ZIP via API, then fetch results. Show snackbar on invalid.
  Future<void> _validateAndFetchZip() async {
    final state = _selectedState.value;
    if (state == null || state.isEmpty) {
      SnackbarHelper.showError('Please select a state first');
      return;
    }
    final zip = zipSearchController.text.trim();
    if (zip.length != 5 || !RegExp(r'^\d{5}$').hasMatch(zip)) return;

    try {
      _isLoadingZipCodes.value = true;
      await _loanOfficerZipCodeService.validateZipCode(zipcode: zip, state: state);
      const country = 'US';
      final list = await _loanOfficerZipCodeService.verifyZipCode(country, state, zip);
      _allZipCodes.value = list;
      _updateZipCodeLists();
    } on LoanOfficerZipCodeServiceException catch (e) {
      if (kDebugMode) print('❌ Validate ZIP: ${e.message}');
      SnackbarHelper.showError(e.message);
      _allZipCodes.value = List.from(_stateZipCodesFromApi);
      _updateZipCodeLists();
    } catch (e) {
      if (kDebugMode) print('❌ Validate ZIP: $e');
      SnackbarHelper.showError('Failed to validate or fetch ZIP: ${e.toString()}');
      _allZipCodes.value = List.from(_stateZipCodesFromApi);
      _updateZipCodeLists();
    } finally {
      _isLoadingZipCodes.value = false;
    }
  }

  /// Refreshes zip codes from the API (forces reload)
  /// IMPORTANT: Clears lists first to prevent showing mock/stale data
  Future<void> refreshZipCodes() async {
    // IMPORTANT: Clear pending claims/releases on manual refresh
    // This ensures we get fresh state from backend
    _pendingClaimedZipCodes.clear();
    _pendingReleasedZipCodes.clear();

    // Clear lists first to prevent showing stale data
    _claimedZipCodes.clear();
    _availableZipCodes.clear();

    // Force refresh from API
    await _loadZipCodes(forceRefresh: true);
  }

  /// Sets the selected state and fetches ZIP codes for that state
  /// [stateName] can be either full state name (e.g., "Alabama") or state code (e.g., "AL")
  Future<void> selectStateAndFetchZipCodes(String stateName) async {
    if (stateName.isEmpty) {
      _selectedState.value = null;
      _stateZipCodesFromApi.clear();
      _allZipCodes.clear();
      _availableZipCodes.clear();
      zipSearchController.clear();
      return;
    }

    final code = _normalizeStateToCode(stateName);
    if (_selectedState.value == code) return;

    _selectedState.value = code;
    await _loadZipCodesForState(code, forceRefresh: false);
  }

  /// Loads zip codes for a specific state
  Future<void> _loadZipCodesForState(
    String stateName, {
    bool forceRefresh = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (_isLoadingZipCodes.value && !forceRefresh) {
      if (kDebugMode) {
        print('⏳ Zip codes already loading, skipping duplicate request');
      }
      return;
    }

    try {
      const country = 'US';
      final state = _normalizeStateToCode(stateName);
      final stateKey = '${country}_$state';
      final cacheKey = _getCacheKey(country, state);

      zipSearchController.clear();

      if (!forceRefresh &&
          _hasLoadedZipCodes.value &&
          _currentState.value == stateKey) {
        if (_allZipCodes.isNotEmpty) {
          if (kDebugMode) {
            print('📦 Zip codes already loaded in memory, using cached data');
          }
          _updateZipCodeLists();
          return;
        }
      }

      if (!forceRefresh) {
        try {
          final cachedZipCodes = _readCachedZipCodes(cacheKey);
          if (cachedZipCodes != null && cachedZipCodes.isNotEmpty) {
            _stateZipCodesFromApi.clear();
            _stateZipCodesFromApi.addAll(cachedZipCodes);
            _allZipCodes.value = List.from(_stateZipCodesFromApi);
            _currentState.value = stateKey;
            _updateZipCodeLists();
            _hasLoadedZipCodes.value = true;

            if (kDebugMode) {
              print('📦 Loaded ${cachedZipCodes.length} zip codes from cache');
            }
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error reading from GetStorage: $e');
          }
        }
      }

      // Only fetch from API if cache is empty or force refresh
      _isLoadingZipCodes.value = true;

      if (kDebugMode) {
        print('📡 Loading zip codes from API (getstateZip)');
        print('   Country: $country');
        print('   State: $state');
        print('   Force refresh: $forceRefresh');
      }

      final zipCodes = await _loanOfficerZipCodeService.getStateZipCodes(
        country,
        state,
      );

      if (zipCodes.isEmpty) {
        if (kDebugMode) {
          print('⚠️ API returned empty zip codes list');
        }
        _isLoadingZipCodes.value = false;
        return;
      }

      _stateZipCodesFromApi.clear();
      _stateZipCodesFromApi.addAll(zipCodes);
      _allZipCodes.value = List.from(_stateZipCodesFromApi);
      _currentState.value = stateKey;

      Future.microtask(() {
        _saveZipCodesToCache(cacheKey, zipCodes, stateKey);
      });

      _updateZipCodeLists();

      _hasLoadedZipCodes.value = true;

      if (kDebugMode) {
        print('✅ Loaded ${zipCodes.length} zip codes from API');
        print('   Claimed: ${_claimedZipCodes.length}');
        print('   Available: ${_availableZipCodes.length}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error loading zip codes: $e');
        print('   Stack trace: $stackTrace');
      }
      _isLoadingZipCodes.value = false;
    } finally {
      _isLoadingZipCodes.value = false;
    }
  }

  /// Parses amountPaid from a subscription map (may be num or double from JSON).
  static double _amountPaidFromSub(Map<String, dynamic> sub) {
    final v = sub['amountPaid'];
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return 0.0;
  }

  /// Current Monthly = sum of amountPaid of all active subscriptions on this screen.
  double calculateMonthlyCost() {
    final active = activeSubscriptions;
    if (active.isNotEmpty) {
      double sum = 0.0;
      for (final sub in active) {
        sum += _amountPaidFromSub(sub);
      }
      if (sum > 0) return sum;
    }

    // If in free period, return 0
    if (_subscription.value?.isInFreePeriod == true) {
      return 0.0;
    }

    // Fallback: Calculate from ZIP codes
    return LoanOfficerZipCodePricingService.calculateTotalMonthlyPrice(
      _claimedZipCodes,
    );
  }

  /// Standard = lowest price among active subscriptions on this screen.
  double getStandardMonthlyPrice() {
    final active = activeSubscriptions;
    if (active.isNotEmpty) {
      double? lowest;
      for (final sub in active) {
        final amount = _amountPaidFromSub(sub);
        if (amount > 0) {
          if (lowest == null || amount < lowest) lowest = amount;
        }
      }
      if (lowest != null && lowest > 0) return lowest;
    }

    return standardMonthlyPrice;
  }

  /// Update subscription base price based on claimed zip codes
  void _updateSubscriptionPrice() {
    if (_subscription.value == null) return;

    // Calculate new base price from claimed zip codes using population-based pricing
    final newBasePrice =
        LoanOfficerZipCodePricingService.calculateTotalMonthlyPrice(
          _claimedZipCodes,
        );

    // If no zip codes claimed, use fallback price
    final basePrice = newBasePrice > 0 ? newBasePrice : standardMonthlyPrice;

    // Calculate current price (if in free period, it's 0)
    double currentPrice = basePrice;
    if (_subscription.value!.isInFreePeriod) {
      currentPrice = 0.0;
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
        Get.snackbar(
          'Error',
          'Invalid or expired promo code',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      if (promoCode.type != PromoCodeType.loanOfficer6MonthsFree) {
        Get.snackbar(
          'Error',
          'This promo code is not valid for loan officers',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // Check if promo is still valid
      if (!promoCode.isValid) {
        Get.snackbar(
          'Error',
          'This promo code has expired or reached its usage limit',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // Check if already has active promo
      if (_subscription.value?.isInFreePeriod == true) {
        Get.snackbar(
          'Info',
          'You already have an active promotion',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // Calculate free period end date (6 months from now)
      final freePeriodEndsAt = DateTime.now().add(
        const Duration(days: 180),
      ); // 6 months

      // Apply promo to subscription
      final currentSub = _subscription.value!;

      // Ensure base price is up to date before applying promo
      final basePrice =
          LoanOfficerZipCodePricingService.calculateTotalMonthlyPrice(
            _claimedZipCodes,
          );
      final finalBasePrice = basePrice > 0 ? basePrice : standardMonthlyPrice;

      _subscription.value = currentSub.copyWith(
        status: SubscriptionStatus.promo,
        activePromoCode: promoCode,
        isPromoActive: true,
        freeMonthsRemaining: 6,
        freePeriodEndsAt: freePeriodEndsAt,
        baseMonthlyPrice: finalBasePrice, // Update base price from zip codes
        currentMonthlyPrice: 0.0, // Free during promo period
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
        'Promo code applied! You now have 6 months free. After that, you can continue at the normal subscription rate.',
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to apply promo code: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
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

    // Accept codes starting with "LO" (Loan Officer promo codes from agents)
    // In production, this would check against database
    if (code.toUpperCase().startsWith('LO')) {
      return PromoCodeModel(
        id: 'promo_${DateTime.now().millisecondsSinceEpoch}',
        code: code.toUpperCase(),
        type: PromoCodeType.loanOfficer6MonthsFree,
        status: PromoCodeStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: null, // No expiration for agent-generated codes
        maxUses: 1,
        currentUses: 0,
        freeMonths: 6,
        description: '6 Months Free for Loan Officers',
      );
    }

    return null;
  }

  /// Calls POST /api/v1/subscription/cancelSubscription with body { subscriptionId, userId }.
  /// Returns response data on status 200, throws on failure.
  Future<Map<String, dynamic>> _callCancelSubscriptionApi(
    String subscriptionId,
    String userId,
  ) async {
    final authToken = _storage.read('auth_token');
    final path = ApiConstants.cancelSubscriptionEndpoint.replaceFirst(_baseUrl, '');
    // Backend expects stripeSubscriptionId (e.g. sub_xxx or pi_xxx) in subscriptionId field
    final body = {'subscriptionId': subscriptionId, 'userId': userId};
    if (kDebugMode) {
      print('📡 POST cancelSubscription: $_baseUrl$path');
      print('   Body (subscriptionId = stripeSubscriptionId): $body');
    }
    final response = await _dio.post(
      path,
      data: body,
      options: Options(
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ),
    );
    if (response.statusCode == 200) {
      final data = response.data;
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    }
    throw Exception(
      'Cancel subscription failed: ${response.statusCode}',
    );
  }

  /// Cancels a specific subscription (by stripeCustomerId for UI, uses subscriptionId + userId for API).
  Future<void> cancelSubscription([String? stripeCustomerId]) async {
    try {
      _isLoading.value = true;

      final authController = Get.find<global.AuthController>();
      final userId = authController.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        SnackbarHelper.showError('User not authenticated. Please login again.');
        return;
      }

      Map<String, dynamic>? activeSub;
      if (stripeCustomerId != null && stripeCustomerId.isNotEmpty) {
        try {
          activeSub = _subscriptions.firstWhere(
            (sub) =>
                sub['stripeCustomerId']?.toString() == stripeCustomerId,
          );
        } catch (_) {
          activeSub = null;
        }
      } else {
        activeSub = activeSubscriptionFromAPI;
      }

      if (activeSub == null) {
        SnackbarHelper.showError('No active subscription found');
        return;
      }

      final stripeSubscriptionId = activeSub['stripeSubscriptionId']?.toString() ??
          activeSub['_id']?.toString() ??
          '';
      if (stripeSubscriptionId.isEmpty) {
        SnackbarHelper.showError('Stripe subscription ID not found');
        return;
      }

      final status =
          activeSub['subscriptionStatus']?.toString().toLowerCase() ?? '';
      if (status == 'canceled' || status == 'cancelled') {
        SnackbarHelper.showError('Subscription is already cancelled');
        return;
      }

      if (kDebugMode) {
        print('📡 Cancelling subscription');
        print('   stripeSubscriptionId: $stripeSubscriptionId');
        print('   userId: $userId');
      }

      final responseData =
          await _callCancelSubscriptionApi(stripeSubscriptionId, userId);

      if (kDebugMode) {
        print('📥 Cancel subscription response: 200 OK');
        print('   Response: $responseData');
      }

      await fetchUserStats();
      final billingPortalUrl = responseData['url'] as String?;

      if (billingPortalUrl != null && billingPortalUrl.isNotEmpty) {
        if (kDebugMode) {
          print('🌐 Opening Stripe billing portal: $billingPortalUrl');
        }
        final uri = Uri.parse(billingPortalUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          SnackbarHelper.showSuccess(
            'Subscription cancellation processed. Your subscription status has been updated.',
            title: 'Success',
          );
        });
      });
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling subscription:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Response: ${e.response?.data}');
        print('   Status Code: ${e.response?.statusCode}');
      }

      String errorMessage =
          'Failed to cancel subscription. Please try again.';
      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Subscription not found.';
        } else if (e.response?.statusCode == 400) {
          errorMessage = (responseData is Map &&
                  responseData.containsKey('message'))
              ? responseData['message'].toString()
              : 'Invalid request. Please contact support.';
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Request timed out. Please try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage =
              'Unable to connect. Please check your internet connection.';
        }
      }
      SnackbarHelper.showError(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error cancelling subscription: $e');
      }
      NetworkErrorHandler.handleError(
        e,
        defaultMessage:
            'Unable to cancel subscription. Please try again later.',
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
    if (sub?.isInFreePeriod == true && sub?.freePeriodEndsAt != null) {
      if (DateTime.now().isAfter(sub!.freePeriodEndsAt!)) {
        // Free period ended, transition to normal pricing
        final zipCodeCost =
            LoanOfficerZipCodePricingService.calculateTotalMonthlyPrice(
              _claimedZipCodes,
            );
        _subscription.value = sub.copyWith(
          status: SubscriptionStatus.active,
          isPromoActive: false,
          activePromoCode: null,
          currentMonthlyPrice: zipCodeCost > 0
              ? zipCodeCost
              : sub.baseMonthlyPrice,
          freeMonthsRemaining: 0,
          freePeriodEndsAt: null,
          updatedAt: DateTime.now(),
        );

        Get.snackbar(
          'Info',
          'Your free period has ended. You are now on the normal subscription rate.',
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
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

  Future<bool> joinWaitingList(LoanOfficerZipCodeModel zipCode) async {
    if (_waitingListRequests.contains(zipCode.postalCode)) {
      return false;
    }

    final authController = Get.find<global.AuthController>();
    final user = authController.currentUser;

    if (user == null) {
      Get.snackbar('Error', 'Please log in to join the waiting list');
      return false;
    }

    _waitingListRequests.add(zipCode.postalCode);
    try {
      final zipCodeId = zipCode.id ?? zipCode.postalCode;
      final requestBody = {
        'name': user.name.isNotEmpty ? user.name : 'Loan Officer',
        'email': user.email,
        'zipCodeId': zipCodeId,
        'userId': user.id,
      };

      if (kDebugMode) {
        print('📡 Joining waiting list for ZIP ${zipCode.postalCode}');
        print('   Payload: $requestBody');
      }

      final authToken = _storage.read('auth_token');
      final response = await _dio.post(
        '/waiting-list',
        data: requestBody,
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (kDebugMode) {
        print(
          '📥 Waiting list response: ${response.statusCode} ${response.data}',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchWaitingListEntries(zipCodeId);
        _addCurrentUserToZipWaitingUsers(zipCode, user.id);
        return true;
      }

      throw Exception('Unexpected response: ${response.statusCode}');
    } catch (e) {
      NetworkErrorHandler.handleError(
        e,
        defaultMessage:
            'Unable to join the waiting list right now. Please try again.',
      );
      return false;
    } finally {
      _waitingListRequests.remove(zipCode.postalCode);
    }
  }

  void _addCurrentUserToZipWaitingUsers(LoanOfficerZipCodeModel zip, String userId) {
    if (zip.waitingUsers.contains(userId)) return;
    final updated = zip.copyWith(
      waitingUsers: [...zip.waitingUsers, userId],
    );
    final key = zip.postalCode;
    for (var i = 0; i < _allZipCodes.length; i++) {
      if (_allZipCodes[i].postalCode == key) {
        _allZipCodes[i] = updated;
        break;
      }
    }
    for (var i = 0; i < _availableZipCodes.length; i++) {
      if (_availableZipCodes[i].postalCode == key) {
        _availableZipCodes[i] = updated;
        break;
      }
    }
    _allZipCodes.refresh();
    _availableZipCodes.refresh();
    _applySearchFilter();
  }

  Future<List<WaitingListEntry>> fetchWaitingListEntries(
    String zipCodeId,
  ) async {
    if (zipCodeId.isEmpty) {
      return [];
    }

    if (_waitingListLoading.contains(zipCodeId)) {
      return _waitingListEntries[zipCodeId] ?? [];
    }

    _waitingListLoading.add(zipCodeId);
    try {
      final authToken = _storage.read('auth_token');
      final response = await _dio.get(
        '/waiting-list/$zipCodeId',
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      final data = response.data;
      if (data is List) {
        final entries = data
            .whereType<Map<String, dynamic>>()
            .map((json) => WaitingListEntry.fromJson(json))
            .toList();
        _waitingListEntries[zipCodeId] = entries;
        return entries;
      }

      return _waitingListEntries[zipCodeId] ?? [];
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Waiting list fetch error: ${e.message}');
      }
      throw e;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Waiting list fetch unexpected: $e');
      }
      throw e;
    } finally {
      _waitingListLoading.remove(zipCodeId);
    }
  }

  Future<void> _prefetchWaitingLists(List<LoanOfficerZipCodeModel> zipCodes) async {
    for (final zip in zipCodes) {
      final zipId = zip.id ?? zip.postalCode;
      if (zip.claimedByOfficer == true &&
          !_waitingListEntries.containsKey(zipId)) {
        // Use Future.microtask or just call it without await to not block
        fetchWaitingListEntries(zipId);
      }
    }
  }

  Future<void> addLoan(LoanModel loan) async {


    try {
      _isLoading.value = true;
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _loans.insert(0, loan);
      Get.snackbar(
        'Success',
        'Loan added successfully!',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add loan: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateLoan(LoanModel updatedLoan) async {
    try {
      _isLoading.value = true;
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      final index = _loans.indexWhere((loan) => loan.id == updatedLoan.id);
      if (index != -1) {
        _loans[index] = updatedLoan.copyWith(updatedAt: DateTime.now());
      }
      Get.snackbar(
        'Success',
        'Loan updated successfully!',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update loan: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteLoan(String loanId) async {
    try {
      _isLoading.value = true;
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _loans.removeWhere((loan) => loan.id == loanId);
      Get.snackbar(
        'Success',
        'Loan deleted successfully!',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete loan: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      _isLoading.value = false;
    }
  }
}

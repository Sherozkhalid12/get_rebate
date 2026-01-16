import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getrebate/app/models/zip_code_model.dart';
import 'package:getrebate/app/models/loan_model.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/models/subscription_model.dart';
import 'package:getrebate/app/models/promo_code_model.dart';
import 'package:getrebate/app/services/zip_code_pricing_service.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/controllers/current_loan_officer_controller.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';

import '../../../zipcodeservice.dart';

class LoanOfficerController extends GetxController {
  // Services
  final ZipCodeService _zipCodeService;
  final GetStorage _storage;

  // Storage keys
  static const String _zipCodesCacheKeyPrefix = 'zip_codes_cache_';
  static const String _lastStateKey = 'zip_codes_last_state';

  LoanOfficerController({
    ZipCodeService? zipCodeService,
    GetStorage? storage,
  })  : _zipCodeService = zipCodeService ?? ZipCodeService(),
        _storage = storage ?? GetStorage();

  // Data
  final _claimedZipCodes = <ZipCodeModel>[].obs;
  final _availableZipCodes = <ZipCodeModel>[].obs;
  final _allZipCodes = <ZipCodeModel>[].obs; // All zip codes from API
  final _filteredAvailableZipCodes = <ZipCodeModel>[].obs; // Filtered available zip codes for search
  final _filteredClaimedZipCodes = <ZipCodeModel>[].obs; // Filtered claimed zip codes for search
  final _searchQuery = ''.obs; // Current search query
  final _loans = <LoanModel>[].obs;
  final _isLoading = false.obs;
  final _isLoadingZipCodes = false.obs;
  final _hasLoadedZipCodes = false.obs; // Cache flag to prevent reloading
  final _loadingZipCodeIds = <String>{}.obs; // Track which zip codes are being processed
  final _currentState = ''.obs; // Track current state for cache invalidation
  final _selectedTab = 0
      .obs; // 0: Dashboard, 1: Messages, 2: ZIP Management, 3: Billing

  // Stats
  final _searchesAppearedIn = 0.obs;
  final _profileViews = 0.obs;
  final _contacts = 0.obs;
  final _totalRevenue = 0.0.obs;

  // Subscription & Promo Code
  final _subscription = Rxn<SubscriptionModel>();
  final _promoCodeInput = ''.obs;

  // Standard pricing (deprecated - now using zip code population-based pricing)
  // Kept for backward compatibility, but pricing is now calculated from zip codes
  @Deprecated('Use ZipCodePricingService instead')
  static const double standardMonthlyPrice = 17.99;

  // Getters
  List<ZipCodeModel> get claimedZipCodes => _claimedZipCodes;
  List<ZipCodeModel> get availableZipCodes => _availableZipCodes;
  List<ZipCodeModel> get filteredClaimedZipCodes => _filteredClaimedZipCodes;
  List<ZipCodeModel> get filteredAvailableZipCodes => _filteredAvailableZipCodes;
  List<LoanModel> get loans => _loans;
  bool get isLoading => _isLoading.value;
  bool get isLoadingZipCodes => _isLoadingZipCodes.value;
  bool get hasLoadedZipCodes => _hasLoadedZipCodes.value;
  String get searchQuery => _searchQuery.value;

  /// Check if a specific zip code is being processed
  bool isZipCodeLoading(String zipCode) => _loadingZipCodeIds.contains(zipCode);
  int get selectedTab => _selectedTab.value;
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
  int get daysUntilCancellation => _subscription.value?.daysUntilCancellation ?? 0;
  DateTime? get freePeriodEndsAt => _subscription.value?.freePeriodEndsAt;
  int? get freeMonthsRemaining => _subscription.value?.freeMonthsRemaining;

  @override
  void onInit() {
    super.onInit();
    _loadMockData();
    _initializeSubscription();
    checkPromoExpiration(); // Check if free period has ended

    // Preload chat threads for instant access when loan officer opens messages
    _preloadThreads();

    // Listen to loan officer changes to sync ZIP codes
    _setupLoanOfficerListener();

    // Load zip codes AFTER page renders (deferred for instant page load)
    // Use Future.delayed to ensure page renders first, then loads data
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadZipCodes();
    });
  }

  /// Sets up a listener to sync ZIP codes when loan officer data changes
  void _setupLoanOfficerListener() {
    try {
      final currentLoanOfficerController = Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;

      if (currentLoanOfficerController != null) {
        // Listen to changes in currentLoanOfficer and update ZIP code lists
        ever(currentLoanOfficerController.currentLoanOfficer, (LoanOfficerModel? officer) {
          if (officer != null && _allZipCodes.isNotEmpty) {
            if (kDebugMode) {
              print('🔄 Loan officer data updated, syncing ZIP codes...');
              print('   Claimed ZIP codes from model: ${officer.claimedZipCodes}');
            }
            // Update ZIP code lists to reflect claimed ZIP codes from the model
            _updateZipCodeLists();
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
    // Cancel search debounce timer to prevent memory leaks
    _searchDebounceTimer?.cancel();
    super.onClose();
  }

  /// Gets the cache key for zip codes based on country and state
  String _getCacheKey(String country, String state) {
    return '$_zipCodesCacheKeyPrefix${country}_$state';
  }

  /// Loads zip codes from cache or API
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
      final currentLoanOfficerController = Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;

      final loanOfficer = currentLoanOfficerController?.currentLoanOfficer.value;

      // Country is always US, only state changes
      const country = 'US';
      final state = (loanOfficer?.licensedStates.isNotEmpty == true)
          ? loanOfficer!.licensedStates.first
          : 'CA'; // Default to CA if no licensed states

      final stateKey = '${country}_$state';
      final cacheKey = _getCacheKey(country, state);

      // ALWAYS check memory cache first (fastest)
      if (!forceRefresh && _hasLoadedZipCodes.value && _currentState.value == stateKey) {
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
          final cachedData = _storage.read<String>(cacheKey);
          if (cachedData != null && cachedData.isNotEmpty) {
            try {
              final List<dynamic> jsonList = jsonDecode(cachedData);
              if (jsonList.isNotEmpty) {
                final cachedZipCodes = jsonList
                    .map((json) {
                  try {
                    return ZipCodeModel.fromJson(json as Map<String, dynamic>);
                  } catch (e) {
                    if (kDebugMode) {
                      print('⚠️ Failed to parse zip code item: $e');
                    }
                    return null;
                  }
                })
                    .whereType<ZipCodeModel>()
                    .toList();

                if (cachedZipCodes.isNotEmpty) {
                  // Update reactive state using GetX
                  _allZipCodes.value = cachedZipCodes;
                  _currentState.value = stateKey;
                  _updateZipCodeLists();
                  _hasLoadedZipCodes.value = true;

                  if (kDebugMode) {
                    print('✅ Loaded ${cachedZipCodes.length} zip codes from GetStorage');
                    print('   State: $state');
                  }

                  // Skip background refresh if data is fresh (prevent unnecessary API calls)
                  // Only refresh if cache is older than 1 hour
                  try {
                    final lastCacheTimeStr = _storage.read<String>('${cacheKey}_timestamp');
                    DateTime? lastCacheTime;
                    if (lastCacheTimeStr != null) {
                      lastCacheTime = DateTime.tryParse(lastCacheTimeStr);
                    }
                    final shouldRefresh = lastCacheTime == null ||
                        DateTime.now().difference(lastCacheTime).inHours >= 1;

                    if (shouldRefresh) {
                      // Refresh cache in background (non-blocking, delayed to avoid conflicts)
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
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Failed to parse cached zip codes: $e');
              }
              // Clear invalid cache
              _storage.remove(cacheKey);
            }
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
        print('📡 Loading zip codes from API');
        print('   Country: $country');
        print('   State: $state');
        print('   Force refresh: $forceRefresh');
      }

      final zipCodes = await _zipCodeService.getZipCodes(country, state);

      if (zipCodes.isEmpty) {
        if (kDebugMode) {
          print('⚠️ API returned empty zip codes list');
        }
        _isLoadingZipCodes.value = false;
        return;
      }

      // Update reactive state using GetX
      _allZipCodes.value = zipCodes;
      _currentState.value = stateKey;

      // Save to GetStorage (persistent cache) - do this in background to avoid blocking
      Future.microtask(() {
        _saveZipCodesToCache(cacheKey, zipCodes, stateKey);
      });

      // Separate claimed and available zip codes
      _updateZipCodeLists();

      // Mark as loaded
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

      // Show error only if no cached data available
      if (_allZipCodes.isEmpty) {
        Get.snackbar(
          'Error',
          'Failed to load zip codes. Please check your connection.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      _isLoadingZipCodes.value = false;
    }
  }

  /// Saves zip codes to GetStorage cache with error handling
  /// Optimized for large datasets with chunked processing
  void _saveZipCodesToCache(String cacheKey, List<ZipCodeModel> zipCodes, String stateKey) {
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
      _storage.write('${cacheKey}_timestamp', DateTime.now().toIso8601String()); // Cache timestamp as string

      if (kDebugMode) {
        final sizeKB = (jsonString.length / 1024).toStringAsFixed(2);
        print('💾 Saved ${zipCodes.length} zip codes to GetStorage ($sizeKB KB)');
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
            print('💾 Saved subset (${subset.length} zip codes) to cache as fallback');
          }
        }
      } catch (e2) {
        if (kDebugMode) {
          print('⚠️ Fallback cache save also failed: $e2');
        }
      }
    }
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

      // Check again after delay
      if (_isLoadingZipCodes.value) {
        return;
      }

      final zipCodes = await _zipCodeService.getZipCodes(country, state);

      if (zipCodes.isEmpty) {
        return;
      }

      final cacheKey = _getCacheKey(country, state);
      final stateKey = '${country}_$state';

      // Only update if state hasn't changed (prevent race conditions)
      if (_currentState.value == stateKey && !_isLoadingZipCodes.value) {
        // Update cache without updating UI (silent update to avoid blocking)
        _saveZipCodesToCache(cacheKey, zipCodes, stateKey);

        // Only update UI if user is on zip codes tab and data changed significantly
        if (_selectedTab.value == 2 && zipCodes.length != _allZipCodes.length) {
          _allZipCodes.value = zipCodes;
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

  /// Updates the claimed and available zip code lists based on all zip codes
  /// Uses GetX reactive state management for optimal performance
  void _updateZipCodeLists() {
    try {
      final currentLoanOfficerController = Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;

      final loanOfficerId = currentLoanOfficerController?.currentLoanOfficer.value?.id;

      if (loanOfficerId == null || loanOfficerId.isEmpty) {
        // If no loan officer, treat all as available
        _availableZipCodes.value = List.from(_allZipCodes);
        _claimedZipCodes.value = [];
        _applySearchFilter(); // Apply search if active
        return;
      }

      // Get the loan officer's claimedZipCodes array from the model
      final loanOfficer = currentLoanOfficerController?.currentLoanOfficer.value;
      final claimedZipCodesFromModel = loanOfficer?.claimedZipCodes ?? <String>[];

      // Separate claimed and available zip codes efficiently
      final claimed = <ZipCodeModel>[];
      final available = <ZipCodeModel>[];

      for (final zip in _allZipCodes) {
        // Check if this zip code is claimed by the current loan officer
        // Check both: 1) claimedByLoanOfficer field, 2) claimedZipCodes array from loan officer model
        final isClaimedByField = zip.claimedByLoanOfficer != null && zip.claimedByLoanOfficer == loanOfficerId;
        final isClaimedInModel = claimedZipCodesFromModel.contains(zip.zipCode);

        if (isClaimedByField || isClaimedInModel) {
          // If claimed in model but not in field, update the zip code model
          if (!isClaimedByField && isClaimedInModel) {
            final updatedZip = zip.copyWith(
              claimedByLoanOfficer: loanOfficerId,
              isAvailable: false,
            );
            final index = _allZipCodes.indexWhere((z) => z.zipCode == zip.zipCode);
            if (index != -1) {
              _allZipCodes[index] = updatedZip;
            }
            claimed.add(updatedZip);
          } else {
            claimed.add(zip);
          }
        } else {
          // Available if not claimed or claimed by someone else
          available.add(zip);
        }
      }

      // Update reactive state using GetX - assign new lists to trigger reactivity
      _claimedZipCodes.value = List.from(claimed);
      _availableZipCodes.value = List.from(available);

      // Apply search filter if active
      _applySearchFilter();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error updating zip code lists: $e');
        print('   Stack trace: $stackTrace');
      }
      // Fallback to empty lists to prevent crashes
      _claimedZipCodes.value = [];
      _availableZipCodes.value = List.from(_allZipCodes);
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
        .where((zip) =>
    zip.zipCode.contains(query) ||
        zip.state.toLowerCase().contains(query))
        .toList();

    _filteredAvailableZipCodes.value = _availableZipCodes
        .where((zip) =>
    zip.zipCode.contains(query) ||
        zip.state.toLowerCase().contains(query))
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
            print('🚀 Loan Officer: Created MessagesController - socket will be initialized');
          }
        }
        final messagesController = Get.find<MessagesController>();

        // Load threads in background - don't wait for it
        messagesController.refreshThreads();

        // Ensure socket is connected for real-time message reception
        // The socket should be initialized in MessagesController.onInit()
        // which is called when the controller is created above
        if (kDebugMode) {
          print('🚀 Loan Officer: Preloading chat threads and ensuring socket connection...');
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

    // Calculate base price from claimed zip codes using population-based pricing
    final basePrice = ZipCodePricingService.calculateTotalMonthlyPrice(_claimedZipCodes);

    _subscription.value = SubscriptionModel(
      id: 'sub_${userId}',
      userId: userId,
      status: SubscriptionStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      baseMonthlyPrice: basePrice > 0 ? basePrice : standardMonthlyPrice, // Fallback to old price if no zip codes
      currentMonthlyPrice: basePrice > 0 ? basePrice : standardMonthlyPrice,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  void setSelectedTab(int index) {
    _selectedTab.value = index;
  }

  void _loadMockData() {
    // Mock claimed ZIP codes
    _claimedZipCodes.value = [
      ZipCodeModel(
        zipCode: '10001',
        state: 'NY',
        population: 50000,
        claimedByLoanOfficer: 'loan_1',
        claimedAt: DateTime.now().subtract(const Duration(days: 30)),
        price: 199.99,
        isAvailable: false,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        searchCount: 67,
      ),
    ];

    // Mock available ZIP codes
    _availableZipCodes.value = [
      ZipCodeModel(
        zipCode: '10002',
        state: 'NY',
        population: 45000,
        price: 179.99,
        isAvailable: true,
        createdAt: DateTime.now(),
        searchCount: 0,
      ),
      ZipCodeModel(
        zipCode: '10003',
        state: 'NY',
        population: 40000,
        price: 159.99,
        isAvailable: true,
        createdAt: DateTime.now(),
        searchCount: 0,
      ),
    ];

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

  Future<void> claimZipCode(ZipCodeModel zipCode) async {
    // Prevent multiple simultaneous claims of the same zip code
    if (_loadingZipCodeIds.contains(zipCode.zipCode)) {
      return;
    }

    try {
      // Add to loading set for this specific zip code
      _loadingZipCodeIds.add(zipCode.zipCode);

      // Check if loan officer can claim more ZIP codes (max 6)
      if (_claimedZipCodes.length >= 6) {
        Get.snackbar('Error', 'You can only claim up to 6 ZIP codes');
        return;
      }

      // Get current loan officer ID
      final currentLoanOfficerController = Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;

      final loanOfficerId = currentLoanOfficerController?.currentLoanOfficer.value?.id;

      if (loanOfficerId == null) {
        Get.snackbar('Error', 'Loan officer information not available');
        return;
      }

      // Prepare claim API body with all required fields
      // Required: id, zipcode, price, state, population
      final price = (zipCode.price ?? 0.0).toString();
      final population = zipCode.population.toString();
      final state = zipCode.state;

      // Call API to claim zip code with all required fields
      await _zipCodeService.claimZipCode(
        loanOfficerId,
        zipCode.zipCode,
        price,
        state,
        population,
      );

      // Update local state
      final claimedZip = zipCode.copyWith(
        claimedByLoanOfficer: loanOfficerId,
        claimedAt: DateTime.now(),
        isAvailable: false,
      );

      // Update the zip code in all zip codes list efficiently
      final index = _allZipCodes.indexWhere((zip) => zip.zipCode == zipCode.zipCode);
      if (index != -1) {
        _allZipCodes[index] = claimedZip;
      }

      // Refresh the lists (this will also reapply search filter if active)
      _updateZipCodeLists();

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

      // Refresh the current loan officer data to get updated claimedZipCodes from backend
      if (currentLoanOfficerController != null && loanOfficerId.isNotEmpty) {
        await currentLoanOfficerController.refreshData(loanOfficerId);
        // Update zip code lists again after refresh to sync with backend data
        _updateZipCodeLists();
      }

      Get.snackbar(
        'Success',
        'ZIP code ${zipCode.zipCode} claimed successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ZipCodeServiceException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to claim ZIP code: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      // Remove from loading set
      _loadingZipCodeIds.remove(zipCode.zipCode);
    }
  }

  Future<void> releaseZipCode(ZipCodeModel zipCode) async {
    // Prevent multiple simultaneous releases of the same zip code
    if (_loadingZipCodeIds.contains(zipCode.zipCode)) {
      return;
    }

    try {
      // Add to loading set for this specific zip code
      _loadingZipCodeIds.add(zipCode.zipCode);

      // Get current loan officer ID
      final currentLoanOfficerController = Get.isRegistered<CurrentLoanOfficerController>()
          ? Get.find<CurrentLoanOfficerController>()
          : null;

      final loanOfficerId = currentLoanOfficerController?.currentLoanOfficer.value?.id;

      if (loanOfficerId == null) {
        Get.snackbar('Error', 'Loan officer information not available');
        return;
      }

      // Call API to release zip code
      await _zipCodeService.releaseZipCode(loanOfficerId, zipCode.zipCode);

      // Update local state - mark as available and remove claim
      // Create new instance directly to properly set nullable fields to null
      final availableZip = ZipCodeModel(
        zipCode: zipCode.zipCode,
        state: zipCode.state,
        population: zipCode.population,
        claimedByAgent: zipCode.claimedByAgent,
        claimedByLoanOfficer: null, // Explicitly set to null
        claimedAt: null, // Explicitly set to null
        price: zipCode.price,
        isAvailable: true,
        createdAt: zipCode.createdAt,
        lastSearchedAt: zipCode.lastSearchedAt,
        searchCount: zipCode.searchCount,
      );

      // Update the zip code in all zip codes list efficiently
      // Create a new list to ensure GetX reactivity is triggered
      final index = _allZipCodes.indexWhere((zip) => zip.zipCode == zipCode.zipCode);
      if (index != -1) {
        final updatedList = List<ZipCodeModel>.from(_allZipCodes);
        updatedList[index] = availableZip;
        _allZipCodes.value = updatedList; // Assign new list to trigger reactivity

        if (kDebugMode) {
          print('🔄 Updated zip code ${zipCode.zipCode} in _allZipCodes');
          print('   Claimed by: ${availableZip.claimedByLoanOfficer}');
          print('   Is available: ${availableZip.isAvailable}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Zip code ${zipCode.zipCode} not found in _allZipCodes');
        }
      }

      // Refresh the lists (this will also reapply search filter if active)
      // This must be called after updating _allZipCodes to ensure proper separation
      _updateZipCodeLists();

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

      // Refresh the current loan officer data to get updated claimedZipCodes from backend
      if (currentLoanOfficerController != null && loanOfficerId.isNotEmpty) {
        await currentLoanOfficerController.refreshData(loanOfficerId);
        // Update zip code lists again after refresh to sync with backend data
        _updateZipCodeLists();
      }

      Get.snackbar(
        'Success',
        'ZIP code ${zipCode.zipCode} released successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ZipCodeServiceException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to release ZIP code: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      // Remove from loading set
      _loadingZipCodeIds.remove(zipCode.zipCode);
    }
  }

  // Debounce timer for search optimization
  Timer? _searchDebounceTimer;

  /// Searches zip codes with debouncing for optimal performance
  /// Debounces search input to avoid excessive filtering operations
  void searchZipCodes(String query) {
    _searchQuery.value = query;

    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Debounce search filtering by 300ms for better performance
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applySearchFilter();
    });
  }

  /// Refreshes zip codes from the API (forces reload)
  Future<void> refreshZipCodes() async {
    await _loadZipCodes(forceRefresh: true);
  }

  double calculateMonthlyCost() {
    // Calculate base cost from ZIP codes using population-based pricing tiers
    final zipCodeCost = ZipCodePricingService.calculateTotalMonthlyPrice(_claimedZipCodes);

    // If in free period, return 0
    if (_subscription.value?.isInFreePeriod == true) {
      return 0.0;
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
    final newBasePrice = ZipCodePricingService.calculateTotalMonthlyPrice(_claimedZipCodes);

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
        Get.snackbar('Error', 'Invalid or expired promo code');
        return;
      }

      if (promoCode.type != PromoCodeType.loanOfficer6MonthsFree) {
        Get.snackbar('Error', 'This promo code is not valid for loan officers');
        return;
      }

      // Check if promo is still valid
      if (!promoCode.isValid) {
        Get.snackbar('Error', 'This promo code has expired or reached its usage limit');
        return;
      }

      // Check if already has active promo
      if (_subscription.value?.isInFreePeriod == true) {
        Get.snackbar('Info', 'You already have an active promotion');
        return;
      }

      // Calculate free period end date (6 months from now)
      final freePeriodEndsAt = DateTime.now().add(const Duration(days: 180)); // 6 months

      // Apply promo to subscription
      final currentSub = _subscription.value!;

      // Ensure base price is up to date before applying promo
      final basePrice = ZipCodePricingService.calculateTotalMonthlyPrice(_claimedZipCodes);
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
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to apply promo code: ${e.toString()}');
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
    if (sub?.isInFreePeriod == true && sub?.freePeriodEndsAt != null) {
      if (DateTime.now().isAfter(sub!.freePeriodEndsAt!)) {
        // Free period ended, transition to normal pricing
        final zipCodeCost = ZipCodePricingService.calculateTotalMonthlyPrice(_claimedZipCodes);
        _subscription.value = sub.copyWith(
          status: SubscriptionStatus.active,
          isPromoActive: false,
          activePromoCode: null,
          currentMonthlyPrice: zipCodeCost > 0 ? zipCodeCost : sub.baseMonthlyPrice,
          freeMonthsRemaining: 0,
          freePeriodEndsAt: null,
          updatedAt: DateTime.now(),
        );

        Get.snackbar(
          'Info',
          'Your free period has ended. You are now on the normal subscription rate.',
          duration: const Duration(seconds: 4),
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

  Future<void> addLoan(LoanModel loan) async {
    try {
      _isLoading.value = true;
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _loans.insert(0, loan);
      Get.snackbar('Success', 'Loan added successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add loan: ${e.toString()}');
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
      Get.snackbar('Success', 'Loan updated successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update loan: ${e.toString()}');
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
      Get.snackbar('Success', 'Loan deleted successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete loan: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }
}

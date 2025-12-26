import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getrebate/app/models/zip_code_model.dart';
import 'package:getrebate/app/models/agent_listing_model.dart';
import 'package:getrebate/app/models/subscription_model.dart';
import 'package:getrebate/app/models/promo_code_model.dart';
import 'package:getrebate/app/services/zip_code_pricing_service.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/network_error_handler.dart';
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
  final _isLoading = false.obs;
  final _selectedTab = 0
      .obs; // 0: Dashboard, 1: ZIP Management, 2: My Listings, 3: Stats, 4: Billing
  
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

  // Standard pricing (deprecated - now using zip code population-based pricing)
  // Kept for backward compatibility, but pricing is now calculated from zip codes
  @Deprecated('Use ZipCodePricingService instead')
  static const double standardMonthlyPrice = 17.99;

  // Getters
  List<ZipCodeModel> get claimedZipCodes => _claimedZipCodes;
  List<ZipCodeModel> get availableZipCodes => _availableZipCodes;
  List<AgentListingModel> get myListings => _myListings; // Filtered listings
  List<AgentListingModel> get allListings => _allListings; // All listings
  bool get isLoading => _isLoading.value;
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
    _loadMockData(); // Keep mock data for ZIP codes and stats - instant
    _initializeSubscription(); // Initialize subscription - instant
    checkPromoExpiration(); // Check if any promos have expired - instant
    
    // Fetch listings in background without blocking UI
    Future.microtask(() => fetchAgentListings());
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

    // Mock stats
    _searchesAppearedIn.value = 77;
    _profileViews.value = 234;
    _contacts.value = 89;
    _websiteClicks.value = 156;
    _totalRevenue.value = 1249.99;
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
      _isLoading.value = true;

      // Check if agent can claim more ZIP codes (max 6)
      if (_claimedZipCodes.length >= 6) {
        Get.snackbar('Error', 'You can only claim up to 6 ZIP codes');
        return;
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Add to claimed ZIP codes
      final claimedZip = zipCode.copyWith(
        claimedByAgent: 'agent_1',
        claimedAt: DateTime.now(),
        isAvailable: false,
      );

      _claimedZipCodes.add(claimedZip);
      _availableZipCodes.removeWhere((zip) => zip.zipCode == zipCode.zipCode);

      // Update subscription price based on new zip code
      _updateSubscriptionPrice();

      Get.snackbar(
        'Success',
        'ZIP code ${zipCode.zipCode} claimed successfully!',
      );
    } catch (e) {
      NetworkErrorHandler.handleError(
        e,
        defaultMessage: 'Unable to claim ZIP code. Please check your internet connection and try again.',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> releaseZipCode(ZipCodeModel zipCode) async {
    try {
      _isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

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
      _isLoading.value = false;
    }
  }

  Future<void> searchZipCodes(String query) async {
    try {
      _isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Filter available ZIP codes by query
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

      String errorMessage = 'Failed to fetch listings. Please try again.';

      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (e.response?.statusCode == 404) {
          // 404 is okay - just means no listings found
          _myListings.value = [];
          print('ℹ️ No listings found (404)');
          return;
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
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
}

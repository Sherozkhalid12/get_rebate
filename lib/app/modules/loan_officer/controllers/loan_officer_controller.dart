import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/zip_code_model.dart';
import 'package:getrebate/app/models/loan_model.dart';
import 'package:getrebate/app/models/subscription_model.dart';
import 'package:getrebate/app/models/promo_code_model.dart';
import 'package:getrebate/app/services/zip_code_pricing_service.dart';
import 'package:getrebate/app/services/zip_codes_service.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/utils/network_error_handler.dart';

class LoanOfficerController extends GetxController {
  // Data
  final _claimedZipCodes = <ZipCodeModel>[].obs;
  final _availableZipCodes = <ZipCodeModel>[].obs;
  final _loans = <LoanModel>[].obs;
  final _isLoading = false.obs;
  final _selectedTab = 0
      .obs; // 0: Dashboard, 1: Messages, 2: ZIP Management, 3: Billing, 4: Checklists, 5: Stats
  
  // State and ZIP code management
  final _selectedState = Rxn<String>();
  final _isLoadingZipCodes = false.obs;
  
  // Services
  final _zipCodesService = ZipCodesService();

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
  List<LoanModel> get loans => _loans;
  bool get isLoading => _isLoading.value;
  int get selectedTab => _selectedTab.value;
  int get searchesAppearedIn => _searchesAppearedIn.value;
  int get profileViews => _profileViews.value;
  int get contacts => _contacts.value;
  double get totalRevenue => _totalRevenue.value;
  
  // State and ZIP code getters
  String? get selectedState => _selectedState.value;
  bool get isLoadingZipCodes => _isLoadingZipCodes.value;

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
  
  // State and ZIP code methods
  Future<void> selectStateAndFetchZipCodes(String state) async {
    if (state.isEmpty) {
      _selectedState.value = null;
      _availableZipCodes.value = [];
      return;
    }
    
    _selectedState.value = state;
    await _fetchZipCodesByState(state);
  }
  
  Future<void> _fetchZipCodesByState(String state) async {
    try {
      _isLoadingZipCodes.value = true;
      
      final zipCodes = await _zipCodesService.getZipCodesByState(state: state);
      
      // Update available ZIP codes, filtering out already claimed ones
      final claimedZipCodesSet = _claimedZipCodes.map((z) => z.zipCode).toSet();
      _availableZipCodes.value = zipCodes
          .where((zip) => !claimedZipCodesSet.contains(zip.zipCode))
          .toList();
    } catch (e) {
      NetworkErrorHandler.handleError(
        e,
        defaultMessage: 'Unable to fetch ZIP codes. Please check your internet connection and try again.',
      );
    } finally {
      _isLoadingZipCodes.value = false;
    }
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
    try {
      _isLoading.value = true;

      // Check if loan officer can claim more ZIP codes (max 6)
      if (_claimedZipCodes.length >= 6) {
        Get.snackbar('Error', 'You can only claim up to 6 ZIP codes');
        return;
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Add to claimed ZIP codes
      final claimedZip = zipCode.copyWith(
        claimedByLoanOfficer: 'loan_1',
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
        claimedByLoanOfficer: null,
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

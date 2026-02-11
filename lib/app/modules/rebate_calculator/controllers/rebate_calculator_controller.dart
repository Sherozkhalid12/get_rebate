// lib/app/modules/rebate_calculator/controllers/rebate_calculator_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/services/rebate_calculator_api_service.dart';

class RebateCalculatorController extends GetxController {
  // MODE: 0 = Tiers, 1 = Actual, 2 = Seller Conversion
  final currentMode = 0.obs;

  // API Service
  final _apiService = RebateCalculatorApiService();

  // Loading states for each tab
  final isLoadingEstimated = false.obs;
  final isLoadingActual = false.obs;
  final isLoadingSeller = false.obs;

  // API Results for each tab
  final apiResultEstimated = Rxn<RebateCalculatorResponse>();
  final apiResultActual = Rxn<RebateCalculatorResponse>();
  final apiResultSeller = Rxn<RebateCalculatorResponse>();

  // FORM CONTROLLERS - Only Sales Price, BAC, and State needed
  final homePriceController = TextEditingController();
  final agentCommissionController = TextEditingController();
  final sellerOriginalFeeController =
      TextEditingController(); // For Mode 2 (Seller Conversion)

  // DROPDOWNS
  final _selectedState = 'CA'.obs; // Default to California (rebates allowed)

  // RESULTS
  final estimatedRebate = 0.0.obs;
  final agentRebate = 0.0.obs;
  final totalSavings = 0.0.obs;
  final rebatePercentage = 0.0.obs;
  final effectiveCommissionRate = 0.0.obs;
  final commissionTier = ''.obs;

  // MODE 2: Actual
  final actualRebate = 0.0.obs;
  final actualTier = ''.obs;

  // MODE 3: Seller
  final sellerRebate = 0.0.obs;
  final sellerNewFee = 0.0.obs;

  // TIER DISPLAY (Mode 0)
  final tiers = <Map<String, dynamic>>[].obs;

  // OPTIONS - Only include states where rebates are allowed
  static const List<String> _allStates = [
    'AZ',
    'AR',
    'CA',
    'CO',
    'CT',
    'DE',
    'FL',
    'GA',
    'HI',
    'ID',
    'IL',
    'IN',
    'KY',
    'ME',
    'MD',
    'MA',
    'MI',
    'MN',
    'MT',
    'NE',
    'NV',
    'NH',
    'NJ',
    'NM',
    'NY',
    'NC',
    'ND',
    'OH',
    'PA',
    'RI',
    'SC',
    'SD',
    'TX',
    'UT',
    'VT',
    'VA',
    'WA',
    'WV',
    'WI',
    'WY',
  ];

  // Seller-specific limitations (currently only New Jersey)
  static const Set<String> _sellerRebateLimitedStates = {'NJ'};

  List<String> get allowedStates => _allStates;

  // GETTERS
  String get selectedState => _selectedState.value;
  bool get shouldShowSellerRestriction =>
      _sellerRebateLimitedStates.contains(_selectedState.value);

  String getSellerRestrictionMessage() {
    if (!shouldShowSellerRestriction) return '';

    if (currentMode.value == 2) {
      return 'New Jersey does not allow commission rebates to sellers. This Seller Conversion calculator converts your listing commission into a lower fee instead.';
    }

    return 'New Jersey does not allow commission rebates to sellers. Switch to the Seller Conversion tab to convert your commission into a lower listing fee.';
  }

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
    _updateFormValidity(); // Initial validation check
  }

  // Observable for form validity
  final _isFormValid = false.obs;

  void _setupListeners() {
    homePriceController.addListener(() {
      // Clear API results when inputs change (but not while loading)
      if (!isLoading) {
        _clearApiResultsForCurrentMode();
      }
      _calculate();
      _updateFormValidity();
    });
    agentCommissionController.addListener(() {
      // Clear API results when inputs change (but not while loading)
      if (!isLoading) {
        _clearApiResultsForCurrentMode();
      }
      _calculate();
      _updateFormValidity();
    });
    sellerOriginalFeeController.addListener(() {
      // Clear API results when inputs change (but not while loading)
      if (!isLoading) {
        _clearApiResultsForCurrentMode();
      }
      _calculate();
      _updateFormValidity();
    });
    _selectedState.listen((_) {
      // Clear API results when state changes (but not while loading)
      if (!isLoading) {
        _clearApiResultsForCurrentMode();
      }
      _updateFormValidity();
    });
    currentMode.listen((_) => _updateFormValidity());
  }

  /// Clears API results for the current mode
  void _clearApiResultsForCurrentMode() {
    switch (currentMode.value) {
      case 0:
        apiResultEstimated.value = null;
        break;
      case 1:
        apiResultActual.value = null;
        break;
      case 2:
        apiResultSeller.value = null;
        break;
    }
  }

  void _updateFormValidity() {
    final priceText = homePriceController.text.replaceAll(RegExp(r'[,\$]'), '');
    final price = double.tryParse(priceText);

    String commissionText;
    if (currentMode.value == 2) {
      commissionText = sellerOriginalFeeController.text;
    } else {
      commissionText = agentCommissionController.text;
    }
    final commission = double.tryParse(commissionText);

    _isFormValid.value =
        (price != null && price > 0) &&
        (commission != null && commission > 0) &&
        _selectedState.value.isNotEmpty;
  }

  // MAIN CALCULATION - Only uses Sales Price and BAC
  void _calculate() {
    // Don't run local calculations if we have API results for the current mode or if loading
    // This prevents flickering when API results are displayed or while API call is in progress
    if (_hasApiResultForCurrentMode() || isLoading) {
      return;
    }

    final price =
        double.tryParse(homePriceController.text.replaceAll(',', '')) ?? 0.0;
    final agentRate = double.tryParse(agentCommissionController.text) ?? 0.0;
    final sellerFeeRate =
        double.tryParse(sellerOriginalFeeController.text) ?? agentRate;

    if (price <= 0) {
      _resetResults();
      return;
    }

    // Apply 4.0% minimum commission rule: if commission >= 4.0%, use 4.0% (or more) for rebate purposes
    // The _getRebateData function already handles this: rates >= 4.0% return Tier 1 (40% rebate)
    // This ensures that any commission rate >= 4.0% uses Tier 1 for rebate calculation

    // MODE 0: Tiers (Buyer rebate tiers using BAC)
    if (currentMode.value == 0) {
      _calcTiers(price);
    }

    // MODE 1: Actual (Buyer rebate calculation)
    // Formula: Rebate = Sale/Purchase Price × BAC × Tier %
    // If BAC >= 4.0%, _getRebateData returns Tier 1 (40% rebate), ensuring 4.0% minimum is used
    if (currentMode.value == 1) {
      final data = _getRebateData(agentRate, price);
      // Commission = Price × BAC / 100
      final commission = price * agentRate / 100;
      // Rebate = Commission × Tier % / 100 = Price × BAC × Tier % / 10000
      actualRebate.value = commission * data['pct'] / 100;
      actualTier.value = data['tier'];
      rebatePercentage.value = data['pct'];
      commissionTier.value = data['tier'];
    }

    // MODE 2: Seller Conversion (Seller rebate calculation)
    // Formula: Rebate = Sale/Purchase Price × LAC × Tier %
    // If LAC >= 4.0%, _getRebateData returns Tier 1 (40% rebate), ensuring 4.0% minimum is used
    if (currentMode.value == 2) {
      final data = _getRebateData(sellerFeeRate, price);
      // Commission = Price × LAC / 100
      final commission = price * sellerFeeRate / 100;
      // Rebate = Commission × Tier % / 100 = Price × LAC × Tier % / 10000
      final rebate = commission * data['pct'] / 100;
      sellerRebate.value = rebate;
      sellerNewFee.value = ((commission - rebate) / price) * 100;
    }

    // COMMON REBATE CALC (for display)
    final data = _getRebateData(agentRate, price);
    final agentCommission = price * agentRate / 100;

    agentRebate.value = agentCommission * data['pct'] / 100;
    estimatedRebate.value = agentRebate.value;

    effectiveCommissionRate.value = agentCommission > 0
        ? ((agentCommission - estimatedRebate.value) / price) * 100
        : 0.0;

    commissionTier.value = data['tier'];
    rebatePercentage.value = data['pct'];
    totalSavings.value = estimatedRebate.value;
  }

  void _calcTiers(double price) {
    // For homes $700k or higher: Tiers 5 and 6 do not apply, minimum is Tier 4
    final isHighValue = price >= 700000;

    final tierList = [
      _tier("4.0% or more", 40.0, 4.0, price),
      _tier("3.01% - 3.99%", 35.0, 3.01, price),
      _tier("2.5% - 3.0%", 30.0, 2.5, price),
      _tier("2.0% - 2.49%", 25.0, 2.0, price),
    ];

    // Add Tiers 5, 6, 7 only for homes below $700k
    if (!isHighValue) {
      tierList.addAll([
        _tier("1.5% - 1.99%", 20.0, 1.5, price),
        _tier(".25% - 1.49%", 10.0, 0.25, price),
      ]);
    }

    // Tier 7 applies to all price ranges
    tierList.add(_tier("0 - .24%", 0.0, 0.0, price));

    tiers.assignAll(tierList);
  }

  /// Calculates rebate amount for a tier
  /// Formula: Rebate = Price × Commission Rate × Tier % / 10000
  Map<String, dynamic> _tier(
    String range,
    double pct,
    double rate,
    double price,
  ) {
    // Commission = Price × Rate / 100
    final comm = price * rate / 100;
    // Rebate = Commission × Tier % / 100 = Price × Rate × Tier % / 10000
    final rebate = comm * pct / 100;
    return {
      'range': range,
      'rebate': '$pct% rebate',
      'color': pct >= 35 ? AppTheme.lightGreen : AppTheme.mediumGray,
      'amount': rebate.toStringAsFixed(0),
    };
  }

  /// Determines rebate tier and percentage based on commission rate
  /// If rate >= 4.0%, returns Tier 1 (40% rebate) - ensuring 4.0% minimum commission rule
  Map<String, dynamic> _getRebateData(double rate, [double? price]) {
    final homePrice =
        price ?? (double.tryParse(homePriceController.text) ?? 0.0);
    final isHighValue = homePrice >= 700000;

    // 4.0% minimum commission rule: if rate >= 4.0%, always use Tier 1 (40% rebate)
    if (rate >= 4.0) return {'pct': 40.0, 'tier': 'Tier 1: 4.0% or more'};
    if (rate >= 3.01) return {'pct': 35.0, 'tier': 'Tier 2: 3.01% - 3.99%'};
    if (rate >= 2.5) return {'pct': 30.0, 'tier': 'Tier 3: 2.5% - 3.0%'};
    if (rate >= 2.0) return {'pct': 25.0, 'tier': 'Tier 4: 2.0% - 2.49%'};

    // For homes $700k or higher: Tiers 5 and 6 do not apply, minimum is Tier 4
    if (isHighValue) {
      // If commission is below 2%, check if it qualifies for Tier 7
      if (rate < 0.25) return {'pct': 0.0, 'tier': 'Tier 7: 0 - .24%'};
      // Otherwise, apply Tier 4 as minimum
      return {
        'pct': 25.0,
        'tier': 'Tier 4: 2.0% - 2.49% (minimum for \$700k+)',
      };
    }

    // For homes below $700k: All tiers apply
    if (rate >= 1.5) return {'pct': 20.0, 'tier': 'Tier 5: 1.5% - 1.99%'};
    if (rate >= 0.25) return {'pct': 10.0, 'tier': 'Tier 6: .25% - 1.49%'};
    return {'pct': 0.0, 'tier': 'Tier 7: 0 - .24%'};
  }

  void _resetResults() {
    estimatedRebate.value = 0;
    agentRebate.value = 0;
    totalSavings.value = 0;
    rebatePercentage.value = 0;
    effectiveCommissionRate.value = 0;
    commissionTier.value = '';
    actualRebate.value = 0;
    actualTier.value = '';
    sellerRebate.value = 0;
    sellerNewFee.value = 0;
    tiers.clear();
    // Don't clear API results here - they should persist until new calculation
  }

  // ACTIONS
  void setMode(int mode) {
    currentMode.value = mode;
    _calculate();
  }

  void setSelectedState(String s) => _selectedState.value = s;

  void resetAll() {
    homePriceController.clear();
    agentCommissionController.clear();
    sellerOriginalFeeController.clear();
    _selectedState.value = 'CA'; // Default to California (rebates allowed)
    _resetResults();
    _resetApiResults();
    _calculate();
  }

  void _resetApiResults() {
    apiResultEstimated.value = null;
    apiResultActual.value = null;
    apiResultSeller.value = null;
  }

  /// Validates form inputs for API call
  bool _validateInputs() {
    final priceText = homePriceController.text.replaceAll(RegExp(r'[,\$]'), '');
    final price = double.tryParse(priceText);

    String commissionText;
    if (currentMode.value == 2) {
      commissionText = sellerOriginalFeeController.text;
    } else {
      commissionText = agentCommissionController.text;
    }
    final commission = double.tryParse(commissionText);

    if (price == null || price <= 0) {
      Get.snackbar(
        'Validation Error',
        'Please enter a valid home price greater than 0.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }

    if (commission == null || commission <= 0) {
      Get.snackbar(
        'Validation Error',
        'Please enter a valid commission percentage greater than 0.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }

    if (_selectedState.value.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select a state.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }

    return true;
  }

  /// Formats price for API (removes commas and dollar sign)
  String _formatPriceForApi(String priceText) {
    return priceText.replaceAll(RegExp(r'[,\$]'), '');
  }

  /// Calls API for Estimated tab (Mode 0)
  Future<void> calculateEstimated() async {
    if (!_validateInputs()) return;

    isLoadingEstimated.value = true;
    // Clear old result when starting new calculation
    apiResultEstimated.value = null;

    try {
      final priceText = _formatPriceForApi(homePriceController.text);
      final commissionText = agentCommissionController.text;

      final response = await _apiService.estimateRebate(
        price: priceText,
        commission: commissionText,
        state: _selectedState.value,
      );

      if (response.success) {
        // Set API result - this will trigger UI update
        apiResultEstimated.value = response;
      } else {
        // Clear on failure
        apiResultEstimated.value = null;
        Get.snackbar(
          'Calculation Failed',
          'Unable to estimate rebate. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
        );
      }
    } on RebateCalculatorApiException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to calculate rebate. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoadingEstimated.value = false;
    }
  }

  /// Calls API for Actual tab (Mode 1)
  Future<void> calculateActual() async {
    if (!_validateInputs()) return;

    isLoadingActual.value = true;
    // Clear old result when starting new calculation
    apiResultActual.value = null;

    try {
      final priceText = _formatPriceForApi(homePriceController.text);
      final commissionText = agentCommissionController.text;

      final response = await _apiService.calculateExactRebate(
        price: priceText,
        commission: commissionText,
        state: _selectedState.value,
      );

      if (response.success) {
        // Set API result - this will trigger UI update
        apiResultActual.value = response;
      } else {
        // Clear on failure
        apiResultActual.value = null;
        Get.snackbar(
          'Calculation Failed',
          'Unable to calculate exact rebate. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
        );
      }
    } on RebateCalculatorApiException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to calculate rebate. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoadingActual.value = false;
    }
  }

  /// Calls API for Seller Conversion tab (Mode 2)
  Future<void> calculateSeller() async {
    if (!_validateInputs()) return;

    isLoadingSeller.value = true;
    // Clear old result when starting new calculation
    apiResultSeller.value = null;

    try {
      final priceText = _formatPriceForApi(homePriceController.text);
      final commissionText = sellerOriginalFeeController.text;

      final response = await _apiService.calculateSellerRate(
        price: priceText,
        commission: commissionText,
        state: _selectedState.value,
      );

      if (response.success) {
        // Set API result - this will trigger UI update
        apiResultSeller.value = response;
      } else {
        // Clear on failure
        apiResultSeller.value = null;
        Get.snackbar(
          'Calculation Failed',
          'Unable to calculate seller rate. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
        );
      }
    } on RebateCalculatorApiException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to calculate seller rate. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoadingSeller.value = false;
    }
  }

  /// Gets current loading state based on mode
  bool get isLoading {
    switch (currentMode.value) {
      case 0:
        return isLoadingEstimated.value;
      case 1:
        return isLoadingActual.value;
      case 2:
        return isLoadingSeller.value;
      default:
        return false;
    }
  }

  /// Gets current API result based on mode
  RebateCalculatorResponse? get currentApiResult {
    switch (currentMode.value) {
      case 0:
        return apiResultEstimated.value;
      case 1:
        return apiResultActual.value;
      case 2:
        return apiResultSeller.value;
      default:
        return null;
    }
  }

  /// Checks if there's an API result for the current mode
  bool _hasApiResultForCurrentMode() {
    switch (currentMode.value) {
      case 0:
        return apiResultEstimated.value != null &&
            apiResultEstimated.value!.success;
      case 1:
        return apiResultActual.value != null && apiResultActual.value!.success;
      case 2:
        return apiResultSeller.value != null && apiResultSeller.value!.success;
      default:
        return false;
    }
  }

  /// Checks if form is valid for current mode (reactive)
  bool get isFormValid => _isFormValid.value;

  @override
  void onClose() {
    homePriceController.dispose();
    agentCommissionController.dispose();
    sellerOriginalFeeController.dispose();
    _apiService.dispose();
    super.onClose();
  }
}

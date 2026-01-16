import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/services/loan_officer_service.dart';

/// Global controller that holds the currently authenticated loan officer.
///
/// This should be the single source of truth for the loan officer profile
/// across the entire app (dashboard, profile, settings, headers, etc.).
class CurrentLoanOfficerController extends GetxController {
  final LoanOfficerService _loanOfficerService;

  /// Currently authenticated loan officer
  final Rx<LoanOfficerModel?> currentLoanOfficer = Rx<LoanOfficerModel?>(null);

  /// Loading state for fetch/refresh operations
  final RxBool isLoading = false.obs;

  CurrentLoanOfficerController({
    LoanOfficerService? loanOfficerService,
  }) : _loanOfficerService = loanOfficerService ?? LoanOfficerService();

  /// Convenience getter
  LoanOfficerModel? get loanOfficer => currentLoanOfficer.value;

  /// Fetches the current loan officer by ID and updates [currentLoanOfficer].
  ///
  /// Typically called after login, using the authenticated user's ID.
  /// Prevents multiple simultaneous fetches with a guard.
  Future<void> fetchCurrentLoanOfficer(String id) async {
    if (id.isEmpty) {
      if (kDebugMode) {
        print('⚠️ CurrentLoanOfficerController: Provided ID is empty, aborting fetch.');
      }
      return;
    }

    // Guard: Prevent multiple simultaneous fetches
    if (isLoading.value) {
      if (kDebugMode) {
        print('⚠️ CurrentLoanOfficerController: Already loading, skipping duplicate fetch for ID: $id');
      }
      return;
    }

    // Guard: If data already exists for this ID, skip fetch
    if (currentLoanOfficer.value != null && currentLoanOfficer.value!.id == id) {
      if (kDebugMode) {
        print('✅ CurrentLoanOfficerController: Loan officer data already loaded for ID: $id, skipping fetch.');
      }
      return;
    }

    isLoading.value = true;

    try {
      if (kDebugMode) {
        print('📡 CurrentLoanOfficerController: Fetching current loan officer...');
        print('   ID: $id');
      }

      final officer = await _loanOfficerService.getCurrentLoanOfficer(id);
      currentLoanOfficer.value = officer;
      currentLoanOfficer.refresh();

      if (kDebugMode) {
        print('✅ CurrentLoanOfficerController: Loan officer loaded successfully');
        print('   ID: ${officer.id}');
        print('   Name: ${officer.name}');
        print('   Profile Image: ${officer.profileImage ?? "Not set"}');
      }
    } on LoanOfficerServiceException catch (e) {
      if (kDebugMode) {
        print('❌ CurrentLoanOfficerController: Service exception: ${e.message}');
        print('   Status Code: ${e.statusCode}');
      }

      // Show user-friendly message, but keep existing data if any
      _safeShowSnackbar(
        'Error',
        e.message,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ CurrentLoanOfficerController: Unexpected error: $e');
      }

      _safeShowSnackbar(
        'Error',
        'Failed to load loan officer profile. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Re-fetches the latest data for the current loan officer.
  ///
  /// Useful for pull-to-refresh, after profile edits, or on app resume.
  Future<void> refreshData([String? id]) async {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;

    final effectiveId = id ??
        auth?.currentUser?.id ??
        currentLoanOfficer.value?.id ??
        '';

    await fetchCurrentLoanOfficer(effectiveId);
  }

  void _safeShowSnackbar(String title, String message) {
    try {
      if (Get.isOverlaysOpen || Get.context != null) {
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ CurrentLoanOfficerController: Could not show snackbar: $e');
      }
    }
  }
}








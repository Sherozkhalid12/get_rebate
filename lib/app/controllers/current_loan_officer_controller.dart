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

  CurrentLoanOfficerController({LoanOfficerService? loanOfficerService})
    : _loanOfficerService = loanOfficerService ?? LoanOfficerService();

  /// Convenience getter
  LoanOfficerModel? get loanOfficer => currentLoanOfficer.value;

  /// Fetches the current loan officer by ID and updates [currentLoanOfficer].
  ///
  /// Typically called after login, using the authenticated user's ID.
  Future<void> fetchCurrentLoanOfficer(String id) async {
    if (id.isEmpty) {
      if (kDebugMode) {
        print(
          '⚠️ CurrentLoanOfficerController: Provided ID is empty, aborting fetch.',
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      if (kDebugMode) {
        print(
          '📡 CurrentLoanOfficerController: Fetching current loan officer...',
        );
        print('   ID: $id');
      }

      final officer = await _loanOfficerService.getCurrentLoanOfficer(id);
      currentLoanOfficer.value = officer;
      currentLoanOfficer.refresh();

      if (kDebugMode) {
        print(
          '✅ CurrentLoanOfficerController: Loan officer loaded: ${officer.id}',
        );
      }
    } on LoanOfficerServiceException catch (e) {
      if (kDebugMode) {
        print(
          '❌ CurrentLoanOfficerController: Service exception: ${e.message}',
        );
        print('   Status Code: ${e.statusCode}');
      }

      // Show user-friendly message, but keep existing data if any
      _safeShowSnackbar('Error', e.message);
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
  Future<void> refreshData([String? id, bool forceRefresh = false]) async {
    try {
      // Get auth controller safely
      final auth = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : null;

      // Determine effective ID with fallback chain
      final effectiveId =
          id ?? auth?.currentUser?.id ?? currentLoanOfficer.value?.id ?? '';

      if (effectiveId.isEmpty) {
        debugPrint(
          'Warning: No valid ID found for refreshing loan officer data',
        );
        return;
      }

      // If force refresh is requested → clear current data to bypass cache
      LoanOfficerModel? previousData;
      if (forceRefresh) {
        previousData = currentLoanOfficer.value;
        currentLoanOfficer.value = null; // Force fetch by clearing state
        isLoading.value = true;
      }

      // Perform the actual fetch
      await fetchCurrentLoanOfficer(effectiveId);

      // If fetch failed during force refresh → restore previous data
      if (forceRefresh &&
          currentLoanOfficer.value == null &&
          previousData != null) {
        currentLoanOfficer.value = previousData;
        debugPrint('Force refresh failed, restored previous data');
      }
    } catch (e, stack) {
      debugPrint('Error refreshing loan officer data: $e');
      debugPrint('Stack trace: $stack');
      // Optional: show user-friendly error (uncomment if needed)
      // Get.snackbar('Refresh Failed', 'Could not update profile. Please try again.');
    } finally {
      isLoading.value = false;
    }
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

// import 'dart:async';
// import 'dart:convert';
//
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
//
// import '../../../models/loan_officer_model.dart';
// import '../../../models/zip_code_model.dart';
// import '../../../controllers/current_loan_officer_controller.dart';
// import '../../../controllers/auth_controller.dart' as global_auth;
// import '../../../zipcodeservice.dart';
//
// class LoanZipCodeController extends GetxController {
//   static LoanZipCodeController get to => Get.find();
//
//   // Services
//   final ZipCodeService _zipCodeService = ZipCodeService();
//   final GetStorage _storage = GetStorage();
//
//   // ZIP Code Lists
//   final RxList<ZipCodeModel> claimedZipCodes = <ZipCodeModel>[].obs;
//   final RxList<ZipCodeModel> availableZipCodes = <ZipCodeModel>[].obs;
//   final RxList<ZipCodeModel> allZipCodes = <ZipCodeModel>[].obs;
//
//   // Search & Filtering
//   final RxString searchQuery = ''.obs;
//   final RxList<ZipCodeModel> filteredClaimed = <ZipCodeModel>[].obs;
//   final RxList<ZipCodeModel> filteredAvailable = <ZipCodeModel>[].obs;
//
//   // State & Loading
//   final RxnString selectedState = RxnString();
//   final RxBool isLoadingZipCodes = false.obs;
//   final RxSet<String> processingZipCodes = <String>{}.obs;
//
//   // Pending Actions
//   final RxSet<String> pendingClaimed = <String>{}.obs;
//   final RxSet<String> pendingReleased = <String>{}.obs;
//
//   bool _syncLocked = false;
//
//   @override
//   void onInit() {
//     super.onInit();
//     _clearAllZipData();
//     _setupLoanOfficerListener();
//     _loadInitialClaimedZipCodes();
//     Future.delayed(const Duration(milliseconds: 400), () {
//       _loadZipCodes(force: true);
//     });
//   }
//
//   void _clearAllZipData() {
//     claimedZipCodes.clear();
//     availableZipCodes.clear();
//     allZipCodes.clear();
//     pendingClaimed.clear();
//     pendingReleased.clear();
//     searchQuery.value = '';
//     filteredClaimed.clear();
//     filteredAvailable.clear();
//   }
//
//   void _setupLoanOfficerListener() {
//     final officerCtrl = Get.find<CurrentLoanOfficerController>();
//     ever(officerCtrl.currentLoanOfficer, (LoanOfficerModel? officer) {
//       if (officer != null && !_syncLocked) {
//         _syncClaimedFromBackend(officer);
//       }
//     });
//   }
//
//   Future<void> _loadInitialClaimedZipCodes() async {
//     final officerCtrl = Get.find<CurrentLoanOfficerController>();
//     final authCtrl = Get.find<global_auth.AuthController>();
//     final userId = authCtrl.currentUser?.id;
//
//     if (userId == null) return;
//
//     await officerCtrl.refreshData(userId, true);
//     final officer = officerCtrl.currentLoanOfficer.value;
//     if (officer != null) {
//       _syncClaimedFromBackend(officer);
//     }
//   }
//
//   void _syncClaimedFromBackend(LoanOfficerModel officer) {
//     if (_syncLocked) return;
//
//     final claimedSet = officer.claimedZipCodes.toSet();
//
//     claimedZipCodes.removeWhere((z) => !claimedSet.contains(z.zipCode));
//
//     for (final code in claimedSet) {
//       if (claimedZipCodes.any((z) => z.zipCode == code)) continue;
//
//       final existing = allZipCodes.firstWhereOrNull((z) => z.zipCode == code);
//       final model = existing != null
//           ? existing.copyWith(
//         claimedByLoanOfficer: officer.id,
//         isAvailable: false,
//       )
//           : ZipCodeModel(
//         zipCode: code,
//         state: officer.licensedStates.firstOrNull ?? 'CA',
//         population: 0,
//         claimedByLoanOfficer: officer.id,
//         claimedAt: DateTime.now(),
//         isAvailable: false,
//         createdAt: DateTime.now(),
//         price: null,
//       );
//
//       claimedZipCodes.add(model);
//     }
//
//     _refreshAvailableList();
//     _applySearchFilter();
//   }
//
//   Future<void> _loadZipCodes({bool force = false}) async {
//     if (isLoadingZipCodes.value && !force) return;
//     isLoadingZipCodes.value = true;
//
//     try {
//       final officerCtrl = Get.find<CurrentLoanOfficerController>();
//       final officer = officerCtrl.currentLoanOfficer.value;
//       final state = selectedState.value ?? officer?.licensedStates.firstOrNull ?? 'CA';
//
//       final cacheKey = 'zip_US_$state';
//
//       if (!force) {
//         final cached = _storage.read(cacheKey);
//         if (cached != null && cached is List && cached.isNotEmpty) {
//           try {
//             final items = cached.map((e) => ZipCodeModel.fromJson(e)).toList();
//             if (items.isNotEmpty) {
//               allZipCodes.value = items;
//               _refreshZipCodeLists();
//               return;
//             }
//           } catch (_) {
//             _storage.remove(cacheKey);
//           }
//         }
//       }
//
//       final fresh = await _zipCodeService.getZipCodes('US', state);
//       if (fresh.isNotEmpty) {
//         allZipCodes.value = fresh;
//         _storage.write(cacheKey, fresh.map((z) => z.toJson()).toList());
//         _refreshZipCodeLists();
//       }
//     } catch (e) {
//       if (allZipCodes.isEmpty) {
//         Get.snackbar('Error', 'Failed to load ZIP codes. Please check your connection.');
//       }
//     } finally {
//       isLoadingZipCodes.value = false;
//     }
//   }
//
//   void _refreshZipCodeLists() {
//     if (allZipCodes.isEmpty) return;
//
//     final officer = Get.find<CurrentLoanOfficerController>().currentLoanOfficer.value;
//     final officerId = officer?.id;
//
//     if (officerId == null) {
//       availableZipCodes.value = allZipCodes.toList();
//       return;
//     }
//
//     final backendClaimed = officer!.claimedZipCodes.toSet();
//
//     final newClaimed = <ZipCodeModel>[];
//     final newAvailable = <ZipCodeModel>[];
//
//     for (final zip in allZipCodes) {
//       if (backendClaimed.contains(zip.zipCode)) {
//         newClaimed.add(zip.copyWith(
//           claimedByLoanOfficer: officerId,
//           isAvailable: false,
//         ));
//       } else {
//         newAvailable.add(zip.copyWith(
//           claimedByLoanOfficer: null,
//           isAvailable: true,
//         ));
//       }
//     }
//
//     claimedZipCodes.value = newClaimed;
//     availableZipCodes.value = newAvailable;
//     _applySearchFilter();
//   }
//
//   void _refreshAvailableList() {
//     final claimedSet = claimedZipCodes.map((z) => z.zipCode).toSet();
//     availableZipCodes.value = allZipCodes
//         .where((z) => !claimedSet.contains(z.zipCode))
//         .map((z) => z.copyWith(isAvailable: true, claimedByLoanOfficer: null))
//         .toList();
//   }
//
//   Future<void> claimZipCode(ZipCodeModel zip) async {
//     if (processingZipCodes.contains(zip.zipCode)) return;
//
//     processingZipCodes.add(zip.zipCode);
//     _syncLocked = true;
//
//     try {
//       if (claimedZipCodes.length >= 6) {
//         Get.snackbar('Limit Reached', 'Maximum 6 ZIP codes allowed', snackPosition: SnackPosition.TOP);
//         return;
//       }
//
//       final officerCtrl = Get.find<CurrentLoanOfficerController>();
//       final officerId = officerCtrl.currentLoanOfficer.value?.id;
//       if (officerId == null) return;
//
//       await _zipCodeService.claimZipCode(
//         officerId,
//         zip.zipCode,
//         (zip.price ?? 0).toString(),
//         zip.state,
//         zip.population.toString(),
//       );
//
//       pendingClaimed.add(zip.zipCode);
//       pendingReleased.remove(zip.zipCode);
//
//       final claimed = zip.copyWith(
//         claimedByLoanOfficer: officerId,
//         claimedAt: DateTime.now(),
//         isAvailable: false,
//       );
//
//       availableZipCodes.removeWhere((z) => z.zipCode == zip.zipCode);
//       if (!claimedZipCodes.any((z) => z.zipCode == zip.zipCode)) {
//         claimedZipCodes.add(claimed);
//       }
//
//       final idx = allZipCodes.indexWhere((z) => z.zipCode == zip.zipCode);
//       if (idx != -1) allZipCodes[idx] = claimed;
//
//       _applySearchFilter();
//
//       Get.snackbar('Success', 'ZIP ${zip.zipCode} claimed', snackPosition: SnackPosition.TOP);
//
//       await officerCtrl.refreshData(officerId,  true);
//       pendingClaimed.remove(zip.zipCode);
//       _syncClaimedFromBackend(officerCtrl.currentLoanOfficer.value!);
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to claim ZIP code', snackPosition: SnackPosition.TOP);
//     } finally {
//       processingZipCodes.remove(zip.zipCode);
//       _syncLocked = false;
//     }
//   }
//
//   Future<void> releaseZipCode(ZipCodeModel zip) async {
//     if (processingZipCodes.contains(zip.zipCode)) return;
//
//     processingZipCodes.add(zip.zipCode);
//     _syncLocked = true;
//
//     try {
//       final officerCtrl = Get.find<CurrentLoanOfficerController>();
//       final officerId = officerCtrl.currentLoanOfficer.value?.id;
//       if (officerId == null) return;
//
//       await _zipCodeService.releaseZipCode(officerId, zip.zipCode);
//
//       pendingReleased.add(zip.zipCode);
//       pendingClaimed.remove(zip.zipCode);
//
//       final released = zip.copyWith(
//         claimedByLoanOfficer: null,
//         claimedAt: null,
//         isAvailable: true,
//       );
//
//       claimedZipCodes.removeWhere((z) => z.zipCode == zip.zipCode);
//       if (!availableZipCodes.any((z) => z.zipCode == zip.zipCode)) {
//         availableZipCodes.add(released);
//       }
//
//       final idx = allZipCodes.indexWhere((z) => z.zipCode == zip.zipCode);
//       if (idx != -1) allZipCodes[idx] = released;
//
//       _applySearchFilter();
//
//       Get.snackbar('Success', 'ZIP ${zip.zipCode} released', snackPosition: SnackPosition.TOP);
//
//       await officerCtrl.refreshData(officerId,  true);
//       pendingReleased.remove(zip.zipCode);
//       _syncClaimedFromBackend(officerCtrl.currentLoanOfficer.value!);
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to release ZIP code', snackPosition: SnackPosition.TOP);
//     } finally {
//       processingZipCodes.remove(zip.zipCode);
//       _syncLocked = false;
//     }
//   }
//
//   Future<void> refreshZipCodes() async {
//     pendingClaimed.clear();
//     pendingReleased.clear();
//
//     final officerCtrl = Get.find<CurrentLoanOfficerController>();
//     final uid = officerCtrl.currentLoanOfficer.value?.id;
//
//     if (uid != null) {
//       await officerCtrl.refreshData(uid, true);
//     }
//
//     await _loadZipCodes(force: true);
//   }
//
//   void selectState(String? state) {
//     if (state == null || state.isEmpty) {
//       selectedState.value = null;
//       availableZipCodes.clear();
//       return;
//     }
//
//     if (selectedState.value == state) return;
//
//     selectedState.value = state;
//     _loadZipCodes(force: false);
//   }
//
//   void searchZipCodes(String query) {
//     searchQuery.value = query.trim().toLowerCase();
//     _applySearchFilter();
//   }
//
//   void _applySearchFilter() {
//     if (searchQuery.isEmpty) {
//       filteredClaimed.clear();
//       filteredAvailable.clear();
//       return;
//     }
//
//     final q = searchQuery.value;
//
//     filteredClaimed.value = claimedZipCodes
//         .where((z) => z.zipCode.contains(q) || z.state.toLowerCase().contains(q))
//         .toList();
//
//     filteredAvailable.value = availableZipCodes
//         .where((z) => z.zipCode.contains(q) || z.state.toLowerCase().contains(q))
//         .toList();
//   }
//
//   bool isZipProcessing(String zipCode) => processingZipCodes.contains(zipCode);
//
//   @override
//   void onClose() {
//     processingZipCodes.clear();
//     super.onClose();
//   }
// }
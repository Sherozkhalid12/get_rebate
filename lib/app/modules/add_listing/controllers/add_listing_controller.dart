import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/routes/app_pages.dart';

class AddListingController extends GetxController {

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipCodeController = TextEditingController();

  // Observable variables
  final _isLoading = false.obs;
  final _bacPercent = 2.5.obs;
  final _dualAgencyAllowed = false.obs;
  final _isListingAgent = Rxn<bool>(); // Null until answered
  final _selectedPhotos = <File>[].obs; // Changed to File objects
  final _agreeToLargerRebateForDualAgency = false.obs;
  final _dualAgencyTotalCommissionPercent =
      5.0.obs; // Default 5% total commission
  final _openHouses = <OpenHouseEntry>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  double get bacPercent => _bacPercent.value;
  bool get dualAgencyAllowed => _dualAgencyAllowed.value;
  bool? get isListingAgent => _isListingAgent.value;
  List<File> get selectedPhotos => _selectedPhotos;
  bool get agreeToLargerRebateForDualAgency =>
      _agreeToLargerRebateForDualAgency.value;
  double get dualAgencyTotalCommissionPercent =>
      _dualAgencyTotalCommissionPercent.value;
  List<OpenHouseEntry> get openHouses => _openHouses;
  bool get canAddMoreOpenHouses => _openHouses.length < 4;

  @override
  void onInit() {
    super.onInit();
    // Set default values
    _bacPercent.value = 2.5;
    _dualAgencyAllowed.value = false;
  }

  void updateBacPercent(double value) {
    _bacPercent.value = value;
  }

  void toggleDualAgency() {
    _dualAgencyAllowed.value = !_dualAgencyAllowed.value;
    // Reset rebate agreement when dual agency is toggled off
    if (!_dualAgencyAllowed.value) {
      _agreeToLargerRebateForDualAgency.value = false;
    }
  }

  void toggleAgreeToLargerRebate() {
    _agreeToLargerRebateForDualAgency.value =
        !_agreeToLargerRebateForDualAgency.value;
  }

  void updateDualAgencyTotalCommission(double value) {
    _dualAgencyTotalCommissionPercent.value = value;
  }

  void setIsListingAgent(bool value) {
    _isListingAgent.value = value;

    // If not listing agent, disable dual agency
    // (can't offer dual agency on someone else's listing)
    if (!value) {
      _dualAgencyAllowed.value = false;
    }
  }

  void addPhoto(File photoFile) {
    if (_selectedPhotos.length < 10) {
      // Max 10 photos
      _selectedPhotos.add(photoFile);
    } else {
      Get.snackbar('Limit Reached', 'You can add up to 10 photos');
    }
  }

  void removePhoto(int index) {
    _selectedPhotos.removeAt(index);
  }

  void addOpenHouse() {
    if (_openHouses.length >= 4) {
      Get.snackbar('Limit Reached', 'You can add up to 4 open houses');
      return;
    }
    _openHouses.add(OpenHouseEntry());
  }

  void removeOpenHouse(int index) {
    if (index >= 0 && index < _openHouses.length) {
      _openHouses.removeAt(index);
    }
  }

  void updateOpenHouseDate(int index, DateTime date) {
    if (index >= 0 && index < _openHouses.length) {
      _openHouses[index].date = date;
    }
  }

  void updateOpenHouseStartTime(int index, TimeOfDay time) {
    if (index >= 0 && index < _openHouses.length) {
      _openHouses[index].startTime = time;
    }
  }

  void updateOpenHouseEndTime(int index, TimeOfDay time) {
    if (index >= 0 && index < _openHouses.length) {
      _openHouses[index].endTime = time;
    }
  }

  void updateOpenHouseNotes(int index, String notes) {
    if (index >= 0 && index < _openHouses.length) {
      _openHouses[index].notes = notes;
    }
  }

  Future<void> submitListing() async {
    if (!_validateForm()) return;

    try {
      _isLoading.value = true;

      // Get authenticated user ID
      final authController = Get.find<global.AuthController>();
      final currentUser = authController.currentUser;
      final agentId = currentUser?.id ?? '';

      if (agentId.isEmpty) {
        Get.snackbar('Error', 'Please login to create a listing');
        return;
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      Get.snackbar(
        'Success',
        'Listing created successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate to agent home page
      Get.offAllNamed(AppPages.AGENT);
    } catch (e) {
      Get.snackbar('Error', 'Failed to create listing: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  bool _validateForm() {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a title');
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a description');
      return false;
    }

    if (priceController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a price');
      return false;
    }

    final price = double.tryParse(priceController.text);
    if (price == null || price <= 0) {
      Get.snackbar('Error', 'Please enter a valid price');
      return false;
    }

    if (addressController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter an address');
      return false;
    }

    if (cityController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a city');
      return false;
    }

    if (stateController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a state');
      return false;
    }

    if (zipCodeController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a ZIP code');
      return false;
    }

    // CRITICAL: Verify listing agent status
    if (_isListingAgent.value == null) {
      Get.snackbar(
        'Error',
        'Please confirm if you are the listing agent for this property',
        duration: const Duration(seconds: 4),
      );
      return false;
    }

    // Warning if not the listing agent
    if (_isListingAgent.value == false) {
      Get.snackbar(
        'Warning',
        'You indicated you are NOT the listing agent. Dual agency will not be available, and commission structure may differ.',
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }

    return true;
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipCodeController.dispose();
    super.onClose();
  }
}

// Helper class for managing open house entries during form filling
class OpenHouseEntry {
  DateTime date;
  TimeOfDay startTime;
  TimeOfDay endTime;
  String notes;

  OpenHouseEntry({
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? notes,
  }) : date = date ?? DateTime.now(),
       startTime = startTime ?? const TimeOfDay(hour: 10, minute: 0),
       endTime = endTime ?? const TimeOfDay(hour: 14, minute: 0),
       notes = notes ?? '';
}

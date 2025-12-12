import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:get_storage/get_storage.dart';

class AddListingController extends GetxController {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://d3bae2a4822b.ngrok-free.app/api/v1';

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
      final authToken = GetStorage().read('auth_token');

      if (agentId.isEmpty) {
        Get.snackbar('Error', 'Please login to create a listing');
        return;
      }

      // Prepare form data
      final formData = FormData();

      // Add text fields
      formData.fields.addAll([
        MapEntry('propertyTitle', titleController.text.trim()),
        MapEntry('description', descriptionController.text.trim()),
        MapEntry('price', priceController.text.trim()),
        MapEntry('BACPercentage', _bacPercent.value.toString()),
        MapEntry('listingAgent', (_isListingAgent.value ?? false).toString()),
        MapEntry('dualAgencyAllowed', _dualAgencyAllowed.value.toString()),
        MapEntry('streetAddress', addressController.text.trim()),
        MapEntry('city', cityController.text.trim()),
        MapEntry('state', stateController.text.trim()),
        MapEntry('zipCode', zipCodeController.text.trim()),
        MapEntry('id', agentId),
      ]);

      // Format open houses as JSON array
      if (_openHouses.isNotEmpty) {
        final openHousesJson = _openHouses.map((oh) {
          final dateStr = oh.date.toIso8601String().split('T')[0]; // YYYY-MM-DD
          final startTimeStr = _formatTimeOfDay(oh.startTime);
          final endTimeStr = _formatTimeOfDay(oh.endTime);

          return {
            'date': dateStr,
            'fromTime': startTimeStr,
            'toTime': endTimeStr,
            'notes': oh.notes,
          };
        }).toList();

        formData.fields.add(MapEntry('openHouses', jsonEncode(openHousesJson)));
      } else {
        formData.fields.add(MapEntry('openHouses', jsonEncode([])));
      }

      // Add property photos (files)
      for (var photo in _selectedPhotos) {
        final fileName = photo.path.split('/').last;
        formData.files.add(
          MapEntry(
            'propertyPhotos',
            await MultipartFile.fromFile(photo.path, filename: fileName),
          ),
        );
      }

      print('🚀 Sending POST request to: $_baseUrl/agent/createListing/');
      print('📤 Request Data:');
      print('  - propertyTitle: ${titleController.text.trim()}');
      print('  - description: ${descriptionController.text.trim()}');
      print('  - price: ${priceController.text.trim()}');
      print('  - BACPercentage: ${_bacPercent.value}');
      print('  - listingAgent: ${_isListingAgent.value ?? false}');
      print('  - dualAgencyAllowed: ${_dualAgencyAllowed.value}');
      print('  - streetAddress: ${addressController.text.trim()}');
      print('  - city: ${cityController.text.trim()}');
      print('  - state: ${stateController.text.trim()}');
      print('  - zipCode: ${zipCodeController.text.trim()}');
      print('  - id: $agentId');
      print('  - propertyPhotos: ${_selectedPhotos.length} file(s)');
      print('  - openHouses: ${_openHouses.length} entry(ies)');

      // Setup Dio with auth token
      _dio.options.baseUrl = _baseUrl;
      _dio.options.headers = {
        'Content-Type': 'multipart/form-data',
        'ngrok-skip-browser-warning': 'true',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      // Make API call
      final response = await _dio.post('/agent/createListing/', data: formData);

      // Handle successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ SUCCESS - Status Code: ${response.statusCode}');
        print('📥 Response Data:');
        print(response.data);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        Get.snackbar(
          'Success',
          'Listing created successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate to agent home page
        Get.offAllNamed(AppPages.AGENT);
      }
    } on DioException catch (e) {
      // Handle Dio errors
      print('❌ ERROR - Status Code: ${e.response?.statusCode ?? "N/A"}');
      print('📥 Error Response:');
      print(e.response?.data ?? e.message);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      String errorMessage = 'Failed to create listing. Please try again.';

      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'Invalid request. Please check your input.';
        } else {
          errorMessage = e.response?.statusMessage ?? errorMessage;
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
      Get.snackbar('Error', 'Failed to create listing: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
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

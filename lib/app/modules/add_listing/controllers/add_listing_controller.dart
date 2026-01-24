import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/models/zip_code_model.dart';
import 'package:getrebate/app/modules/agent/controllers/agent_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:get_storage/get_storage.dart';

import '../../../widgets/custom_snackbar.dart';

class AddListingController extends GetxController {
  final Dio _dio = Dio();
  // Using ApiConstants for centralized URL management
  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipCodeController = TextEditingController();
  final _selectedClaimedZip = Rxn<ZipCodeModel>();

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

  // Property details fields (for propertyDetails JSON)
  final _propertyType = 'house'.obs; // Default to 'house'
  final _propertyStatus = 'active'.obs; // Default to 'active'
  final _bedrooms = ''.obs;
  final _bathrooms = ''.obs;
  final _squareFeet = ''.obs;

  // Property features (array)
  final _propertyFeatures = <String>[].obs;

  // Status field (separate from propertyDetails.status)
  final _listingStatus = 'active'.obs; // Default to 'active'

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
  ZipCodeModel? get selectedClaimedZip => _selectedClaimedZip.value;
  String get propertyType => _propertyType.value;
  String get propertyStatus => _propertyStatus.value;
  String get bedrooms => _bedrooms.value;
  String get bathrooms => _bathrooms.value;
  String get squareFeet => _squareFeet.value;
  List<String> get propertyFeatures => _propertyFeatures;
  String get listingStatus => _listingStatus.value;

  void setPropertyType(String type) => _propertyType.value = type;
  void setPropertyStatus(String status) => _propertyStatus.value = status;
  void setBedrooms(String value) => _bedrooms.value = value;
  void setBathrooms(String value) => _bathrooms.value = value;
  void setSquareFeet(String value) => _squareFeet.value = value;
  void togglePropertyFeature(String feature) {
    if (_propertyFeatures.contains(feature)) {
      _propertyFeatures.remove(feature);
    } else {
      _propertyFeatures.add(feature);
    }
  }

  void setListingStatus(String status) => _listingStatus.value = status;

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

  void selectClaimedZip(ZipCodeModel? zip) {
    _selectedClaimedZip.value = zip;
    if (zip != null) {
      zipCodeController.text = zip.zipCode;
      stateController.text = zip.state;
    }
  }

  void addPhoto(File photoFile) {
    if (_selectedPhotos.length < 10) {
      // Max 10 photos
      _selectedPhotos.add(photoFile);
    } else {
      SnackbarHelper.showInfo(
        'You can add up to 10 photos',
        title: 'Limit Reached',
      );
    }
  }

  void removePhoto(int index) {
    _selectedPhotos.removeAt(index);
  }

  void addOpenHouse() {
    if (_openHouses.length >= 4) {
      SnackbarHelper.showInfo(
        'You can add up to 4 open houses',
        title: 'Limit Reached',
      );
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
        _isLoading.value = false;
        SnackbarHelper.showError('Please login to create a listing');
        return;
      }

      // Prepare form data
      final formData = FormData();

      // Add text fields (matching API exactly)
      final listingCommissionPercent =
          (_dualAgencyTotalCommissionPercent.value - _bacPercent.value).clamp(
            0.0,
            double.infinity,
          );
      final listingSideCommissionPayload = {
        'totalCommission': _dualAgencyTotalCommissionPercent.value,
        'listingCommission': listingCommissionPercent,
      };
      formData.fields.addAll([
        MapEntry('propertyTitle', titleController.text.trim()),
        MapEntry('description', descriptionController.text.trim()),
        MapEntry('price', priceController.text.trim()),
        MapEntry('BACPercentage', _bacPercent.value.toString()),
        MapEntry('listingAgent', (_isListingAgent.value ?? false).toString()),
        MapEntry('dualAgencyAllowed', _dualAgencyAllowed.value.toString()),
        MapEntry(
          'listingSideCommission',
          jsonEncode(listingSideCommissionPayload),
        ),
        MapEntry('streetAddress', addressController.text.trim()),
        MapEntry('city', cityController.text.trim()),
        MapEntry('state', stateController.text.trim()),
        MapEntry('zipCode', zipCodeController.text.trim()),
        MapEntry('id', agentId),
        MapEntry('status', _listingStatus.value), // Status field
        MapEntry('createdByRole', 'agent'), // Always 'agent' for this form
      ]);

      // Format open houses as JSON array (matching API format)
      final openHousesJson = _openHouses.map((oh) {
        final dateStr = oh.date.toIso8601String().split('T')[0]; // YYYY-MM-DD
        final startTimeStr = _formatTimeOfDay(oh.startTime);
        final endTimeStr = _formatTimeOfDay(oh.endTime);

        return {
          'date': dateStr,
          'fromTime': startTimeStr,
          'toTime': endTimeStr,
          if (oh.notes.isNotEmpty) 'specialNote': oh.notes,
        };
      }).toList();
      formData.fields.add(MapEntry('openHouses', jsonEncode(openHousesJson)));

      // Format propertyDetails as JSON object
      final propertyDetailsJson = {
        'type': _propertyType.value,
        'status': _propertyStatus.value,
        if (_squareFeet.value.isNotEmpty) 'squareFeet': _squareFeet.value,
        if (_bedrooms.value.isNotEmpty) 'bedrooms': _bedrooms.value,
        if (_bathrooms.value.isNotEmpty) 'bathrooms': _bathrooms.value,
      };
      formData.fields.add(
        MapEntry('propertyDetails', jsonEncode(propertyDetailsJson)),
      );

      // Format propertyFeatures as JSON array
      formData.fields.add(
        MapEntry('propertyFeatures', jsonEncode(_propertyFeatures)),
      );

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

      if (kDebugMode) {
        print(
          '🚀 Sending POST request to: ${ApiConstants.createListingEndpoint}',
        );
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
        print('  - status: ${_listingStatus.value}');
        print('  - createdByRole: agent');
        print('  - propertyDetails: $propertyDetailsJson');
        print('  - propertyFeatures: $_propertyFeatures');
        print('  - propertyPhotos: ${_selectedPhotos.length} file(s)');
        print('  - openHouses: ${_openHouses.length} entry(ies)');
      }

      // Setup Dio with auth token and timeouts
      _dio.options.baseUrl = ApiConstants.apiBaseUrl;
      _dio.options.headers = {
        ...ApiConstants.ngrokHeaders,
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };
      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(seconds: 30);
      _dio.options.sendTimeout = const Duration(seconds: 30);

      // Make API call
      final response = await _dio.post(
        ApiConstants.createListingEndpoint,
        data: formData,
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      // Handle successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ SUCCESS - Status Code: ${response.statusCode}');
          print('📥 Response Data:');
          print(response.data);
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }

        _isLoading.value = false;

        // Show success snackbar
        SnackbarHelper.showSuccess(
          'Listing created successfully!',
          title: 'Success',
        );

        final agentController = Get.find<AgentController>();
        agentController.setSelectedTab(0);

        // Navigate back after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(Get.context!);
      }
    } on DioException catch (e) {
      _isLoading.value = false;

      if (kDebugMode) {
        print('❌ ERROR - Status Code: ${e.response?.statusCode ?? "N/A"}');
        print('📥 Error Response:');
        print(e.response?.data ?? e.message);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      String errorMessage = 'Failed to create listing. Please try again.';

      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (responseData is Map && responseData.containsKey('error')) {
          errorMessage = responseData['error'].toString();
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'Invalid request. Please check your input.';
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
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

      SnackbarHelper.showError(errorMessage);
    } catch (e) {
      _isLoading.value = false;

      if (kDebugMode) {
        print('❌ Unexpected Error: ${e.toString()}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      CustomSnackbar.showError('Failed to create listing: ${e.toString()}');
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
      SnackbarHelper.showValidation('Please enter a property title');
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      SnackbarHelper.showValidation('Please enter a property description');
      return false;
    }

    if (priceController.text.trim().isEmpty) {
      SnackbarHelper.showValidation('Please enter a price');
      return false;
    }

    final price = double.tryParse(priceController.text.trim());
    if (price == null || price <= 0) {
      SnackbarHelper.showValidation('Please enter a valid price');
      return false;
    }

    if (addressController.text.trim().isEmpty) {
      SnackbarHelper.showValidation('Please enter a street address');
      return false;
    }

    if (cityController.text.trim().isEmpty) {
      SnackbarHelper.showValidation('Please enter a city');
      return false;
    }

    if (stateController.text.trim().isEmpty) {
      SnackbarHelper.showValidation('Please enter a state');
      return false;
    }

    if (_selectedClaimedZip.value == null) {
      SnackbarHelper.showValidation(
        'Please select a ZIP code from your claimed areas',
      );
      return false;
    }

    // CRITICAL: Verify listing agent status
    if (_isListingAgent.value == null) {
      SnackbarHelper.showValidation(
        'Please confirm if you are the listing agent for this property',
      );
      return false;
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

import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:get_storage/get_storage.dart';

class CreateListingController extends GetxController {
  final Dio _dio = Dio();
  final _isLoading = false.obs;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipCodeController = TextEditingController();
  final priceController = TextEditingController();
  final bedroomsController = TextEditingController();
  final bathroomsController = TextEditingController();
  final squareFeetController = TextEditingController();

  // Observable variables
  final _selectedPropertyType = 'house'.obs;
  final _selectedStatus = 'active'.obs; // Changed default to 'active'
  final _selectedFeatures = <String>[].obs;
  final _selectedPhotos = <File>[].obs; // Changed to File objects
  final _bacPercent = 2.5.obs;
  final _dualAgencyAllowed = false.obs;
  final _isListingAgent = true.obs; // Default to true
  final _openHouses = <OpenHouseEntry>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  GlobalKey<FormState> get formKey => _formKey;
  String get selectedPropertyType => _selectedPropertyType.value;
  String get selectedStatus => _selectedStatus.value;
  List<String> get selectedFeatures => _selectedFeatures;
  List<File> get selectedPhotos => _selectedPhotos;
  double get bacPercent => _bacPercent.value;
  bool get dualAgencyAllowed => _dualAgencyAllowed.value;
  bool get isListingAgent => _isListingAgent.value;
  List<OpenHouseEntry> get openHouses => _openHouses;
  
  void updateBacPercent(double value) => _bacPercent.value = value;
  void toggleDualAgency() => _dualAgencyAllowed.value = !_dualAgencyAllowed.value;
  void setIsListingAgent(bool value) => _isListingAgent.value = value;

  // Property types
  final List<String> propertyTypes = [
    'house',
    'condo',
    'townhouse',
    'apartment',
  ];

  // Status options
  final List<String> statusOptions = ['draft', 'active', 'pending', 'sold'];

  // Features
  final List<String> availableFeatures = [
    'garage',
    'pool',
    'fireplace',
    'hardwood_floors',
    'garden',
    'balcony',
    'elevator',
    'gym',
    'parking',
    'security',
  ];

  void setPropertyType(String type) {
    _selectedPropertyType.value = type;
  }

  void setStatus(String status) {
    _selectedStatus.value = status;
  }

  void toggleFeature(String feature) {
    if (_selectedFeatures.contains(feature)) {
      _selectedFeatures.remove(feature);
    } else {
      _selectedFeatures.add(feature);
    }
  }

  void addPhoto(File photoFile) {
    if (_selectedPhotos.length < 10) {
      _selectedPhotos.add(photoFile);
    } else {
      SnackbarHelper.showValidation('You can add up to 10 photos');
    }
  }

  void removePhoto(int index) {
    if (index >= 0 && index < _selectedPhotos.length) {
      _selectedPhotos.removeAt(index);
    }
  }
  
  void addOpenHouse() {
    if (_openHouses.length >= 4) {
      SnackbarHelper.showValidation('You can add up to 4 open houses');
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
  
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields
    if (!_validateForm()) {
      return;
    }

    try {
      _isLoading.value = true;

      // Get authenticated user ID
      final authController = Get.find<global.AuthController>();
      final currentUser = authController.currentUser;
      final agentId = currentUser?.id ?? '';
      final authToken = GetStorage().read('auth_token');

      if (agentId.isEmpty) {
        _isLoading.value = false;
        SnackbarHelper.showError(
          'Please login to create a listing',
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Prepare form data
      final formData = FormData();

      // Add text fields (matching API exactly)
      formData.fields.addAll([
        MapEntry('propertyTitle', titleController.text.trim()),
        MapEntry('description', descriptionController.text.trim()),
        MapEntry('price', priceController.text.trim()),
        MapEntry('BACPercentage', _bacPercent.value.toString()),
        MapEntry('listingAgent', _isListingAgent.value.toString()),
        MapEntry('dualAgencyAllowed', _dualAgencyAllowed.value.toString()),
        MapEntry('streetAddress', addressController.text.trim()),
        MapEntry('city', cityController.text.trim()),
        MapEntry('state', stateController.text.trim()),
        MapEntry('zipCode', zipCodeController.text.trim()),
        MapEntry('id', agentId),
        MapEntry('status', _selectedStatus.value),
        MapEntry('createdByRole', 'agent'),
      ]);

      // Format open houses as JSON array
      final openHousesJson = _openHouses.map((oh) {
        final dateStr = oh.date.toIso8601String().split('T')[0];
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
        'type': _selectedPropertyType.value,
        'status': _selectedStatus.value,
        if (squareFeetController.text.trim().isNotEmpty)
          'squareFeet': squareFeetController.text.trim(),
        if (bedroomsController.text.trim().isNotEmpty)
          'bedrooms': bedroomsController.text.trim(),
        if (bathroomsController.text.trim().isNotEmpty)
          'bathrooms': bathroomsController.text.trim(),
      };
      formData.fields.add(MapEntry('propertyDetails', jsonEncode(propertyDetailsJson)));

      // Format propertyFeatures as JSON array
      formData.fields.add(MapEntry('propertyFeatures', jsonEncode(_selectedFeatures)));

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
        print('🚀 Sending POST request to: ${ApiConstants.createListingEndpoint}');
        print('📤 Request Data:');
        print('  - propertyTitle: ${titleController.text.trim()}');
        print('  - description: ${descriptionController.text.trim()}');
        print('  - price: ${priceController.text.trim()}');
        print('  - status: ${_selectedStatus.value}');
        print('  - propertyDetails: $propertyDetailsJson');
        print('  - propertyFeatures: $_selectedFeatures');
        print('  - propertyPhotos: ${_selectedPhotos.length} file(s)');
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

        // Show success snackbar BEFORE navigating back (to avoid overlay issues)
        try {
          SnackbarHelper.showSuccess(
            'Listing created successfully!',
            title: 'Success',
            duration: const Duration(seconds: 2),
          );
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not show snackbar: $e');
          }
        }

        // Clear all form fields
        resetForm();

        // Navigate back after a short delay
        await Future.delayed(const Duration(milliseconds: 300));
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

      SnackbarHelper.showError(
        errorMessage,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      _isLoading.value = false;

      if (kDebugMode) {
        print('❌ Unexpected Error: ${e.toString()}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      SnackbarHelper.showError(
        'Failed to create listing: ${e.toString()}',
        duration: const Duration(seconds: 3),
      );
    }
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

    if (zipCodeController.text.trim().isEmpty) {
      SnackbarHelper.showValidation('Please enter a ZIP code');
      return false;
    }

    return true;
  }

  void resetForm() {
    titleController.clear();
    descriptionController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    zipCodeController.clear();
    priceController.clear();
    bedroomsController.clear();
    bathroomsController.clear();
    squareFeetController.clear();
    _selectedPropertyType.value = 'house';
    _selectedStatus.value = 'active';
    _selectedFeatures.clear();
    _selectedPhotos.clear();
    _openHouses.clear();
    _bacPercent.value = 2.5;
    _dualAgencyAllowed.value = false;
    _isListingAgent.value = true;
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipCodeController.dispose();
    priceController.dispose();
    bedroomsController.dispose();
    bathroomsController.dispose();
    squareFeetController.dispose();
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


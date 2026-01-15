import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/utils/network_error_handler.dart';
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
      if (kDebugMode) {
        print('📸 Preparing to upload ${_selectedPhotos.length} photo(s)');
      }
      
      for (int i = 0; i < _selectedPhotos.length; i++) {
        final photo = _selectedPhotos[i];
        final fileName = photo.path.split('/').last;
        
        // Verify file exists and is readable
        if (!await photo.exists()) {
          if (kDebugMode) {
            print('❌ Photo file does not exist: ${photo.path}');
          }
          continue;
        }
        
        try {
          final fileSize = await photo.length();
          if (kDebugMode) {
            print('📸 Photo [$i]: $fileName (${(fileSize / 1024).toStringAsFixed(2)} KB)');
            print('   Path: ${photo.path}');
          }
          
          // Read file bytes to ensure file is accessible
          final fileBytes = await photo.readAsBytes();
          if (kDebugMode) {
            print('   File bytes read: ${fileBytes.length} bytes');
          }
          
          // Create multipart file from bytes
          // This ensures the file is sent as multipart/form-data
          // Determine content type from file extension
          String? contentType;
          if (fileName.toLowerCase().endsWith('.png')) {
            contentType = 'image/png';
          } else if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) {
            contentType = 'image/jpeg';
          } else if (fileName.toLowerCase().endsWith('.gif')) {
            contentType = 'image/gif';
          } else {
            contentType = 'image/png'; // Default
          }
          
          final multipartFile = MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
          );
          
          // Use exact field name 'propertyPhotos' to match server's multer configuration
          // Multer expects this exact field name (without brackets) for multiple files
          formData.files.add(
            MapEntry(
              'propertyPhotos',
              multipartFile,
            ),
          );
          
          if (kDebugMode) {
            print('✅ Photo [$i] added to formData as multipart file');
            print('   Content-Type: $contentType');
            print('   Length: ${multipartFile.length} bytes');
            print('   Filename: $fileName');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error adding photo [$i]: $e');
            print('   Stack trace: ${StackTrace.current}');
          }
        }
      }
      
      if (kDebugMode) {
        print('📊 FormData Summary:');
        print('   - Fields: ${formData.fields.length}');
        print('   - Files: ${formData.files.length}');
        print('🚀 Sending POST request to: ${ApiConstants.createListingEndpoint}');
        print('📤 Request Data:');
        print('  - propertyTitle: ${titleController.text.trim()}');
        print('  - description: ${descriptionController.text.trim()}');
        print('  - price: ${priceController.text.trim()}');
        print('  - status: ${_selectedStatus.value}');
        print('  - propertyDetails: $propertyDetailsJson');
        print('  - propertyFeatures: $_selectedFeatures');
        print('  - propertyPhotos: ${formData.files.length} file(s) uploaded');
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

      // Verify formData has files before sending
      if (kDebugMode) {
        print('📋 Final FormData check before sending:');
        print('   Total fields: ${formData.fields.length}');
        print('   Total files: ${formData.files.length}');
        if (formData.files.isEmpty && _selectedPhotos.isNotEmpty) {
          print('⚠️ WARNING: Selected photos (${_selectedPhotos.length}) but no files in formData!');
        }
      }

      // Make API call with explicit multipart options
      if (kDebugMode) {
        print('📡 Making POST request with FormData:');
        print('   Endpoint: ${ApiConstants.createListingEndpoint}');
        print('   Files count: ${formData.files.length}');
        print('   Fields count: ${formData.fields.length}');
        // Log all file entries
        for (int i = 0; i < formData.files.length; i++) {
          final entry = formData.files[i];
          print('   File [$i]: key="${entry.key}", filename="${entry.value.filename}"');
        }
      }

      final response = await _dio.post(
        ApiConstants.createListingEndpoint,
        data: formData,
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            if (authToken != null) 'Authorization': 'Bearer $authToken',
            // Don't set Content-Type manually - Dio will automatically set multipart/form-data with boundary
          },
          // Ensure we're sending as multipart
          followRedirects: false,
          validateStatus: (status) => status! < 500,
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

      NetworkErrorHandler.handleError(
        e,
        defaultMessage: 'Unable to create listing. Please check your internet connection and try again.',
      );
    } catch (e) {
      _isLoading.value = false;

      if (kDebugMode) {
        print('❌ Unexpected Error: ${e.toString()}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      NetworkErrorHandler.handleError(
        e,
        defaultMessage: 'Unable to create listing. Please check your internet connection and try again.',
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


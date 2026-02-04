import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/models/property_model.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/controllers/location_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/widgets/custom_snackbar.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:get_storage/get_storage.dart';

class EditListingController extends GetxController {
  final LocationController _locationController = Get.find<LocationController>();
  final Dio _dio = Dio();
  final _isLoading = false.obs;
  final _formKey = GlobalKey<FormState>();
  late PropertyModel _originalProperty;
  late String _listingId;

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
  final _selectedStatus = 'draft'.obs;
  final _selectedFeatures = <String>[].obs;
  final _existingImages = <String>[].obs; // URLs from API
  final _newPhotos = <File>[].obs; // New files to upload
  final _bacPercent = 2.5.obs;
  final _dualAgencyAllowed = false.obs;
  final _isListingAgent = true.obs;
  final _openHouses = <OpenHouseEntry>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  GlobalKey<FormState> get formKey => _formKey;
  String get selectedPropertyType => _selectedPropertyType.value;
  String get selectedStatus => _selectedStatus.value;
  List<String> get selectedFeatures => _selectedFeatures;
  List<String> get existingImages => _existingImages;
  List<File> get newPhotos => _newPhotos;
  List<String> get allImages => [..._existingImages, ..._newPhotos.map((f) => f.path)];
  // For backward compatibility with view
  List<String> get images => allImages;
  PropertyModel get originalProperty => _originalProperty;
  double get bacPercent => _bacPercent.value;
  bool get dualAgencyAllowed => _dualAgencyAllowed.value;
  bool get isListingAgent => _isListingAgent.value;
  List<OpenHouseEntry> get openHouses => _openHouses;

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

  @override
  void onInit() {
    super.onInit();
    _loadPropertyData();
  }

  void _loadPropertyData() {
    final property = Get.arguments?['property'] as PropertyModel?;
    if (property != null) {
      _originalProperty = property;
      _populateForm(property);
    } else {
      Navigator.pop(Get.context!);
      Get.snackbar('Error', 'Property data not found');
    }
  }

  void _populateForm(PropertyModel property) {
    _listingId = property.id;
    titleController.text = property.title;
    descriptionController.text = property.description;
    addressController.text = property.address;
    cityController.text = property.city;
    stateController.text = property.state;
    zipCodeController.text = property.zipCode;
    priceController.text = property.price.toString();
    bedroomsController.text = property.bedrooms.toString();
    bathroomsController.text = property.bathrooms.toString();
    squareFeetController.text = property.squareFeet.toString();

    _selectedPropertyType.value = property.propertyType;
    _selectedStatus.value = property.status;
    _existingImages.value = List.from(property.images);
    _newPhotos.value = [];

    // Populate features
    _selectedFeatures.clear();
    property.features?.forEach((key, value) {
      if (value == true) {
        _selectedFeatures.add(key);
      }
    });
  }
  
  void updateBacPercent(double value) => _bacPercent.value = value;
  void toggleDualAgency() => _dualAgencyAllowed.value = !_dualAgencyAllowed.value;
  void setIsListingAgent(bool value) => _isListingAgent.value = value;
  
  void addPhoto(File photoFile) {
    if (_newPhotos.length + _existingImages.length < 10) {
      _newPhotos.add(photoFile);
    } else {
      CustomSnackbar.showValidation('You can add up to 10 photos');
    }
  }

  void removeExistingImage(int index) {
    if (index >= 0 && index < _existingImages.length) {
      _existingImages.removeAt(index);
    }
  }

  void removeNewPhoto(int index) {
    if (index >= 0 && index < _newPhotos.length) {
      _newPhotos.removeAt(index);
    }
  }
  
  // For backward compatibility with view
  void removeImage(int index) {
    // If index is in existing images range, remove from existing
    if (index < _existingImages.length) {
      removeExistingImage(index);
    } else {
      // Otherwise, remove from new photos (adjust index)
      final newIndex = index - _existingImages.length;
      if (newIndex >= 0 && newIndex < _newPhotos.length) {
        removeNewPhoto(newIndex);
      }
    }
  }
  
  // For backward compatibility - accepts String URL or File
  void addImage(dynamic image) {
    if (image is File) {
      addPhoto(image);
    } else if (image is String) {
      // If it's a URL, add to existing images
      if (!_existingImages.contains(image) && _existingImages.length + _newPhotos.length < 10) {
        _existingImages.add(image);
      } else if (_existingImages.length + _newPhotos.length >= 10) {
        CustomSnackbar.showValidation('You can add up to 10 photos');
      }
    }
  }
  
  void addOpenHouse() {
    if (_openHouses.length >= 4) {
      CustomSnackbar.showValidation('You can add up to 4 open houses');
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
  
  bool _validateForm() {
    if (titleController.text.trim().isEmpty) {
      CustomSnackbar.showValidation('Please enter a property title');
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      CustomSnackbar.showValidation('Please enter a description');
      return false;
    }
    if (priceController.text.trim().isEmpty) {
      CustomSnackbar.showValidation('Please enter a price');
      return false;
    }
    final price = double.tryParse(priceController.text);
    if (price == null || price <= 0) {
      CustomSnackbar.showValidation('Please enter a valid price');
      return false;
    }
    if (addressController.text.trim().isEmpty) {
      CustomSnackbar.showValidation('Please enter a street address');
      return false;
    }
    if (cityController.text.trim().isEmpty) {
      CustomSnackbar.showValidation('Please enter a city');
      return false;
    }
    if (stateController.text.trim().isEmpty) {
      CustomSnackbar.showValidation('Please enter a state');
      return false;
    }
    if (zipCodeController.text.trim().isEmpty) {
      CustomSnackbar.showValidation('Please enter any ZIP code of selected state');
      return false;
    }
    if (_existingImages.isEmpty && _newPhotos.isEmpty) {
      CustomSnackbar.showValidation('Please add at least one property photo');
      return false;
    }
    return true;
  }

  /// Uses cached current location zip for the ZIP code field (instant, no fetch on tap).
  void useCurrentLocationForZip() {
    final zipCode = _locationController.currentZipCode;
    if (zipCode != null &&
        zipCode.length == 5 &&
        RegExp(r'^\d+$').hasMatch(zipCode)) {
      zipCodeController.text = zipCode;
      zipCodeController.selection = TextSelection.collapsed(offset: zipCode.length);
    } else {
      SnackbarHelper.showInfo(
        'Location not ready yet. Please wait a moment and try again, or enter ZIP manually.',
        title: 'Location',
        duration: const Duration(seconds: 3),
      );
    }
  }

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
        CustomSnackbar.showError('Please login to update a listing');
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
          'squareFootage': squareFeetController.text.trim(),
        if (bedroomsController.text.trim().isNotEmpty)
          'bedrooms': bedroomsController.text.trim(),
        if (bathroomsController.text.trim().isNotEmpty)
          'bathrooms': bathroomsController.text.trim(),
      };
      formData.fields.add(MapEntry('propertyDetails', jsonEncode(propertyDetailsJson)));

      // Format propertyFeatures as JSON array
      formData.fields.add(MapEntry('propertyFeatures', jsonEncode(_selectedFeatures)));

      // Add new property photos (files)
      for (var photo in _newPhotos) {
        final fileName = photo.path.split('/').last;
        formData.files.add(
          MapEntry(
            'propertyPhotos',
            await MultipartFile.fromFile(photo.path, filename: fileName),
          ),
        );
      }

      if (kDebugMode) {
        print('🚀 Sending PUT request to: ${ApiConstants.getUpdateListingEndpoint(_listingId)}');
        print('📤 Request Data:');
        print('  - propertyTitle: ${titleController.text.trim()}');
        print('  - description: ${descriptionController.text.trim()}');
        print('  - price: ${priceController.text.trim()}');
        print('  - status: ${_selectedStatus.value}');
        print('  - propertyDetails: $propertyDetailsJson');
        print('  - propertyFeatures: $_selectedFeatures');
        print('  - propertyPhotos: ${_newPhotos.length} new file(s)');
        print('  - existingImages: ${_existingImages.length} image(s)');
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

      // Make API call (PUT request)
      final response = await _dio.put(
        ApiConstants.getUpdateListingEndpoint(_listingId).replaceFirst(ApiConstants.apiBaseUrl, ''),
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
        CustomSnackbar.showSuccess(
          'Success',
          'Listing updated successfully!',
        );

        // Navigate back after a short delay
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pop(Get.context!, true); // Return true to indicate success
      }
    } on DioException catch (e) {
      _isLoading.value = false;

      if (kDebugMode) {
        print('❌ ERROR - Status Code: ${e.response?.statusCode ?? "N/A"}');
        print('📥 Error Response:');
        print(e.response?.data ?? e.message);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      String errorMessage = 'Failed to update listing. Please try again.';

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
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Listing not found.';
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        } else {
          errorMessage = e.response?.statusMessage ?? errorMessage;
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      CustomSnackbar.showError(errorMessage);
    } catch (e) {
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ Unexpected Error: ${e.toString()}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      CustomSnackbar.showError('Failed to update listing: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  void resetForm() {
    _populateForm(_originalProperty);
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

// OpenHouseEntry class for managing open house data
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

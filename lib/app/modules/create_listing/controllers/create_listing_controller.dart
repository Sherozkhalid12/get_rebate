import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getrebate/app/models/property_model.dart';

class CreateListingController extends GetxController {
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
  final _selectedStatus = 'draft'.obs;
  final _selectedFeatures = <String>[].obs;
  final _images = <String>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  GlobalKey<FormState> get formKey => _formKey;
  String get selectedPropertyType => _selectedPropertyType.value;
  String get selectedStatus => _selectedStatus.value;
  List<String> get selectedFeatures => _selectedFeatures;
  List<String> get images => _images;

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

  void addImage(String imageUrl) {
    _images.add(imageUrl);
  }

  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
    }
  }

  void submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _isLoading.value = true;

    try {
      // Create property model
      final property = PropertyModel(
        id: 'prop_${DateTime.now().millisecondsSinceEpoch}',
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        address: addressController.text.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim(),
        zipCode: zipCodeController.text.trim(),
        price: (double.tryParse(priceController.text) ?? 0).toDouble(),
        bedrooms: int.tryParse(bedroomsController.text) ?? 0,
        bathrooms: int.tryParse(bathroomsController.text) ?? 0,
        squareFeet: (int.tryParse(squareFeetController.text) ?? 0).toDouble(),
        propertyType: _selectedPropertyType.value,
        status: _selectedStatus.value,
        images: _images.toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: 'user_1', // This would come from auth
        features: Map.fromIterable(
          _selectedFeatures,
          key: (feature) => feature,
          value: (feature) => true,
        ),
      );

      // Here you would typically save to a database
      // For now, we'll just show success and go back

      Get.snackbar(
        'Success',
        'Property listing created successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate back
      Get.back(result: property);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create listing: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
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
    _selectedStatus.value = 'draft';
    _selectedFeatures.clear();
    _images.clear();
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

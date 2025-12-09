import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getrebate/app/models/property_model.dart';

class EditListingController extends GetxController {
  final _isLoading = false.obs;
  final _formKey = GlobalKey<FormState>();
  late PropertyModel _originalProperty;

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
  PropertyModel get originalProperty => _originalProperty;

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
      Get.back();
      Get.snackbar('Error', 'Property data not found');
    }
  }

  void _populateForm(PropertyModel property) {
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
    _images.value = List.from(property.images);

    // Populate features
    _selectedFeatures.clear();
    property.features?.forEach((key, value) {
      if (value == true) {
        _selectedFeatures.add(key);
      }
    });
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
      // Create updated property model
      final updatedProperty = _originalProperty.copyWith(
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
        updatedAt: DateTime.now(),
        features: Map.fromIterable(
          _selectedFeatures,
          key: (feature) => feature,
          value: (feature) => true,
        ),
      );

      // Here you would typically update in a database
      // For now, we'll just show success and go back

      Get.snackbar(
        'Success',
        'Property listing updated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate back with updated property
      Get.back(result: updatedProperty);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update listing: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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

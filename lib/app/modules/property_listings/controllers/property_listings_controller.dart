import 'package:get/get.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getrebate/app/models/property_model.dart';
import 'package:getrebate/app/routes/app_pages.dart';

class PropertyListingsController extends GetxController {
  final _properties = <PropertyModel>[].obs;
  final _isLoading = false.obs;
  final _selectedStatus =
      'all'.obs; // 'all', 'active', 'pending', 'sold', 'draft'
  final _selectedPropertyType =
      'all'.obs; // 'all', 'house', 'condo', 'townhouse'
  final _selectedPriceRange =
      'all'.obs; // 'all', 'under_500k', '500k_1m', 'over_1m'
  final _searchQuery = ''.obs;

  // Getters
  List<PropertyModel> get properties => _properties;
  bool get isLoading => _isLoading.value;
  String get selectedStatus => _selectedStatus.value;
  String get selectedPropertyType => _selectedPropertyType.value;
  String get selectedPriceRange => _selectedPriceRange.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    _loadMockData();
  }

  void _loadMockData() {
    _properties.value = [
      PropertyModel(
        id: 'prop_1',
        title: 'Beautiful Family Home',
        description:
            'Spacious 3-bedroom home with modern amenities and a large backyard perfect for families.',
        address: '123 Main Street',
        city: 'New York',
        state: 'NY',
        zipCode: '10001',
        price: 750000,
        bedrooms: 3,
        bathrooms: 2,
        squareFeet: 1800,
        propertyType: 'house',
        status: 'active',
        images: [
          'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&h=600&fit=crop',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ownerId: 'user_1',
        features: {
          'garage': true,
          'pool': false,
          'fireplace': true,
          'hardwood_floors': true,
        },
        lotSize: 0.25,
        yearBuilt: 2015,
        mlsNumber: 'MLS123456',
      ),
      PropertyModel(
        id: 'prop_2',
        title: 'Modern Downtown Condo',
        description:
            'Luxury condo in the heart of downtown with stunning city views and premium finishes.',
        address: '456 Downtown Ave',
        city: 'New York',
        state: 'NY',
        zipCode: '10002',
        price: 950000,
        bedrooms: 2,
        bathrooms: 2,
        squareFeet: 1200,
        propertyType: 'condo',
        status: 'pending',
        images: [
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&h=600&fit=crop',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ownerId: 'user_1',
        features: {
          'garage': true,
          'pool': true,
          'fireplace': false,
          'hardwood_floors': true,
          'balcony': true,
        },
        yearBuilt: 2020,
        mlsNumber: 'MLS789012',
      ),
      PropertyModel(
        id: 'prop_3',
        title: 'Charming Townhouse',
        description:
            'Historic townhouse with original character and modern updates throughout.',
        address: '789 Historic Lane',
        city: 'Brooklyn',
        state: 'NY',
        zipCode: '11201',
        price: 650000,
        bedrooms: 4,
        bathrooms: 3,
        squareFeet: 2200,
        propertyType: 'townhouse',
        status: 'draft',
        images: [
          'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800&h=600&fit=crop',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        ownerId: 'user_1',
        features: {
          'garage': false,
          'pool': false,
          'fireplace': true,
          'hardwood_floors': true,
          'garden': true,
        },
        lotSize: 0.15,
        yearBuilt: 1920,
      ),
    ];
  }

  void setSelectedStatus(String status) {
    _selectedStatus.value = status;
  }

  void setSelectedPropertyType(String type) {
    _selectedPropertyType.value = type;
  }

  void setSelectedPriceRange(String range) {
    _selectedPriceRange.value = range;
  }

  void setSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void clearFilters() {
    _selectedStatus.value = 'all';
    _selectedPropertyType.value = 'all';
    _selectedPriceRange.value = 'all';
    _searchQuery.value = '';
  }

  List<PropertyModel> get filteredProperties {
    var filtered = _properties.where((property) {
      // Status filter
      if (_selectedStatus.value != 'all' &&
          property.status != _selectedStatus.value) {
        return false;
      }

      // Property type filter
      if (_selectedPropertyType.value != 'all' &&
          property.propertyType != _selectedPropertyType.value) {
        return false;
      }

      // Price range filter
      if (_selectedPriceRange.value != 'all') {
        switch (_selectedPriceRange.value) {
          case 'under_500k':
            if (property.price >= 500000) return false;
            break;
          case '500k_1m':
            if (property.price < 500000 || property.price > 1000000)
              return false;
            break;
          case 'over_1m':
            if (property.price <= 1000000) return false;
            break;
        }
      }

      // Search query filter
      if (_searchQuery.value.isNotEmpty) {
        final query = _searchQuery.value.toLowerCase();
        if (!property.title.toLowerCase().contains(query) &&
            !property.description.toLowerCase().contains(query) &&
            !property.address.toLowerCase().contains(query) &&
            !property.city.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    return filtered;
  }

  void createNewListing() async {
    // Navigate to create listing page
    try {
      final result = await Get.toNamed('/create-listing');
      if (result != null && result is PropertyModel) {
        // Add the new property to the list
        _properties.add(result);
        Get.snackbar('Success', 'Property listing created successfully!');
      }
    } catch (e) {
      print('Navigation error: $e');
      Get.snackbar('Error', 'Failed to navigate to create listing page');
    }
  }

  void editProperty(PropertyModel property) async {
    // Navigate to edit property page
    try {
      final result = await Get.toNamed(
        '/edit-listing',
        arguments: {'property': property},
      );
      if (result != null && result is PropertyModel) {
        // Update the property in the list
        final index = _properties.indexWhere((p) => p.id == result.id);
        if (index != -1) {
          _properties[index] = result;
          Get.snackbar('Success', 'Property listing updated successfully!');
        }
      }
    } catch (e) {
      print('Navigation error: $e');
      Get.snackbar('Error', 'Failed to navigate to edit listing page');
    }
  }

  void deleteProperty(String propertyId) {
    _properties.removeWhere((property) => property.id == propertyId);
    Get.snackbar('Success', 'Property deleted successfully');
  }

  void showDeleteConfirmation(String propertyId, String propertyTitle) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Property'),
        content: Text(
          'Are you sure you want to delete "$propertyTitle"? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              deleteProperty(propertyId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void updatePropertyStatus(String propertyId, String newStatus) {
    final index = _properties.indexWhere(
      (property) => property.id == propertyId,
    );
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
    }
  }

  String getStatusColor(String status) {
    switch (status) {
      case 'active':
        return '#4CAF50'; // Green
      case 'pending':
        return '#FF9800'; // Orange
      case 'sold':
        return '#2196F3'; // Blue
      case 'draft':
        return '#9E9E9E'; // Gray
      default:
        return '#9E9E9E';
    }
  }

  String getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'sold':
        return 'Sold';
      case 'draft':
        return 'Draft';
      default:
        return 'Unknown';
    }
  }

  String getPropertyTypeLabel(String type) {
    switch (type) {
      case 'house':
        return 'House';
      case 'condo':
        return 'Condo';
      case 'townhouse':
        return 'Townhouse';
      default:
        return 'Unknown';
    }
  }

  String getPriceRangeLabel(String range) {
    switch (range) {
      case 'under_500k':
        return 'Under \$500K';
      case '500k_1m':
        return '\$500K - \$1M';
      case 'over_1m':
        return 'Over \$1M';
      default:
        return 'All Prices';
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/demo_data/demo_property_data.dart';

class PropertyDetailController extends GetxController {
  // Property data
  final Map<String, dynamic> property =
      Get.arguments ?? DemoPropertyData.getSampleProperty();

  // Observable variables
  final _isLoading = false.obs;
  final _isFavorite = false.obs;
  final _currentImageIndex = 0.obs;
  final _hasAcknowledgedRebateDisclosure = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isFavorite => _isFavorite.value;
  int get currentImageIndex => _currentImageIndex.value;
  bool get hasAcknowledgedRebateDisclosure =>
      _hasAcknowledgedRebateDisclosure.value;

  @override
  void onInit() {
    super.onInit();
    // Initialize property data
    _loadPropertyData();
  }

  void _loadPropertyData() {
    if (kDebugMode) {
      print('🏠 Property Detail View Loaded:');
      print('   Property ID: ${property['id']}');
      print('   Address: ${property['address']}');
      print('   Price: ${property['price']}');
      print('   Beds: ${property['beds']}');
      print('   Baths: ${property['baths']}');
      print('   Sqft: ${property['sqft']}');
      print('   Images: ${property['images']?.length ?? 0}');
      print('   Status: ${property['status']}');
      print('   BAC: ${property['bacPercent']}%');
      final desc = property['description']?.toString() ?? '';
      final descPreview = desc.isNotEmpty 
          ? (desc.length > 50 ? desc.substring(0, 50) : desc)
          : 'No description';
      print('   Description: $descPreview...');
      print('   Agent: ${property['agent']}');
      print('   Open Houses: ${property['openHouses']?.length ?? 0}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  void toggleFavorite() {
    _isFavorite.value = !_isFavorite.value;
    // TODO: Implement favorite functionality
  }

  void setCurrentImageIndex(int index) {
    _currentImageIndex.value = index;
  }

  void contactAgent() {
    // TODO: Implement contact agent functionality
    Get.snackbar('Contact Agent', 'Agent contact functionality coming soon!');
  }

  void scheduleShowing() {
    // TODO: Implement schedule showing functionality
    Get.snackbar(
      'Schedule Showing',
      'Schedule showing functionality coming soon!',
    );
  }

  void openBuyerLeadForm() {
    Get.toNamed(
      '/buyer-lead-form',
      arguments: {
        'property': property,
        'agent': property['agent'], // Assuming agent info is included
      },
    );
  }

  void openSellerLeadForm() {
    Get.toNamed(
      '/seller-lead-form',
      arguments: {
        'property': property,
        'agent': property['agent'], // Assuming agent info is included
      },
    );
  }

  void openRebateCalculator() {
    Get.toNamed('/rebate-calculator', arguments: {'property': property});
  }

  void acknowledgeRebateDisclosure() {
    _hasAcknowledgedRebateDisclosure.value = true;
    // TODO: Store this acknowledgment in the database/preferences
    Get.snackbar(
      'Acknowledged',
      'Thank you for reviewing the rebate disclosure',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}

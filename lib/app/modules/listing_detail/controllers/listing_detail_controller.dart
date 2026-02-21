import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/services/listing_service.dart';
import 'package:getrebate/app/services/listing_tracking_service.dart';

class ListingDetailController extends GetxController {
  final ListingService _listingService = InMemoryListingService();
  final ListingTrackingService _listingTrackingService = ListingTrackingService();
  final Rxn<Listing> _listing = Rxn<Listing>();
  final CarouselSliderController carouselController = CarouselSliderController();
  final _currentImageIndex = 0.obs;

  Listing? get listing => _listing.value;
  int get currentImageIndex => _currentImageIndex.value;
  
  List<String> get photoUrls => listing?.photoUrls ?? [];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    _listing.value = args?['listing'] as Listing?;
    if (listing != null) {
      _listingService.incrementStats(listing!.id, view: true);
      _listingTrackingService.recordListingView(listing!.id);
      
      // Print full listing data
      if (kDebugMode) {
        final listing = _listing.value!;
        print('\n' + '='*80);
        print('🏠 LISTING DETAIL - FULL DATA');
        print('='*80);
        print('📋 Listing Details:');
        print('   ID: ${listing.id}');
        print('   Agent ID: ${listing.agentId}');
        print('   Price: \$${(listing.priceCents / 100).toStringAsFixed(2)} (${listing.priceCents} cents)');
        print('   Address:');
        print('     Street: ${listing.address.street}');
        print('     City: ${listing.address.city}');
        print('     State: ${listing.address.state}');
        print('     ZIP: ${listing.address.zip}');
        print('     Full Address: ${listing.address.toString()}');
        print('   Photos (${listing.photoUrls.length}):');
        for (int j = 0; j < listing.photoUrls.length; j++) {
          print('     [${j + 1}] ${listing.photoUrls[j]}');
        }
        print('   BAC Percent: ${listing.bacPercent}%');
        print('   Dual Agency Allowed: ${listing.dualAgencyAllowed}');
        if (listing.dualAgencyCommissionPercent != null) {
          print('   Dual Agency Commission: ${listing.dualAgencyCommissionPercent}%');
        }
        print('   Created At: ${listing.createdAt}');
        print('   Stats:');
        print('     Searches: ${listing.stats.searches}');
        print('     Views: ${listing.stats.views}');
        print('     Contacts: ${listing.stats.contacts}');
        print('   JSON: ${listing.toJson()}');
        print('='*80);
        print('📍 ZIP Code for Find Agents: ${listing.address.zip}');
        print('='*80 + '\n');
      }
    }
  }

  void onImageChanged(int index) {
    _currentImageIndex.value = index;
  }

  /// Record listing contact - call when user taps contact (phone/email)
  void recordListingContact() {
    if (listing != null && listing!.id.isNotEmpty) {
      _listingTrackingService.recordListingContact(listing!.id);
    }
  }

  @override
  void onClose() {
    // CarouselSliderController doesn't need disposal
    super.onClose();
  }
}

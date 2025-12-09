import 'package:get/get.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/services/listing_service.dart';

class ListingDetailController extends GetxController {
  final ListingService _listingService = InMemoryListingService();
  final Rxn<Listing> _listing = Rxn<Listing>();

  Listing? get listing => _listing.value;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    _listing.value = args?['listing'] as Listing?;
    if (listing != null) {
      _listingService.incrementStats(listing!.id, view: true);
    }
  }
}

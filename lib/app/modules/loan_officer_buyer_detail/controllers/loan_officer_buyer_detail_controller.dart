import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/buyer_connection_model.dart';

class LoanOfficerBuyerDetailController extends GetxController {
  final _buyerConnection = Rxn<BuyerConnectionModel>();

  BuyerConnectionModel? get buyerConnection => _buyerConnection.value;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['buyerConnection'] != null) {
      _buyerConnection.value = args['buyerConnection'] as BuyerConnectionModel;
    } else {
      if (kDebugMode) {
        print('⚠️ No buyer connection data provided');
      }
    }
  }
}



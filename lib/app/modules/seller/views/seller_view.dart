import 'package:flutter/material.dart';
import 'package:getrebate/app/modules/buyer/views/buyer_view.dart';

// SellerView now uses the same home page as buyers with the 4-tab structure
class SellerView extends StatelessWidget {
  const SellerView({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the same view structure as buyers (Agents, Homes for Sale, Open Houses, Loan Officers)
    return const BuyerView();
  }
}

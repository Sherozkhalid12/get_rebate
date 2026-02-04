class RebateCalculatorService {
  // Buyer keeps 30% of BAC when working with an agent from this site
  static const double standardRebatePercentage = 0.30;

  // Buyer keeps 40% of the total commission when going directly to listing agent
  static const double dualAgencyDirectSharePercentage = 0.40;

  /// Calculates potential rebate range based on BAC percentage
  static RebateRange calculateRebateRange({
    required double listPrice,
    required double bacPercentage,
    required bool allowsDualAgency,
    double? dualAgencyCommissionPercentage,
  }) {
    // Calculate standard rebate using the actual BAC entered for the listing.
    final minStandardRebate = listPrice * bacPercentage * standardRebatePercentage;
    final maxStandardRebate = minStandardRebate;

    // Calculate dual agency rebate from the total commission (if provided),
    // otherwise fall back to the BAC value.
    double? dualAgencyRebate;
    if (allowsDualAgency) {
      final commissionPercent =
          dualAgencyCommissionPercentage ?? bacPercentage;
      dualAgencyRebate =
          listPrice * commissionPercent * dualAgencyDirectSharePercentage;
    }

    return RebateRange(
      minStandardRebate: minStandardRebate,
      maxStandardRebate: maxStandardRebate,
      minDualAgencyRebate: dualAgencyRebate,
      maxDualAgencyRebate: dualAgencyRebate, // Single number, not a range
      listPrice: listPrice,
      bacPercentage: bacPercentage,
      allowsDualAgency: allowsDualAgency,
      dualAgencyCommissionPercentage: dualAgencyCommissionPercentage,
    );
  }

  /// Calculates rebate based on specific BAC percentage
  static double calculateSpecificRebate({
    required double listPrice,
    required double bacPercentage,
  }) {
    return listPrice * bacPercentage * standardRebatePercentage;
  }

  /// Formats currency for display
  static String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  /// Gets rebate percentage range text
  static String getRebatePercentageRangeText() {
    return '${(standardRebatePercentage * 100).toStringAsFixed(0)}%';
  }
}

class RebateRange {
  final double minStandardRebate;
  final double maxStandardRebate;
  final double? minDualAgencyRebate;
  final double? maxDualAgencyRebate;
  final double listPrice;
  final double bacPercentage;
  final bool allowsDualAgency;
  final double? dualAgencyCommissionPercentage;

  RebateRange({
    required this.minStandardRebate,
    required this.maxStandardRebate,
    this.minDualAgencyRebate,
    this.maxDualAgencyRebate,
    required this.listPrice,
    required this.bacPercentage,
    required this.allowsDualAgency,
    this.dualAgencyCommissionPercentage,
  });

  String get formattedMinStandardRebate =>
      RebateCalculatorService.formatCurrency(minStandardRebate);
  String get formattedMaxStandardRebate =>
      RebateCalculatorService.formatCurrency(maxStandardRebate);
  String get formattedMinDualAgencyRebate => minDualAgencyRebate != null
      ? RebateCalculatorService.formatCurrency(minDualAgencyRebate!)
      : '';
  String get formattedMaxDualAgencyRebate => maxDualAgencyRebate != null
      ? RebateCalculatorService.formatCurrency(maxDualAgencyRebate!)
      : '';

  String get standardRebateRangeText {
    // If min and max are the same (based on actual BAC), show single amount
    if (minStandardRebate == maxStandardRebate) {
      return formattedMinStandardRebate;
    }
    return '$formattedMinStandardRebate - $formattedMaxStandardRebate';
  }

  String get dualAgencyRebateRangeText {
    if (minDualAgencyRebate == null) {
      return '';
    }
    return formattedMinDualAgencyRebate;
  }

  bool get hasDualAgencyOption =>
      allowsDualAgency && minDualAgencyRebate != null;
}

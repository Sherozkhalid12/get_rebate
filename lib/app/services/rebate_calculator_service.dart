class RebateCalculatorService {
  // Buyer keeps 30% of BAC when working with an agent from this site
  static const double standardRebatePercentage = 0.30;

  // Buyer keeps 40% of the total commission when going directly to listing agent
  static const double dualAgencyDirectSharePercentage = 0.40;

  /// Variance for compliance: rebate range ±15% to avoid displaying exact amounts.
  /// Aligns with NAR guidance to not publicly display exact BAC/commission.
  static const double _rebateRangeVariance = 0.15;

  /// Calculates potential rebate range based on BAC percentage.
  /// Returns a range (not exact amount) for NAR compliance—exact BAC is not displayed.
  static RebateRange calculateRebateRange({
    required double listPrice,
    required double bacPercentage,
    required bool allowsDualAgency,
    double? dualAgencyCommissionPercentage,
  }) {
    // Base rebate using the BAC entered for the listing.
    final baseStandardRebate =
        listPrice * bacPercentage * standardRebatePercentage;
    // Range: ±15% for compliance—no exact amount publicly displayed.
    final minStandardRebate = baseStandardRebate * (1 - _rebateRangeVariance);
    final maxStandardRebate = baseStandardRebate * (1 + _rebateRangeVariance);

    // Dual agency rebate range
    double? minDualAgencyRebate;
    double? maxDualAgencyRebate;
    if (allowsDualAgency) {
      final commissionPercent =
          dualAgencyCommissionPercentage ?? bacPercentage;
      final baseDualAgencyRebate =
          listPrice * commissionPercent * dualAgencyDirectSharePercentage;
      minDualAgencyRebate = baseDualAgencyRebate * (1 - _rebateRangeVariance);
      maxDualAgencyRebate = baseDualAgencyRebate * (1 + _rebateRangeVariance);
    }

    return RebateRange(
      minStandardRebate: minStandardRebate,
      maxStandardRebate: maxStandardRebate,
      minDualAgencyRebate: minDualAgencyRebate,
      maxDualAgencyRebate: maxDualAgencyRebate,
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
    if (minDualAgencyRebate == null || maxDualAgencyRebate == null) {
      return '';
    }
    return '$formattedMinDualAgencyRebate - $formattedMaxDualAgencyRebate';
  }

  bool get hasDualAgencyOption =>
      allowsDualAgency && minDualAgencyRebate != null;
}

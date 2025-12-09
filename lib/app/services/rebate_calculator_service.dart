class RebateCalculatorService {
  // Standard rebate percentage range (30% of BAC)
  static const double standardRebatePercentage = 0.30;

  // Dual agency rebate percentage (30% of full BAC)
  static const double dualAgencyRebatePercentage = 0.30;

  // Minimum BAC percentage for standard rebate range
  static const double minStandardRebatePercentage = 0.025; // 2.5%

  // Maximum BAC percentage for standard rebate range
  static const double maxStandardRebatePercentage = 0.030; // 3.0%

  // Dual agency rebate percentage range
  static const double minDualAgencyRebatePercentage = 0.40; // 40% minimum
  static const double maxDualAgencyRebatePercentage = 0.50; // 50% maximum

  // Dual agency BAC percentage
  static const double dualAgencyBacPercentage = 0.04; // 4.0%

  /// Calculates potential rebate range based on BAC percentage
  static RebateRange calculateRebateRange({
    required double listPrice,
    required double bacPercentage,
    required bool allowsDualAgency,
    double? dualAgencyCommissionPercentage,
  }) {
    // Calculate standard rebate range based on BAC range 2.5% to 3.0%
    // Minimum: list price * 2.5% * 30%
    final minStandardRebate = listPrice * 0.025 * standardRebatePercentage;

    // Maximum: list price * 3.0% * 30%
    final maxStandardRebate = listPrice * 0.030 * standardRebatePercentage;

    // Calculate dual agency rebate - single number
    // list price * 4% * 40%
    double? dualAgencyRebate;
    if (allowsDualAgency) {
      dualAgencyRebate =
          listPrice * dualAgencyBacPercentage * minDualAgencyRebatePercentage;
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
    return '${(minStandardRebatePercentage * 100).toStringAsFixed(1)}% - ${(maxStandardRebatePercentage * 100).toStringAsFixed(1)}%';
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
    // Show single number for dual agency with "or more"
    return '$formattedMinDualAgencyRebate or more';
  }

  bool get hasDualAgencyOption =>
      allowsDualAgency && minDualAgencyRebate != null;
}

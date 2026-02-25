class RebateCalculatorService {
  // Buyer rebate percentages by tier
  static const double _tier1RebatePercentage = 0.40; // 4.0% or more
  static const double _tier2RebatePercentage = 0.35; // 3.01% - 3.99%
  static const double _tier3RebatePercentage = 0.30; // 2.5% - 3.0%
  static const double _tier4RebatePercentage = 0.25; // 2.0% - 2.49%
  static const double _tier5RebatePercentage = 0.20; // 1.5% - 1.99%
  static const double _tier6RebatePercentage = 0.10; // .25% - 1.49%
  static const double _tier7RebatePercentage = 0.00; // 0% - .24%

  // Dual agency listing display requirement:
  // always show 4.0% x 40% as the minimum with "or more".
  static const double _dualAgencyMinimumCommissionPercent = 0.04;
  static const double dualAgencyDirectSharePercentage = 0.40;

  /// Calculates potential rebate range based on BAC percentage.
  /// Uses tier commission ranges to match the rebate calculator behavior.
  static RebateRange calculateRebateRange({
    required double listPrice,
    required double bacPercentage,
    required bool allowsDualAgency,
    double? dualAgencyCommissionPercentage,
  }) {
    final tier = _getTierRange(
      commissionPercent: bacPercentage,
      listPrice: listPrice,
    );

    final minStandardRebate =
        listPrice * tier.minCommissionPercent * tier.rebatePercentage;
    final maxStandardRebate = tier.maxCommissionPercent != null
        ? listPrice * tier.maxCommissionPercent! * tier.rebatePercentage
        : null;

    double? minDualAgencyRebate;
    if (allowsDualAgency) {
      minDualAgencyRebate =
          listPrice *
          _dualAgencyMinimumCommissionPercent *
          dualAgencyDirectSharePercentage;
    }

    return RebateRange(
      minStandardRebate: minStandardRebate,
      maxStandardRebate: maxStandardRebate,
      minDualAgencyRebate: minDualAgencyRebate,
      maxDualAgencyRebate: null,
      listPrice: listPrice,
      bacPercentage: bacPercentage,
      allowsDualAgency: allowsDualAgency,
      dualAgencyCommissionPercentage: dualAgencyCommissionPercentage,
    );
  }

  static _TierRange _getTierRange({
    required double commissionPercent,
    required double listPrice,
  }) {
    final isHighValue = listPrice >= 700000;

    if (commissionPercent >= 0.04) {
      return const _TierRange(
        minCommissionPercent: 0.04,
        maxCommissionPercent: null,
        rebatePercentage: _tier1RebatePercentage,
      );
    }
    if (commissionPercent >= 0.0301) {
      return const _TierRange(
        minCommissionPercent: 0.0301,
        maxCommissionPercent: 0.0399,
        rebatePercentage: _tier2RebatePercentage,
      );
    }
    if (commissionPercent >= 0.025) {
      return const _TierRange(
        minCommissionPercent: 0.025,
        maxCommissionPercent: 0.03,
        rebatePercentage: _tier3RebatePercentage,
      );
    }
    if (commissionPercent >= 0.02) {
      return const _TierRange(
        minCommissionPercent: 0.02,
        maxCommissionPercent: 0.0249,
        rebatePercentage: _tier4RebatePercentage,
      );
    }

    if (isHighValue) {
      if (commissionPercent < 0.0025) {
        return const _TierRange(
          minCommissionPercent: 0.0,
          maxCommissionPercent: 0.0024,
          rebatePercentage: _tier7RebatePercentage,
        );
      }

      return const _TierRange(
        minCommissionPercent: 0.02,
        maxCommissionPercent: 0.0249,
        rebatePercentage: _tier4RebatePercentage,
      );
    }

    if (commissionPercent >= 0.015) {
      return const _TierRange(
        minCommissionPercent: 0.015,
        maxCommissionPercent: 0.0199,
        rebatePercentage: _tier5RebatePercentage,
      );
    }
    if (commissionPercent >= 0.0025) {
      return const _TierRange(
        minCommissionPercent: 0.0025,
        maxCommissionPercent: 0.0149,
        rebatePercentage: _tier6RebatePercentage,
      );
    }

    return const _TierRange(
      minCommissionPercent: 0.0,
      maxCommissionPercent: 0.0024,
      rebatePercentage: _tier7RebatePercentage,
    );
  }

  /// Calculates rebate based on specific BAC percentage
  static double calculateSpecificRebate({
    required double listPrice,
    required double bacPercentage,
  }) {
    final tier = _getTierRange(
      commissionPercent: bacPercentage,
      listPrice: listPrice,
    );
    return listPrice * bacPercentage * tier.rebatePercentage;
  }

  /// Formats currency for display
  static String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  /// Gets rebate percentage range text
  static String getRebatePercentageRangeText() {
    return '0% - 40%';
  }
}

class _TierRange {
  final double minCommissionPercent;
  final double? maxCommissionPercent;
  final double rebatePercentage;

  const _TierRange({
    required this.minCommissionPercent,
    required this.maxCommissionPercent,
    required this.rebatePercentage,
  });
}

class RebateRange {
  final double minStandardRebate;
  final double? maxStandardRebate;
  final double? minDualAgencyRebate;
  final double? maxDualAgencyRebate;
  final double listPrice;
  final double bacPercentage;
  final bool allowsDualAgency;
  final double? dualAgencyCommissionPercentage;

  RebateRange({
    required this.minStandardRebate,
    this.maxStandardRebate,
    this.minDualAgencyRebate,
    this.maxDualAgencyRebate,
    required this.listPrice,
    required this.bacPercentage,
    required this.allowsDualAgency,
    this.dualAgencyCommissionPercentage,
  });

  String get formattedMinStandardRebate =>
      RebateCalculatorService.formatCurrency(minStandardRebate);
  String get formattedMaxStandardRebate => maxStandardRebate != null
      ? RebateCalculatorService.formatCurrency(maxStandardRebate!)
      : '';
  String get formattedMinDualAgencyRebate => minDualAgencyRebate != null
      ? RebateCalculatorService.formatCurrency(minDualAgencyRebate!)
      : '';
  String get formattedMaxDualAgencyRebate => maxDualAgencyRebate != null
      ? RebateCalculatorService.formatCurrency(maxDualAgencyRebate!)
      : '';

  String get standardRebateRangeText {
    if (maxStandardRebate == null) {
      return '$formattedMinStandardRebate or more';
    }
    if (minStandardRebate == maxStandardRebate) {
      return formattedMinStandardRebate;
    }
    return '$formattedMinStandardRebate - $formattedMaxStandardRebate';
  }

  String get dualAgencyRebateRangeText {
    if (minDualAgencyRebate == null) {
      return '';
    }
    return '$formattedMinDualAgencyRebate or more';
  }

  bool get hasDualAgencyOption =>
      allowsDualAgency && minDualAgencyRebate != null;
}

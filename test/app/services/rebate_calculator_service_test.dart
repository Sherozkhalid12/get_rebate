import 'package:flutter_test/flutter_test.dart';
import 'package:getrebate/app/services/rebate_calculator_service.dart';

void main() {
  group('RebateCalculatorService', () {
    test(r'uses tier range for standard rebate on $1,000,000 at 2.5%', () {
      final rebateRange = RebateCalculatorService.calculateRebateRange(
        listPrice: 1000000,
        bacPercentage: 0.025,
        allowsDualAgency: true,
        dualAgencyCommissionPercentage: 0.04,
      );

      expect(rebateRange.standardRebateRangeText, r'$7,500 - $9,000');
    });

    test('uses 4.0% floor for dual agency with "or more"', () {
      final rebateRange = RebateCalculatorService.calculateRebateRange(
        listPrice: 1000000,
        bacPercentage: 0.025,
        allowsDualAgency: true,
        dualAgencyCommissionPercentage: 0.05,
      );

      expect(rebateRange.dualAgencyRebateRangeText, r'$16,000 or more');
    });

    test(r'applies $700k+ minimum tier 4 for sub-2% BAC', () {
      final rebateRange = RebateCalculatorService.calculateRebateRange(
        listPrice: 800000,
        bacPercentage: 0.018,
        allowsDualAgency: false,
      );

      expect(rebateRange.standardRebateRangeText, r'$4,000 - $4,980');
    });
  });
}

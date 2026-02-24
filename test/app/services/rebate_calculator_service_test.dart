import 'package:flutter_test/flutter_test.dart';
import 'package:getrebate/app/services/rebate_calculator_service.dart';

void main() {
  group('RebateCalculatorService', () {
    test('dual agency text shows single amount with "or more"', () {
      final rebateRange = RebateCalculatorService.calculateRebateRange(
        listPrice: 100000,
        bacPercentage: 0.02,
        allowsDualAgency: true,
        dualAgencyCommissionPercentage: 0.04,
      );

      expect(rebateRange.standardRebateRangeText, r'$510 - $690');
      expect(rebateRange.dualAgencyRebateRangeText, r'$1,360 or more');
    });
  });
}

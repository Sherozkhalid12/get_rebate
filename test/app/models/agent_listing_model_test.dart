import 'package:flutter_test/flutter_test.dart';
import 'package:getrebate/app/models/agent_listing_model.dart';

void main() {
  group('AgentListingModel.fromApiJson', () {
    test(
      'normalizes scaled commission values and reads listingSideCommission',
      () {
        final listing = AgentListingModel.fromApiJson({
          '_id': 'listing-1',
          'id': 'agent-1',
          'propertyTitle': 'Test Home',
          'description': 'Test description',
          'price': '85000',
          'streetAddress': '123 Main',
          'city': 'Test City',
          'state': 'TX',
          'zipCode': '75001',
          'propertyPhotos': const [],
          'BACPercentage': '20',
          'dualAgencyAllowed': true,
          'listingSideCommission': '{"totalCommission":50}',
          'status': 'active',
          'active': true,
        });

        expect(listing.bacPercent, 2.0);
        expect(listing.dualAgencyCommissionPercent, 5.0);
      },
    );

    test('normalizes fractional commission values', () {
      final listing = AgentListingModel.fromApiJson({
        '_id': 'listing-2',
        'id': 'agent-2',
        'propertyTitle': 'Test Home 2',
        'description': 'Test description 2',
        'price': '500000',
        'streetAddress': '456 Main',
        'city': 'Test City',
        'state': 'CA',
        'zipCode': '90001',
        'propertyPhotos': const [],
        'BACPercentage': 0.025,
        'dualAgencyAllowed': true,
        'listingSideCommission': {'totalCommission': 0.05},
        'status': 'active',
        'active': true,
      });

      expect(listing.bacPercent, 2.5);
      expect(listing.dualAgencyCommissionPercent, 5.0);
    });
  });
}

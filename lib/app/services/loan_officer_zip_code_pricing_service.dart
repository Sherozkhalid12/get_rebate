// Service for calculating subscription prices based on zip code population tiers for Loan Officers

import 'package:getrebate/app/models/loan_officer_zip_code_model.dart';
import 'package:getrebate/app/models/pricing_tier_model.dart';

class LoanOfficerZipCodePricingService {
  // Cache the pricing tiers
  static List<PricingTier>? _cachedTiers;
  
  /// Get the pricing tiers for loan officers (cached for performance)
  static List<PricingTier> getPricingTiers() {
    _cachedTiers ??= LoanOfficerPricingTierConfig.getLoanOfficerTiers();
    return _cachedTiers!;
  }

  /// Update pricing tiers (useful for admin configuration)
  static void updatePricingTiers(List<PricingTier> tiers) {
    _cachedTiers = tiers;
  }

  /// Calculate monthly price for a single zip code based on its population
  static double calculatePriceForZipCode(LoanOfficerZipCodeModel zipCode) {
    return calculatePriceForPopulation(zipCode.population);
  }

  /// Calculate monthly price for a population value
  static double calculatePriceForPopulation(int population) {
    final tiers = getPricingTiers();
    return LoanOfficerPricingTierConfig.getPriceForPopulation(population, tiers);
  }

  /// Get the pricing tier for a zip code
  static PricingTier? getTierForZipCode(LoanOfficerZipCodeModel zipCode) {
    return getTierForPopulation(zipCode.population);
  }

  /// Get the pricing tier for a population value
  static PricingTier? getTierForPopulation(int population) {
    final tiers = getPricingTiers();
    return LoanOfficerPricingTierConfig.getTierForPopulation(population, tiers);
  }

  /// Calculate total monthly subscription price for multiple zip codes
  /// This sums up the prices of all claimed zip codes
  static double calculateTotalMonthlyPrice(List<LoanOfficerZipCodeModel> claimedZipCodes) {
    if (claimedZipCodes.isEmpty) return 0.0;
    
    double total = 0.0;
    for (final zipCode in claimedZipCodes) {
      total += calculatePriceForZipCode(zipCode);
    }
    return total;
  }

  /// Get tier information for a zip code (for display purposes)
  static Map<String, dynamic> getTierInfo(LoanOfficerZipCodeModel zipCode) {
    final tier = getTierForZipCode(zipCode);
    if (tier == null) {
      return {
        'tierName': 'Unknown',
        'price': 0.0,
        'populationRange': 'N/A',
        'description': 'Unknown tier',
      };
    }

    return {
      'tierName': tier.tierName,
      'price': tier.monthlyPrice,
      'populationRange': tier.populationRange,
      'description': tier.description,
    };
  }

  /// Validate that a population value has a valid tier
  static bool isValidPopulation(int population) {
    final tier = getTierForPopulation(population);
    return tier != null;
  }

  /// Get all available tiers (for admin/display purposes)
  static List<PricingTier> getAllTiers() {
    return getPricingTiers();
  }
}

/// Loan Officer pricing tier configuration based on the provided image
/// Tier 1: 100-1,000 → $3.99
/// Tier 2: 1,001-3,000 → $5.99
/// Tier 3: 3,001-7,500 → $7.99
/// Tier 4: 7,501-15,000 → $9.99
/// Tier 5: 15,001-30,000 → $12.99
/// Tier 6: 30,001-50,000 → $16.99
/// Tier 7: 50,001-75,000 → $19.99
/// Tier 8: 75,001-100,000 → $22.99
/// Tier 9: 100,001+ → $26.99
class LoanOfficerPricingTierConfig {
  static List<PricingTier> getLoanOfficerTiers() {
    return [
      // Tier 1: 100-1,000
      PricingTier(
        tierName: 'Tier 1',
        minPopulation: 100,
        maxPopulation: 1001,
        monthlyPrice: 3.99,
        description: '100 - 1,000',
      ),
      // Tier 2: 1,001-3,000
      PricingTier(
        tierName: 'Tier 2',
        minPopulation: 1001,
        maxPopulation: 3001,
        monthlyPrice: 5.99,
        description: '1,001 - 3,000',
      ),
      // Tier 3: 3,001-7,500
      PricingTier(
        tierName: 'Tier 3',
        minPopulation: 3001,
        maxPopulation: 7501,
        monthlyPrice: 7.99,
        description: '3,001 - 7,500',
      ),
      // Tier 4: 7,501-15,000
      PricingTier(
        tierName: 'Tier 4',
        minPopulation: 7501,
        maxPopulation: 15001,
        monthlyPrice: 9.99,
        description: '7,501 - 15,000',
      ),
      // Tier 5: 15,001-30,000
      PricingTier(
        tierName: 'Tier 5',
        minPopulation: 15001,
        maxPopulation: 30001,
        monthlyPrice: 12.99,
        description: '15,001 - 30,000',
      ),
      // Tier 6: 30,001-50,000
      PricingTier(
        tierName: 'Tier 6',
        minPopulation: 30001,
        maxPopulation: 50001,
        monthlyPrice: 16.99,
        description: '30,001 - 50,000',
      ),
      // Tier 7: 50,001-75,000
      PricingTier(
        tierName: 'Tier 7',
        minPopulation: 50001,
        maxPopulation: 75001,
        monthlyPrice: 19.99,
        description: '50,001 - 75,000',
      ),
      // Tier 8: 75,001-100,000
      PricingTier(
        tierName: 'Tier 8',
        minPopulation: 75001,
        maxPopulation: 100001,
        monthlyPrice: 22.99,
        description: '75,001 - 100,000',
      ),
      // Tier 9: 100,001+
      PricingTier(
        tierName: 'Tier 9',
        minPopulation: 100001,
        maxPopulation: null, // No upper limit
        monthlyPrice: 26.99,
        description: '100,001+',
      ),
    ];
  }

  /// Get tier for a specific population
  static PricingTier? getTierForPopulation(int population, List<PricingTier> tiers) {
    for (final tier in tiers) {
      if (tier.matches(population)) {
        return tier;
      }
    }
    return null;
  }

  /// Get price for a specific population
  static double getPriceForPopulation(int population, List<PricingTier> tiers) {
    final tier = getTierForPopulation(population, tiers);
    return tier?.monthlyPrice ?? 0.0;
  }
}

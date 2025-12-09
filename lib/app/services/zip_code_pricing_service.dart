// Service for calculating subscription prices based on zip code population tiers

import 'package:getrebate/app/models/pricing_tier_model.dart';
import 'package:getrebate/app/models/zip_code_model.dart';

class ZipCodePricingService {
  // Cache the pricing tiers
  static List<PricingTier>? _cachedTiers;
  
  /// Get the pricing tiers (cached for performance)
  static List<PricingTier> getPricingTiers() {
    _cachedTiers ??= PricingTierConfig.getDefaultTiers();
    return _cachedTiers!;
  }

  /// Update pricing tiers (useful for admin configuration)
  static void updatePricingTiers(List<PricingTier> tiers) {
    _cachedTiers = tiers;
  }

  /// Calculate monthly price for a single zip code based on its population
  static double calculatePriceForZipCode(ZipCodeModel zipCode) {
    return calculatePriceForPopulation(zipCode.population);
  }

  /// Calculate monthly price for a population value
  static double calculatePriceForPopulation(int population) {
    final tiers = getPricingTiers();
    return PricingTierConfig.getPriceForPopulation(population, tiers);
  }

  /// Get the pricing tier for a zip code
  static PricingTier? getTierForZipCode(ZipCodeModel zipCode) {
    return getTierForPopulation(zipCode.population);
  }

  /// Get the pricing tier for a population value
  static PricingTier? getTierForPopulation(int population) {
    final tiers = getPricingTiers();
    return PricingTierConfig.getTierForPopulation(population, tiers);
  }

  /// Calculate total monthly subscription price for multiple zip codes
  /// This sums up the prices of all claimed zip codes
  static double calculateTotalMonthlyPrice(List<ZipCodeModel> claimedZipCodes) {
    if (claimedZipCodes.isEmpty) return 0.0;
    
    double total = 0.0;
    for (final zipCode in claimedZipCodes) {
      total += calculatePriceForZipCode(zipCode);
    }
    return total;
  }

  /// Get tier information for a zip code (for display purposes)
  static Map<String, dynamic> getTierInfo(ZipCodeModel zipCode) {
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


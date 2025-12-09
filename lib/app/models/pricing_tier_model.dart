// Pricing tier model for zip code population-based pricing

class PricingTier {
  final String tierName;
  final int minPopulation; // Inclusive
  final int? maxPopulation; // Exclusive, null means no upper limit
  final double monthlyPrice;
  final String description;

  PricingTier({
    required this.tierName,
    required this.minPopulation,
    this.maxPopulation,
    required this.monthlyPrice,
    required this.description,
  });

  /// Checks if a population falls within this tier
  bool matches(int population) {
    if (population < minPopulation) return false;
    if (maxPopulation != null && population >= maxPopulation!) return false;
    return true;
  }

  /// Gets the display range for this tier
  String get populationRange {
    if (maxPopulation == null) {
      return '$minPopulation+';
    }
    return '$minPopulation - ${maxPopulation! - 1}';
  }

  factory PricingTier.fromJson(Map<String, dynamic> json) {
    return PricingTier(
      tierName: json['tierName'] ?? '',
      minPopulation: json['minPopulation'] ?? 0,
      maxPopulation: json['maxPopulation'],
      monthlyPrice: (json['monthlyPrice'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tierName': tierName,
      'minPopulation': minPopulation,
      'maxPopulation': maxPopulation,
      'monthlyPrice': monthlyPrice,
      'description': description,
    };
  }
}

/// Default pricing tier configuration
/// This can be customized later - structure supports ~10 tiers
class PricingTierConfig {
  static List<PricingTier> getDefaultTiers() {
    return [
      // Tier 1: Very small populations (0-999)
      PricingTier(
        tierName: 'Tier 1',
        minPopulation: 0,
        maxPopulation: 1000,
        monthlyPrice: 9.99,
        description: 'Very Small (0-999)',
      ),
      // Tier 2: Small populations (1,000-2,499)
      PricingTier(
        tierName: 'Tier 2',
        minPopulation: 1000,
        maxPopulation: 2500,
        monthlyPrice: 12.99,
        description: 'Small (1,000-2,499)',
      ),
      // Tier 3: Small-medium populations (2,500-4,999)
      PricingTier(
        tierName: 'Tier 3',
        minPopulation: 2500,
        maxPopulation: 5000,
        monthlyPrice: 15.99,
        description: 'Small-Medium (2,500-4,999)',
      ),
      // Tier 4: Medium populations (5,000-9,999)
      PricingTier(
        tierName: 'Tier 4',
        minPopulation: 5000,
        maxPopulation: 10000,
        monthlyPrice: 17.99,
        description: 'Medium (5,000-9,999)',
      ),
      // Tier 5: Medium-large populations (10,000-19,999)
      PricingTier(
        tierName: 'Tier 5',
        minPopulation: 10000,
        maxPopulation: 20000,
        monthlyPrice: 22.99,
        description: 'Medium-Large (10,000-19,999)',
      ),
      // Tier 6: Large populations (20,000-29,999)
      PricingTier(
        tierName: 'Tier 6',
        minPopulation: 20000,
        maxPopulation: 30000,
        monthlyPrice: 27.99,
        description: 'Large (20,000-29,999)',
      ),
      // Tier 7: Very large populations (30,000-49,999)
      PricingTier(
        tierName: 'Tier 7',
        minPopulation: 30000,
        maxPopulation: 50000,
        monthlyPrice: 34.99,
        description: 'Very Large (30,000-49,999)',
      ),
      // Tier 8: Extra large populations (50,000-74,999)
      PricingTier(
        tierName: 'Tier 8',
        minPopulation: 50000,
        maxPopulation: 75000,
        monthlyPrice: 44.99,
        description: 'Extra Large (50,000-74,999)',
      ),
      // Tier 9: Super large populations (75,000-99,999)
      PricingTier(
        tierName: 'Tier 9',
        minPopulation: 75000,
        maxPopulation: 100000,
        monthlyPrice: 59.99,
        description: 'Super Large (75,000-99,999)',
      ),
      // Tier 10: Maximum populations (100,000+)
      PricingTier(
        tierName: 'Tier 10',
        minPopulation: 100000,
        maxPopulation: null, // No upper limit
        monthlyPrice: 79.99,
        description: 'Maximum (100,000+)',
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


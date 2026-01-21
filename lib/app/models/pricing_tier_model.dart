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
      PricingTier(
        tierName: 'Tier 1',
        minPopulation: 0,
        maxPopulation: 1001,
        monthlyPrice: 7.99,
        description: 'Agent Tier 1 (Up to 1,000)',
      ),
      PricingTier(
        tierName: 'Tier 2',
        minPopulation: 1001,
        maxPopulation: 3001,
        monthlyPrice: 9.99,
        description: 'Agent Tier 2 (1,001-3,000)',
      ),
      PricingTier(
        tierName: 'Tier 3',
        minPopulation: 3001,
        maxPopulation: 7501,
        monthlyPrice: 12.99,
        description: 'Agent Tier 3 (3,001-7,500)',
      ),
      PricingTier(
        tierName: 'Tier 4',
        minPopulation: 7501,
        maxPopulation: 15001,
        monthlyPrice: 17.99,
        description: 'Agent Tier 4 (7,501-15,000)',
      ),
      PricingTier(
        tierName: 'Tier 5',
        minPopulation: 15001,
        maxPopulation: 30001,
        monthlyPrice: 24.99,
        description: 'Agent Tier 5 (15,001-30,000)',
      ),
      PricingTier(
        tierName: 'Tier 6',
        minPopulation: 30001,
        maxPopulation: 50001,
        monthlyPrice: 32.99,
        description: 'Agent Tier 6 (30,001-50,000)',
      ),
      PricingTier(
        tierName: 'Tier 7',
        minPopulation: 50001,
        maxPopulation: 75001,
        monthlyPrice: 39.99,
        description: 'Agent Tier 7 (50,001-75,000)',
      ),
      PricingTier(
        tierName: 'Tier 8',
        minPopulation: 75001,
        maxPopulation: 100001,
        monthlyPrice: 44.99,
        description: 'Agent Tier 8 (75,001-100,000)',
      ),
      PricingTier(
        tierName: 'Tier 9',
        minPopulation: 100001,
        maxPopulation: null,
        monthlyPrice: 49.99,
        description: 'Agent Tier 9 (100,001+)',
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


/// Constants for Agent Areas of Expertise
/// Used for agent sign-up and profile editing
class AgentExpertise {
  // Core expertise areas
  static const String residentialRealEstate = 'Residential Real Estate';
  static const String newConstructionBuilding = 'New Construction & Building';
  static const String firstTimeHomebuyers = 'First-Time Homebuyers';
  static const String investmentProperties = 'Investment Properties';
  static const String relocationServices = 'Relocation Services';
  static const String vacationSecondHomes = 'Vacation & Second Homes';
  static const String landLots = 'Land & Lots';
  static const String shortSalesForeclosures = 'Short Sales & Foreclosures';
  static const String senior55Market = 'Senior / 55+ Market';
  static const String greenEcoFriendlyHomes = 'Green / Eco-Friendly Homes';
  static const String luxuryHighEndMarket = 'Luxury & High-End Market';
  static const String commercialRealEstate = 'Commercial Real Estate';

  /// Get all available expertise areas
  static List<String> getAll() {
    return [
      residentialRealEstate,
      newConstructionBuilding,
      firstTimeHomebuyers,
      investmentProperties,
      relocationServices,
      vacationSecondHomes,
      landLots,
      shortSalesForeclosures,
      senior55Market,
      greenEcoFriendlyHomes,
      luxuryHighEndMarket,
      commercialRealEstate,
    ];
  }

  /// Get descriptions for each expertise area
  static Map<String, String> getDescriptions() {
    return {
      residentialRealEstate:
          'Expertise in buying and selling residential properties including single-family homes, condos, and townhouses.',
      newConstructionBuilding:
          'Specialized knowledge in new construction homes, builder relationships, and construction-to-permanent financing.',
      firstTimeHomebuyers:
          'Dedicated to helping first-time buyers navigate the home buying process, including first-time buyer programs and grants.',
      investmentProperties:
          'Experience with investment real estate, rental properties, and helping investors build portfolios.',
      relocationServices:
          'Assistance with corporate relocations, military moves, and helping clients relocate to new areas.',
      vacationSecondHomes:
          'Specialized in vacation properties, second homes, and seasonal rental properties.',
      landLots:
          'Expertise in land sales, lot purchases, and development opportunities.',
      shortSalesForeclosures:
          'Knowledgeable in short sales, foreclosures, and distressed property transactions.',
      senior55Market:
          'Specialized in 55+ communities, senior living options, and age-restricted properties.',
      greenEcoFriendlyHomes:
          'Expertise in eco-friendly homes, energy-efficient properties, and sustainable building practices.',
      luxuryHighEndMarket:
          'Specialized in luxury properties, high-end real estate, and premium market segments.',
      commercialRealEstate:
          'Licensed in commercial real estate including office buildings, retail spaces, and commercial properties.',
    };
  }

  /// Get description for a specific expertise area
  static String? getDescription(String expertise) {
    return getDescriptions()[expertise];
  }
}





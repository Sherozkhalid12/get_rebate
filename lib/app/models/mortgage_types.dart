/// Mortgage Types Constants
/// These represent the various mortgage loan types that loan officers can specialize in

class MortgageTypes {
  // Main Types of Residential Mortgages
  static const String conventionalConforming = 'Conventional Conforming Loans';
  static const String conventionalNonConforming =
      'Conventional Non-Conforming / Jumbo Loans';
  static const String conventionalPortfolio = 'Conventional Portfolio Loans';
  static const String fhaLoans = 'FHA Loans (Federal Housing Administration)';
  static const String vaLoans = 'VA Loans (Department of Veterans Affairs)';
  static const String usdaLoans = 'USDA Loans (U.S. Department of Agriculture)';
  static const String fthbPrograms = 'First-Time Homebuyer Programs';
  static const String renovationLoans =
      'Renovation Loans (e.g., FHA 203(k), Fannie Mae HomeStyle)';
  static const String constructionToPermanent =
      'Construction-to-Permanent Loan';
  static const String interestOnly = 'Interest-Only Loan';
  static const String nonQM = 'Non-QM (Non-Qualified Mortgage)';
  static const String fixedRate = 'Fixed-Rate Mortgages';
  static const String adjustableRate = 'Adjustable-Rate Mortgage (ARM)';
  static const String hybridLoans = 'Hybrid Loans';
  static const String other = 'Other';

  // Get all available mortgage types
  static List<String> getAll() {
    return [
      conventionalConforming,
      conventionalNonConforming,
      conventionalPortfolio,
      fhaLoans,
      vaLoans,
      usdaLoans,
      fthbPrograms,
      renovationLoans,
      constructionToPermanent,
      interestOnly,
      nonQM,
      fixedRate,
      adjustableRate,
      hybridLoans,
      other,
    ];
  }

  // Get descriptions for each mortgage type
  static Map<String, String> getDescriptions() {
    return {
      conventionalConforming:
          'Meets Fannie Mae and Freddie Mac guidelines. Standard loan limit set annually (e.g., \$766,550 for most areas in 2025).',
      conventionalNonConforming:
          'Exceeds the conforming loan limit. Typically used for higher-priced homes requiring larger loan amounts.',
      conventionalPortfolio:
          'Held by the lender instead of being sold to investors, often with more flexible terms and underwriting guidelines.',
      fhaLoans:
          'Government-backed loans designed for low- to moderate-income buyers with lower down payments and more lenient credit requirements.',
      vaLoans:
          'Available to eligible veterans, active-duty service members, and some surviving spouses. No down payment and no mortgage insurance required.',
      usdaLoans:
          'For buyers in eligible rural and suburban areas. Offers 0% down payment and favorable terms for qualifying properties.',
      fthbPrograms:
          'State, city, or local housing agency programs that may include grants or down payment assistance for first-time buyers.',
      renovationLoans:
          'Combines purchase and renovation costs into one mortgage. Perfect for fixer-uppers and home improvements.',
      constructionToPermanent:
          'Finances both the building and the permanent mortgage once construction is complete. Streamlined financing for new construction.',
      interestOnly:
          'Payments cover only the interest for an initial period, then switch to principal + interest.',
      nonQM:
          'For borrowers with unique income situations (e.g., self-employed) who don\'t meet standard underwriting guidelines.',
      fixedRate:
          'Interest rate stays the same for the life of the loan (typically 15-year, 20-year, or 30-year terms).',
      adjustableRate:
          'Rate is fixed for an initial period (e.g., 5/1 ARM = fixed 5 years, adjusts annually thereafter).',
      hybridLoans:
          'Combines fixed and adjustable features (e.g., fixed for 7 years, then adjusts).',
      other:
          'Custom or specialized loan products not covered in the standard categories.',
    };
  }

  // Get description for a specific mortgage type
  static String? getDescription(String mortgageType) {
    return getDescriptions()[mortgageType];
  }

  // Helper to check if a type is a specialty product
  static bool isSpecialtyProduct(String type) {
    return [
      interestOnly,
      nonQM,
      renovationLoans,
      constructionToPermanent,
    ].contains(type);
  }

  // Helper to check if a type is an area of expertise
  static bool isAreaOfExpertise(String type) {
    return [vaLoans, usdaLoans, fthbPrograms].contains(type);
  }
}

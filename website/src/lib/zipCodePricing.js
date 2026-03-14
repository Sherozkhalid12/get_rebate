/**
 * Population-based pricing tiers for ZIP codes (matches app's PricingTierConfig)
 * Price is monthly subscription per ZIP code
 */
const AGENT_TIERS = [
  { min: 0, max: 1001, price: 7.99 },
  { min: 1001, max: 3001, price: 9.99 },
  { min: 3001, max: 7501, price: 12.99 },
  { min: 7501, max: 15001, price: 17.99 },
  { min: 15001, max: 30001, price: 24.99 },
  { min: 30001, max: 50001, price: 32.99 },
  { min: 50001, max: 75001, price: 39.99 },
  { min: 75001, max: 100001, price: 44.99 },
  { min: 100001, max: null, price: 49.99 },
];

/** Loan Officer tiers (different from Agent) */
const LOAN_OFFICER_TIERS = [
  { min: 100, max: 1001, price: 3.99 },
  { min: 1001, max: 3001, price: 5.99 },
  { min: 3001, max: 7501, price: 7.99 },
  { min: 7501, max: 15001, price: 9.99 },
  { min: 15001, max: 30001, price: 12.99 },
  { min: 30001, max: 50001, price: 16.99 },
  { min: 50001, max: 75001, price: 19.99 },
  { min: 75001, max: 100001, price: 22.99 },
  { min: 100001, max: null, price: 26.99 },
];

function getPriceFromTiers(population, tiers) {
  const pop = Number(population) || 0;
  const tier = tiers.find((t) => {
    if (pop < t.min) return false;
    if (t.max != null && pop >= t.max) return false;
    return true;
  });
  return tier ? tier.price : 0;
}

/**
 * Calculate monthly price for a ZIP code based on population (agent tiers)
 */
export function calculatePriceForPopulation(population) {
  return getPriceFromTiers(population, AGENT_TIERS);
}

/**
 * Calculate monthly price for Loan Officer ZIP codes (loan officer tiers)
 */
export function calculateLoanOfficerPriceForPopulation(population) {
  return getPriceFromTiers(population, LOAN_OFFICER_TIERS);
}

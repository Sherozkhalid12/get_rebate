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

export const MIN_AGENT_PRICE = 7.99;
export const MIN_LOAN_OFFICER_PRICE = 3.99;
export const MAX_CLAIMED_ZIPS = 6;

/** Loan Officer tiers (different from Agent). min 0 so unique/PO Box ZIPs are not $0. */
const LOAN_OFFICER_TIERS = [
  { min: 0, max: 1001, price: 3.99 },
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

/**
 * Monthly price string for display/checkout. Never returns 0.00.
 * Unique / PO Box ZIPs (population 0) use the minimum tier.
 */
export function formatZipMonthlyPrice(population, role = 'agent') {
  const pop = Number(population) || 0;
  const isLo = role === 'loanOfficer' || role === 'loanofficer';
  const calc = isLo ? calculateLoanOfficerPriceForPopulation : calculatePriceForPopulation;
  const floor = isLo ? MIN_LOAN_OFFICER_PRICE : MIN_AGENT_PRICE;
  const n = Number(calc(pop) || floor) || floor;
  return n.toFixed(2);
}

/** Population line on ZIP cards. Unique ZIPs are not residential census areas. */
export function formatZipPopulationMeta(population, distance) {
  const pop = Number(population) || 0;
  const popStr = pop > 0
    ? `Population: ${pop.toLocaleString()}`
    : 'Unique / PO Box ZIP (no residential population on file)';
  if (distance == null || distance === '') return popStr;
  const d = Number(distance);
  if (!Number.isFinite(d) || d === 0) return popStr;
  return `${popStr} • ${distance} mi away`;
}

/** Rebate calculation - mirrors Flutter RebateCalculatorService */

const TIER1 = 0.40; // 4.0%+
const TIER2 = 0.35; // 3.01-3.99%
const TIER3 = 0.30; // 2.5-3.0%
const TIER4 = 0.25; // 2.0-2.49%
const TIER5 = 0.20; // 1.5-1.99%
const TIER6 = 0.10; // 0.25-1.49%
const TIER7 = 0.00; // 0-0.24%
const DUAL_AGENCY_MIN = 0.04;
const DUAL_AGENCY_SHARE = 0.40;

function getTierRange(commissionPercent, listPrice) {
  const isHighValue = listPrice >= 700000;
  if (commissionPercent >= 0.04) return { min: 0.04, max: null, rebate: TIER1 };
  if (commissionPercent >= 0.0301) return { min: 0.0301, max: 0.0399, rebate: TIER2 };
  if (commissionPercent >= 0.025) return { min: 0.025, max: 0.03, rebate: TIER3 };
  if (commissionPercent >= 0.02) return { min: 0.02, max: 0.0249, rebate: TIER4 };
  if (isHighValue) {
    if (commissionPercent < 0.0025) return { min: 0, max: 0.0024, rebate: TIER7 };
    return { min: 0.02, max: 0.0249, rebate: TIER4 };
  }
  if (commissionPercent >= 0.015) return { min: 0.015, max: 0.0199, rebate: TIER5 };
  if (commissionPercent >= 0.0025) return { min: 0.0025, max: 0.0149, rebate: TIER6 };
  return { min: 0, max: 0.0024, rebate: TIER7 };
}

export function formatCurrency(amount) {
  return `$${Math.round(amount).toLocaleString()}`;
}

export function calculateRebateRange({ listPrice, bacPercentage, allowsDualAgency, dualAgencyCommissionPercent }) {
  const bac = Number(bacPercentage) / 100 || 0;
  const price = Number(listPrice) || 0;
  const tier = getTierRange(bac, price);

  const minStandard = price * tier.min * tier.rebate;
  const maxStandard = tier.max != null ? price * tier.max * tier.rebate : null;
  const minDual = allowsDualAgency ? price * DUAL_AGENCY_MIN * DUAL_AGENCY_SHARE : null;

  const standardText = maxStandard == null
    ? `${formatCurrency(minStandard)} or more`
    : minStandard === maxStandard
      ? formatCurrency(minStandard)
      : `${formatCurrency(minStandard)} - ${formatCurrency(maxStandard)}`;
  const dualText = minDual != null ? `${formatCurrency(minDual)} or more` : '';

  return {
    minStandardRebate: minStandard,
    maxStandardRebate: maxStandard,
    minDualAgencyRebate: minDual,
    standardRebateRangeText: standardText,
    dualAgencyRebateRangeText: dualText,
    hasDualAgencyOption: allowsDualAgency && minDual != null,
  };
}

export const REBATE_RESTRICTED_STATES = ['AL', 'AK', 'KS', 'LA', 'MS', 'MO', 'OK', 'OR', 'TN', 'IA'];

export function isRebateRestricted(state) {
  if (!state || typeof state !== 'string') return false;
  const code = state.trim().toUpperCase();
  return REBATE_RESTRICTED_STATES.includes(code);
}

export const REBATE_WORDING = {
  estimatedRebateRangeNotice: 'Estimated Rebate Range is based on the anticipated buyer broker compensation offered by the seller or listing brokerage and is subject to change. The actual rebate amount may vary, be reduced, or not be available depending on the final purchase price, the compensation offered or negotiated, lender approval, and the terms agreed upon in the purchase agreement.',
  standardRebateSubtitle: 'The actual rebate amount will be based on the buyer broker commission negotiated and agreed to as part of the transaction. Real estate commissions are fully negotiable.',
  dualAgencyRebateSubtitle: 'When you work directly with the listing agent, the actual rebate amount will be based on the commission negotiated and agreed to as part of the transaction. Real estate commissions are fully negotiable.',
  importantNotice: 'Buyer broker compensation is negotiable and subject to change. The actual rebate may vary based on the final purchase price, negotiated compensation, lender approval, and purchase agreement terms. Work with your agent for specific details.',
  restrictedStateNotice: 'Real estate rebates are not permitted in this state. The estimates below are for reference only and do not apply to transactions in this location.',
};

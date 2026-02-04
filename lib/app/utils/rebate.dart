// Rebate calculation utilities.

class RebateEstimate {
  final int ownAgentRebateCents;
  final int directRebateCents; // Rebate when working directly with listing agent
  final int?
  directRebateMaxCents; // Legacy field (kept for backward compatibility)

  const RebateEstimate({
    required this.ownAgentRebateCents,
    required this.directRebateCents,
    this.directRebateMaxCents,
  });
}

int _percentOf(int cents, double percent) {
  final double result = cents * (percent / 100.0);
  return result.round();
}

// Estimates two rebate amounts: using your own agent vs contacting listing agent directly.
// The parameters ownAgentShareOfBAC and directBuyerShareOfBAC are configurable defaults.
RebateEstimate estimateRebate({
  required int priceCents,
  required double bacPercent,
  required bool dualAgencyAllowed,
  double? dualAgencyCommissionPercent,
  double ownAgentShareOfBAC =
      30.0, // buyer keeps 30% of BAC via their own agent
  double directBuyerShareOfTotalCommission =
      40.0, // buyer keeps 40% of total commission when going direct
}) {
  final int bacCents = _percentOf(priceCents, bacPercent);

  final int ownAgentRebate = _percentOf(bacCents, ownAgentShareOfBAC);

  int baseCommissionForDirect = bacCents;
  if (dualAgencyAllowed && dualAgencyCommissionPercent != null) {
    baseCommissionForDirect =
        _percentOf(priceCents, dualAgencyCommissionPercent);
  }

  final int directRebate = dualAgencyAllowed
      ? _percentOf(baseCommissionForDirect, directBuyerShareOfTotalCommission)
      : ownAgentRebate;

  return RebateEstimate(
    ownAgentRebateCents: ownAgentRebate,
    directRebateCents: directRebate,
    directRebateMaxCents: null,
  );
}

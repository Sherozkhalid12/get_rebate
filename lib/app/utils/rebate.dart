// Rebate calculation utilities.

class RebateEstimate {
  final int ownAgentRebateCents;
  final int directRebateCents; // Minimum rebate when working with listing agent
  final int?
  directRebateMaxCents; // Maximum rebate when working with listing agent

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
  double ownAgentShareOfBAC =
      30.0, // buyer keeps 30% of BAC via their own agent
  double directBuyerShareOfBACMin =
      40.0, // buyer keeps 40% minimum of BAC when going direct
  double directBuyerShareOfBACMax =
      50.0, // buyer keeps 50% maximum of BAC when going direct
}) {
  final int bacCents = _percentOf(priceCents, bacPercent);

  final int ownAgentRebate = _percentOf(bacCents, ownAgentShareOfBAC);
  final int directRebateMin = dualAgencyAllowed
      ? _percentOf(bacCents, directBuyerShareOfBACMin)
      : ownAgentRebate;
  final int? directRebateMax = dualAgencyAllowed
      ? _percentOf(bacCents, directBuyerShareOfBACMax)
      : null;

  return RebateEstimate(
    ownAgentRebateCents: ownAgentRebate,
    directRebateCents: directRebateMin,
    directRebateMaxCents: directRebateMax,
  );
}

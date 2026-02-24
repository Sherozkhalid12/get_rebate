/// Shared rebate wording for all buyer-facing listing screens.
/// Ensures consistent compliance messaging across the app.
class RebateWordingConstants {
  RebateWordingConstants._();

  /// Main Estimated Rebate Range notice (blue info box).
  /// Explains that the range is based on anticipated compensation and may vary.
  static const String estimatedRebateRangeNotice =
      'Estimated Rebate Range is based on the anticipated buyer broker '
      'compensation offered by the seller or listing brokerage and is subject to change. '
      'The actual rebate amount may vary, be reduced, or not be available depending on '
      'the final purchase price, the compensation offered or negotiated, lender approval, '
      'and the terms agreed upon in the purchase agreement.';

  /// Subtitle for "When you work with an Agent from this site" rebate card.
  static const String standardRebateSubtitle =
      'The actual rebate amount will be based on the buyer broker commission negotiated '
      'and agreed to as part of the transaction. Real estate commissions are fully negotiable.';

  /// Subtitle for "When you work directly with the listing agent" (dual agency) rebate card.
  static const String dualAgencyRebateSubtitle =
      'When you work directly with the listing agent, the actual rebate amount will be '
      'based on the commission negotiated and agreed to as part of the transaction. '
      'Real estate commissions are fully negotiable.';

  /// Important Notice disclaimer (yellow warning box).
  static const String importantNotice =
      'Buyer broker compensation is negotiable and subject to change. '
      'The actual rebate may vary based on the final purchase price, negotiated compensation, '
      'lender approval, and purchase agreement terms. Work with your agent for specific details.';
}

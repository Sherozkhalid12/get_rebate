import 'package:get/get.dart';

class RebateChecklistController extends GetxController {
  List<String> getRebateChecklistForBuying() {
    return [
      'Confirm State Eligibility: Verify that the buyer is purchasing or building in a state that allows real estate rebates. These 10 states currently do not allow real estate rebates: Alabama, Alaska, Kansas, Louisiana, Mississippi, Missouri, Oklahoma, Oregon, Tennessee, and Iowa.',
      'Prepare a Buyer Representation Agreement as you normally would and include the addendum below (or a similar version approved by your broker). (See attached sample form.)',
      'Verify Loan Officer and Lender Participation: Ensure the buyer is pre-approved with a loan officer whose lender allows real estate rebates. (Agents and buyers can search this site for a list of confirmed loan officers.)',
      'Coordinate Seller Concessions and Rebate Limits: Confirm with the buyer\'s loan officer whether "seller concessions" will be requested in the offer. Determine the maximum amount allowed, including the rebate, to ensure the buyer receives the full benefit. Some lenders handle seller concessions and rebates separately—clarify how the lender manages this. It\'s often helpful to review the numbers with the loan officer before submitting the offer.',
      'Review Special Financing Programs: If the buyer is using special financing programs (e.g., first-time homebuyer grants, state or city programs), note that some may restrict or prohibit rebates. Buyers must work with programs and lenders that allow rebates. Make sure buyers understand how their financing decisions may affect rebate eligibility.',
      'For New Construction Purchases: Confirm with the builder that rebates are allowed. Most builders permit them, but some may restrict or prohibit them. If an issue arises, contact us for alternative ideas to try.',
      'Notify the Title or Closing Company Early: Inform the title or closing company that the transaction will include a rebate. Experienced closers will know how to properly document this, though some may need to confirm internal procedures. The rebate should appear on the settlement statement as a credit to the buyer.',
      'Calculate and Verify the Rebate Amount: Use the Rebate Calculator on the site to determine the rebate amount. Buyers also have access to this tool. Because the rebate may change during negotiations, confirm the final amount once the offer is accepted and all contingencies are removed.',
      'Include Rebate Disclosure and Commission Split in the Offer: When submitting an offer, include the rebate disclosure and commission split language (or broker-approved equivalent).',
    ];
  }

  List<String> getRebateChecklistForSelling() {
    return [
      'Confirm Rebate Eligibility: Verify that the property is located in a state that allows real estate rebates. Currently, 11 states do not allow rebates when selling: Alabama, Alaska, Kansas, Louisiana, Mississippi, Missouri, Oklahoma, Oregon, Tennessee, New Jersey, and Iowa.',
      'Complete your listing agreement as you normally would. Then, include and complete a Listing Agent Rebate Disclosure Addendum/Amendment to document the rebate option you and the Seller have selected. (You may use the sample document provided below or your own broker-approved language.) Be sure that both you and the Seller(s) sign the Rebate Addendum/Amendment and that it is included with the signed listing agreement.',
      'Notify the Title/Closing Company: Contact the title or closing company early to let them know a rebate will be part of the transaction. Confirm any special documentation or instructions they may require. The rebate should appear on the settlement statement as a credit to the Seller if the rebate option is chosen.',
      'Confirm Final Rebate or Fee Reduction Amount: Use the "Seller Conversion" calculator tab in the Rebate Calculator on GetaRebate.com to determine the correct amount or fee. Adjust the amount if the final commission or negotiated terms change.',
      'After Closing: Encourage the Seller to leave feedback on your GetaRebate.com profile — this helps build your reputation and visibility. If a rebate was given, the actual rebate amount will show on the settlement statement and the closer should point it out to the Seller at closing. If you used the lower listing fee option, use the calculator to show what that savings equates to. It\'s best that the seller knows the dollar amount they ended up saving so they can tell friends to refer you to!',
    ];
  }

  /// Returns the rebate addendum wording for the Buyer Representation Agreement (Step #2)
  String getRebateAddendumForBuyerRepresentation() {
    return '''The rebate is typically based only on the total Buyer Agent Commission (BAC) negotiated/ paid by the seller or builder. BAC is now negotiated on a property-by-property basis. Real Estate commission is 100% negotiable.

REBATE TIERS (Based on Total Commission received by Agent/Broker)

Use the Estimated Calculator tab on GetaRebate.com or the mobile app before writing an offer, and the Actual Calculator tab once price and BAC are known to calculate rebate amounts. If Dual Agency applies the rebate is then determined by the total commission received "Buyer Agent Commission" (BAC) plus "Listing Agent Commission" (LAC). Dual Agency is when the same agent who has the property listed for sale, also works with the Buyer.

Tier 1: If total commission received is 4.0% or higher of the purchase price, rebate amount is 40% of the total commission received. Tier 2: 3.01 to 3.99% = 35%, Tier 3: 2.5% to 3.0% = 30%, Tier 4: 2.0% to 2.49% = 25%, Tier 5: 1.5% to 1.99% = 20%, Tier 6: .25% to 1.49% = 10%, Tier 7: 0% to .24% = 0% (Higher commission equals higher rebate)

For sales prices of \$700,000 or higher, tiers 5 and 6 do not apply and only tiers 1, 2, 3, 4 or 7 apply.

Rebate appears as a credit on the Closing Disclosure/Settlement Statement, subject to lender approval.

REQUIREMENTS & LIMITATIONS

1. Lender Approval: Buyer must choose a lender/program that allows rebates. (All loan officers on GetaRebate.com have confirmed their lender permits rebates, but Buyer must verify final approval.)

2. State Restrictions: Rebates are currently allowed in 40 states. Buyer must purchase in a rebate-allowed state.

3. Builder Restrictions: Some builders prohibit or limit rebates. If so, Buyer may: Choose a different builder, or Negotiate upgrades/concessions in exchange for lowering the BAC.

4. Not Guaranteed: Despite best efforts, a rebate may be reduced or disallowed due to lender, builder, or state law restrictions.

BUYER AGENT AND BUYER RESPONSIBILITIES

Buyer Agent and Buyer agree to:

Follow the Buying/Building Checklists on GetaRebate.com/app.

Disclose the rebate to all parties.

Confirm rebate eligibility with their lender. And follow all necessary steps.

REBATE ELECTION

Buyer elects to participate in the rebate program:

Yes No''';
  }

  /// Returns the rebate disclosure wording for the Purchase Offer (Step #9)
  String getRebateDisclosureForPurchaseOffer() {
    return '''Real Estate Commission Rebate and Commission Split Disclosure:

Buyer, Seller, and Listing Brokerage acknowledge and agree that the total real estate commission shall be split between the Listing Brokerage and the Buyer's Brokerage at closing, allowing the Buyer's Brokerage to provide a rebate to the Buyer as a credit on the settlement statement.

Buyer and Seller acknowledge that Buyer's Agent has agreed to provide a real estate commission rebate to Buyer in the amount of \$____, or as otherwise agreed upon in writing, subject to approval and acceptance by Buyer's lender of choice. Said rebate shall generally be applied as a credit to Buyer's allowable closing costs on the final settlement statement, provided such credit is permitted by applicable lending guidelines and closing instructions.

The final rebate amount may be adjusted based on negotiated terms of the Purchase Agreement, lender requirements, and applicable state or federal laws. All parties acknowledge that the real estate commission is fully negotiable and that this rebate has been properly disclosed in accordance with state law, lender policy, and the terms of Buyer's agency agreement.''';
  }

  /// Returns the rebate disclosure wording for Seller Listing Agreement (Step #2) - Updated document
  String getRebateDisclosureForListingAgreement() {
    return '''Listing/Selling Commission Rebate Addendum/Amendment

This Listing/Selling Commission Rebate Addendum/Amendment ("Addendum") is attached to and made part of the Listing Agreement between Seller and Listing Broker/Agent for the property located at: __________________________________________.

The rebate options described below are based solely on the original listing fee/commission stated on Line ____ of the attached Listing Agreement ("Original Commission"). The rebate applies only to the commission paid to the Listing Agent/Broker.

REBATE OPTIONS (Both give identical savings/rebate amount)

Option 1 – Reduced Listing Fee (Available in All 50 States) Preferred option

Seller elects to receive a reduced listing fee in lieu of receiving a rebate at closing.

1. The reduced listing fee shall be calculated using the Seller Conversion Calculator provided on GetaRebate.com or the mobile app.

2. The calculator will use the Original Commission percentage and sales price to determine the Reduced Commission percentage.

3. To determine the savings/rebate, take Original Commission minus Reduced Commission (example 3.0% - 2.1% = .9%) times the sales price.

4. No monetary rebate will appear on the Closing Disclosure/Settlement Statement under this option.

Seller elects Option 1: Yes No

If yes, enter Original Commission percentage_________% ,and Reduced Commission percentage_________%.

Option 2 – Commission Rebate at Closing (currently Available in 39 States)

Seller elects to receive a commission rebate paid as a credit on the Closing Disclosure/Settlement Statement.

1. The rebate amount shall be calculated using the Estimated and Actual Calculator tabs on GetaRebate.com or the mobile app.

2. All rebates must meet lender guidelines (if applicable) and be disclosed to all parties.

3. Let title company or closer know that rebate is to be shown as a credit to Seller at closing on the Settlement Statement.

Seller elects Option 2: Yes No

ADDITIONAL TERMS

1. This Addendum supersedes any conflicting terms in the Listing Agreement regarding commission rebates or listing fee adjustments.

2. All rebate calculations are estimates until final commission and sales price amounts are determined.

3. The rebate will be applied only to the commission paid to the Listing Agent/Broker ("LAC").

4. If another brokerage represents the buyer, that brokerage will receive the Buyer Agent Commission ("BAC"), and no portion of that commission is included in this rebate calculation. For option 1 or 2.

5. In the event the Listing Agent enters into a Dual Agency situation, the rebate shall be based on the total commission received (combined LAC + BAC). For option 1 or 2.

6. A higher total commission results in a higher rebate/savings.

7. The Seller acknowledges that rebate availability and limitations may vary based on state law, lender restrictions, and transaction structure.

8. The Listing Agent/Broker makes no guarantee that a lender will approve the rebate, if applicable.''';
  }
}

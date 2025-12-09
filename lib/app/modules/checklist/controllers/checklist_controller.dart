import 'package:get/get.dart';

class ChecklistController extends GetxController {
  // Consumer-friendly checklists (no real estate jargon)
  
  List<String> getBuyerChecklist() {
    return [
      'Get Pre-Approved\n\nFind a loan officer on our site who allows a rebate to be applied. Or, confirm your loan officer allows rebates.\n\nGet your pre-approval letter and know your budget.',
      'Choose Your Agent\n\nEvery agent on our site has agreed to give you a rebate when you work with them. You must work with an agent from this site in order to get a rebate.',
      'Search for Homes\n\nTour homes, compare, and pick your favorite. All homes listed on our site will note a likely rebate range if you were to buy that home. A rebate will work on any home for sale where the seller, builder and/or listing agent is sharing part of the commission with the agent working with the Buyer. The rebate comes from that commission.',
      'Make an Offer\n\nWork with your agent to submit your offer and negotiate terms. You and your agent should include the BAC (Buyer Agent Compensation) directly on the purchase agreement. Once you finalize the sales price and the BAC, you will be able to calculate your exact rebate.',
      'Inspection & Appraisal\n\nGet a home inspection and review results.\n\nYour lender will handle the appraisal.',
      'Finalize Financing & Rebate\n\nConfirm with your agent and lender that your rebate will appear on the closing disclosure.',
      'Closing Day\n\nSign papers, get your keys and your rebate — then celebrate!',
      'Leave Feedback (after closing)\n\nPlease leave feedback for your Agent and/or Loan Officer from this site. Leaving feedback helps recognize agents and loan officers who did a great job and builds their reputation on our site. Your review also helps future buyers and sellers choose trusted agents and loan officers who provide great service and honor their rebate commitment.',
    ];
  }
  
  // Returns true if the checklist item at index should have a clickable link
  bool hasLinkForBuyerItem(int index) {
    // Index 0 = Get Pre-Approved (search loan officer)
    // Index 1 = Choose Your Agent (search agents)
    // Index 2 = Search for Homes (search homes)
    // Index 3 = Make an Offer (calculate rebate)
    // Index 7 = Leave Feedback (leave review)
    return index == 0 || index == 1 || index == 2 || index == 3 || index == 7;
  }
  
  // Returns the action type for the link
  String? getLinkActionForBuyerItem(int index) {
    if (index == 0) return 'search_loan_officer';
    if (index == 1) return 'search_agents';
    if (index == 2) return 'search_homes';
    if (index == 3) return 'calculate_rebate';
    if (index == 7) return 'leave_review';
    return null;
  }

  List<String> getSellerChecklist() {
    return [
      'Choose Your Agent\n\nAll agents on our site have agreed to offer a rebate when you work with them.\n\nThe rebate can either be a credit to you at closing, or, the easiest option is to adjust the listing fee by calculating in the rebate.\n\nSelect an experienced agent who knows your market.',
      'Prepare Your Home\n\nDeclutter, clean, and make small repairs.\n\nBoost curb appeal with simple touches (fresh paint, yard cleanup).',
      'Set the Price\n\nReview a market analysis with your agent.\n\nPrice your home competitively to attract buyers.',
      'List & Market Your Home\n\nYour agent will list your home on the MLS and major websites.\n\nKeep your home showing-ready at all times.',
      'Review Offers\n\nCompare offers carefully — not just price, but terms and timing.\n\nWork with your agent to negotiate the best deal.',
      'Inspection & Appraisal\n\nBe prepared for the buyer\'s inspection and possible repair requests.\n\nCooperate with the appraiser for smooth processing.',
      'Closing Preparation\n\nReview your closing statement and confirm your rebate amount.\n\nGather keys, warranties, and utility info for the buyer.',
      'Closing Day\n\nSign documents, hand over the keys, and enjoy your rebate savings!',
      'Leave Feedback (after closing)\n\nPlease leave feedback for your Agent from this site. Leaving feedback helps recognize agents who did a great job and builds their reputation on our site. Your review also helps future buyers and sellers choose trusted agents who provide great service and honor their rebate commitment.',
    ];
  }
  
  // Returns true if the checklist item at index should have a clickable link
  bool hasLinkForSellerItem(int index) {
    // Index 0 = Choose Your Agent (search agents)
    // Index 8 = Leave Feedback (leave review)
    return index == 0 || index == 8;
  }
  
  // Returns the action type for the link
  String? getLinkActionForSellerItem(int index) {
    if (index == 0) return 'search_agents';
    if (index == 8) return 'leave_review';
    return null;
  }
}


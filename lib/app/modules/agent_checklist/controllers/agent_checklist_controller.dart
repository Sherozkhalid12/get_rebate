import 'package:get/get.dart';

class AgentChecklistController extends GetxController {
  List<String> getAgentChecklist() {
    return [
      'Complete Your Profile: Fill out your agent profile with accurate information including your brokerage, license number, licensed states, specialties, and professional bio. A complete profile helps buyers and sellers find and trust you.',
      'Add Your Contact & Listing Information: Ensure your contact details are correct and include any relevant links (such as your website or listings). This information is visible to buyers and sellers viewing your profile.',
      'Claim ZIP Codes: Select and claim ZIP codes in your licensed states where you want to appear in buyer and seller searches. You can claim up to 6 ZIP codes. Pricing is based on population tiers, ranging from \$3.99 to \$26.99 per month per ZIP code.',
      'Respond to Inquiries Promptly: When buyers or sellers contact you through the platform, respond quickly. Timely responses increase trust and improve conversion into real clients.',
      'Work with Buyers: Represent buyers in home purchases and clearly explain how rebates may apply. Rebates typically come from the commission offered by the seller, listing broker, or builder and often appear as a credit at closing.',
      'Work with Sellers: Assist sellers with listing and selling their homes. Savings for sellers are usually provided through a reduced listing fee, depending on the agreement.',
      'Verify Rebate Eligibility: Confirm that rebates are permitted in the applicable state and that the transaction structure supports them. Coordinate with lenders and title/closing companies when rebates are involved.',
      'Coordinate with Loan Officers: Work closely with loan officers to ensure buyers are pre-approved and that rebate structures align with loan requirements.',
      'Coordinate with Title Companies: Communicate with title and closing companies regarding rebate credits when applicable to ensure a smooth closing process.',
      'Use In-App Messaging Professionally: Communicate clearly and professionally with buyers, sellers, and loan officers using the in-app messaging system, then transition to direct communication as needed.',
      'Update Your Profile Regularly: Keep your profile information current, including licensed states, specialties, contact details, and any changes to your brokerage.',
      'Build Your Reputation: Encourage satisfied buyers and sellers to leave reviews on your profile. Strong reviews improve visibility and trust on the platform.',
    ];
  }

  /// Get information about how the platform works for agents
  String getPlatformOverview() {
    return '''This platform connects you with buyers and sellers searching for real estate professionals in specific ZIP codes. By claiming ZIP codes, your profile becomes visible in searches, allowing you to generate leads and build relationships.

Key Points:
• Buyers and sellers can view your agent profile
• You appear in searches based on claimed ZIP codes
• Users can contact you through in-app messaging
• Rebates may apply depending on state rules and transaction structure
• You work directly with buyers, sellers, lenders, and title companies outside the app
• The platform helps you get discovered and generate leads, while transactions occur in real life''';
  }

  List<String> getSuccessTips() {
    return [
      'Keep your profile complete and accurate',
      'Respond quickly to buyer and seller inquiries',
      'Claim ZIP codes where you actively work',
      'Be clear and transparent about rebates',
      'Coordinate early with lenders and title companies',
      'Maintain professional communication',
      'Encourage clients to leave reviews',
    ];
  }
}

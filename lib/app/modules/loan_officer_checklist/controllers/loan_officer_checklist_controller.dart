import 'package:get/get.dart';

class LoanOfficerChecklistController extends GetxController {
  /// Get the main loan officer checklist
  /// This explains what loan officers do and how they work with the platform
  List<String> getLoanOfficerChecklist() {
    return [
      'Complete Your Profile: Fill out your loan officer profile with accurate information including your company, license number, licensed states, specialty products, and professional bio. A complete profile helps buyers and agents find and trust you.',
      'Add Your Mortgage Application Link: Include your mortgage application URL in your profile. This link is visible to buyers and agents who view your profile, allowing them to easily access your mortgage application process.',
      'Claim ZIP Codes: Select and claim ZIP codes in your licensed states where you want to appear in buyer searches. You can claim up to 6 ZIP codes. The cost is based on population tiers, ranging from \$3.99 to \$26.99 per month per ZIP code.',
      'Respond to Inquiries: When buyers or agents contact you through the platform, respond promptly. The platform provides opportunities, but most of your work happens outside the app through your mortgage application link and direct communication.',
      'Work with Buyers: Help buyers get pre-approved for mortgages and guide them through the loan process. Use your mortgage application link to process applications outside the platform.',
      'Collaborate with Agents: Agents on the platform may refer buyers to you. Work with agents to ensure smooth transactions and help buyers secure financing for their home purchases.',
      'Verify Rebate Eligibility: When working with buyers who are receiving rebates, ensure your lender allows real estate rebates. All loan officers on this platform have confirmed their lenders permit rebates.',
      'Coordinate with Title Companies: Communicate with title/closing companies about rebate transactions when applicable. Ensure all parties understand how rebates affect the loan and closing process.',
      'Review Special Financing Programs: If buyers are using special financing programs (first-time homebuyer grants, state/city programs), verify these programs allow rebates. Some programs may restrict or prohibit rebates.',
      'Maintain Professional Communication: Use the in-app messaging system to communicate with buyers and agents. Keep conversations professional and helpful, then transition to your mortgage application process outside the platform.',
      'Update Your Profile Regularly: Keep your profile information current, including your mortgage application link, specialty products, and any changes to your licensed states or company information.',
      'Build Your Reputation: Encourage satisfied buyers and agents to leave reviews on your profile. Positive reviews help increase your visibility and trustworthiness on the platform.',
    ];
  }

  /// Get information about how the platform works for loan officers
  String getPlatformOverview() {
    return '''This platform connects you with buyers and agents who are looking for mortgage services. While the platform provides opportunities and connections, most of your actual loan processing work happens outside the app through your mortgage application link and direct communication.

Key Points:
• Buyers and agents can view your profile and see your mortgage application link
• They can chat with you through the in-app messaging system
• Your mortgage application link is prominently displayed on your profile
• The platform helps you get discovered, but loan processing happens through your external mortgage application system
• You work with buyers and agents in real life to provide mortgage services
• All loan officers on this platform have confirmed their lenders allow real estate rebates''';
  }

  /// Get tips for success on the platform
  List<String> getSuccessTips() {
    return [
      'Keep your profile complete and up-to-date',
      'Respond quickly to messages from buyers and agents',
      'Make sure your mortgage application link is working and accessible',
      'Claim ZIP codes in areas where you actively work',
      'Encourage satisfied clients to leave reviews',
      'Be transparent about rebate eligibility with buyers',
      'Coordinate effectively with agents and title companies',
    ];
  }
}

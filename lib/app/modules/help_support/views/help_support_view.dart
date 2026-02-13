import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportView extends StatefulWidget {
  const HelpSupportView({super.key});

  @override
  State<HelpSupportView> createState() => _HelpSupportViewState();
}

class _HelpSupportViewState extends State<HelpSupportView> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'Are Real Estate Rebates Legal?',
      'answer': 'Yes. The United States Department of Justice actually promotes real estate rebates and says "Competition among real-estate brokerages protects American homebuyers and helps reduce prices and improve services for consumers." and "All buyers and sellers benefit if the process of selling homes is less expensive. Consequently, allowing non-misleading rebates and inducements is procompetitive and represents an important component of price competition." Also, organizations like Consumer Federation of America and some homebuyer advocacy groups promote rebates as a way to make buying a home more affordable.',
    },
    {
      'question': 'Are rebates legal in all 50 states?',
      'answer': 'No. Currently 40 states allow rebates to buyers, and those same 40 (except New Jersey) allow rebates to sellers. Our app only operates in states where rebates are legally permitted. The following states ban or restrict real estate rebates and are not available in our app: Alabama, Alaska, Iowa, Kansas, Louisiana, Mississippi, Missouri, Oklahoma, Oregon, and Tennessee.',
    },
    {
      'question': 'Is Get a Rebate Real Estate a licensed real estate broker?',
      'answer': 'Yes. Get a Rebate Real Estate is a fully licensed real estate brokerage in the State of Minnesota. We created this platform so buyers and sellers nationwide can benefit from the same rebate savings we have successfully offered our Minnesota clients for more than 25 years, where permitted by law.',
    },
    {
      'question': 'How do I find a real estate agent?',
      'answer': 'Use the search bar on the home screen to enter a ZIP code. Browse through the Agents tab to see available agents in your area. You can view their profiles, ratings, and contact them directly.',
    },
    {
      'question': 'How does the rebate work?',
      'answer': 'When you work with an agent from GetaRebate.com, you may receive savings when you buy, build, or sell. For buyers, the rebate comes from the commission offered by the seller, listing broker, or builder and typically appears as a credit at closing. Commission terms are negotiated when you make an offer. For sellers, savings are usually provided through a reduced listing fee. Restrictions may apply—please coordinate with your agent, lender, and title/closing company to ensure eligibility and a smooth rebate process.',
    },
    {
      'question': 'Is GetaRebate free to use?',
      'answer': 'Yes, GetaRebate is completely free for buyers and sellers.The rebate amount will vary per transaction/property and will be determined by the amount of Buyer Agent Comission being paid on that property, which is negotiable when making an offer.',
    },
    {
      'question': 'How do I cotact an Agent or Loan Officer?',
      'answer': 'Tap on any agent\'s & Loan Officer\'s profile card to view their full profile. From there, you can use the "Contact" button to send them a message or start a conversation.',
    },
    {
      'question': 'Can I save my favorite agents and loan officers?',
      'answer': 'Yes! Tap the heart icon on any agent or loan officer card to add them to your favorites. You can view all your favorites in the Favorites tab.',
    },
    {
      'question': 'How do I calculate my potential rebate?',
      'answer': 'Use the Rebate Calculator tool available on the home screen.  Use the Estimated calculator to get an estimate.  Use the Actual calculator once you know the buyer agent commission being paid.  And use the Seller Conversion tab to calculate what your lowered commission would be including the rebate when you are looking to sell.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.primaryGradient,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(context),
                ],
              ),              SizedBox(height: 24.h),
              
              // Quick Actions
              _buildQuickActions(context),
              SizedBox(height: 24.h),
              
              // FAQ Section
              _buildSectionTitle(context, 'Frequently Asked Questions'),
              SizedBox(height: 16.h),
              
              _buildFAQItem(
                context,
                'Are Real Estate Rebates Legal?',
                'Yes. The United States Department of Justice actually promotes real estate rebates and says "Competition among real-estate brokerages protects American homebuyers and helps reduce prices and improve services for consumers." and "All buyers and sellers benefit if the process of selling homes is less expensive. Consequently, allowing non-misleading rebates and inducements is procompetitive and represents an important component of price competition." Also, organizations like Consumer Federation of America and some homebuyer advocacy groups promote rebates as a way to make buying a home more affordable.',
              ),

              _buildFAQItem(
                context,
                'Are rebates legal in all 50 states?',
                'No. Currently 40 states allow rebates to buyers, and those same 40 (except New Jersey) allow rebates to sellers. Our app only operates in states where rebates are legally permitted. The following states ban or restrict real estate rebates and are not available in our app: Alabama, Alaska, Iowa, Kansas, Louisiana, Mississippi, Missouri, Oklahoma, Oregon, and Tennessee.',
              ),

              _buildFAQItem(
                context,
                'Is Get a Rebate Real Estate a licensed real estate broker?',
                'Yes. Get a Rebate Real Estate is a fully licensed real estate brokerage in the State of Minnesota. We created this platform so buyers and sellers nationwide can benefit from the same rebate savings we have successfully offered our Minnesota clients for more than 25 years, where permitted by law.',
              ),

              _buildFAQItem(
                context,
                'How do I find a real estate agent?',
                'Use the search bar on the home screen to enter a ZIP code. Browse through the Agents tab to see available agents in your area. You can view their profiles, ratings, and contact them directly.',
              ),
              
              _buildFAQItem(
                context,
                'How does the rebate work?',
                'When you work with an agent from GetaRebate.com, you may receive savings when you buy, build, or sell. For buyers, the rebate comes from the commission offered by the seller, listing broker, or builder and typically appears as a credit at closing. Commission terms are negotiated when you make an offer. For sellers, savings are usually provided through a reduced listing fee. Restrictions may apply—please coordinate with your agent, lender, and title/closing company to ensure eligibility and a smooth rebate process.',
              ),
              
              _buildFAQItem(
                context,
                'Is GetaRebate free to use?',
                'Yes, GetaRebate is completely free for buyers and sellers.The rebate amount will vary per transaction/property and will be determined by the amount of Buyer Agent Comission being paid on that property, which is negotiable when making an offer.',
              ),
              
              _buildFAQItem(
                context,
                'How do I cotact an Agent or Loan Officer?',
                'Tap on any agent\'s & Loan Officer\'s profile card to view their full profile. From there, you can use the "Contact" button to send them a message or start a conversation.',
              ),
              
              _buildFAQItem(
                context,
                'Can I save my favorite agents and loan officers?',
                'Yes! Tap the heart icon on any agent or loan officer card to add them to your favorites. You can view all your favorites in the Favorites tab.',
              ),
              
              _buildFAQItem(
                context,
                'How do I calculate my potential rebate?',
                'Use the Rebate Calculator tool available on the home screen.  Use the Estimated calculator to get an estimate.  Use the Actual calculator once you know the buyer agent commission being paid.  And use the Seller Conversion tab to calculate what your lowered commission would be including the rebate when you are looking to sell.',
              ),
              
              SizedBox(height: 24.h),
              
              // Contact Section
              _buildSectionTitle(context, 'Contact Support'),
              SizedBox(height: 16.h),
              
              _buildContactCard(
                context,
                Icons.email,
                'Email Support',
                'support@getrebate.com',
                'Get help via email',
                () => _launchEmail('support@getrebate.com'),
              ),
              
              SizedBox(height: 12.h),
              
              _buildContactCard(
                context,
                Icons.phone,
                'Phone Support',
                '612-860-1537',
                'Call us Monday-Friday, 9 AM - 6 PM EST',
                () => _launchPhone('6128601537'),
              ),
              
              SizedBox(height: 12.h),
              
              _buildContactCard(
                context,
                Icons.chat_bubble_outline,
                'Live Chat',
                'Available 24/7',
                'Chat with our support team',
                () {
                  Get.snackbar(
                    'Live Chat',
                    'Live chat feature coming soon!',
                    backgroundColor: AppTheme.primaryBlue,
                    colorText: AppTheme.white,
                  );
                },
              ),
              
              SizedBox(height: 24.h),
              
              // Resources Section
              _buildSectionTitle(context, 'Resources'),
              SizedBox(height: 16.h),
              
              _buildResourceCard(
                context,
                'Buying Checklist',
                'Step-by-step guide for homebuyers',
                Icons.checklist,
                () => Get.toNamed('/checklist', arguments: {
                  'type': 'buyer',
                  'title': 'Homebuyer Checklist',
                }),
              ),
              
              SizedBox(height: 12.h),
              
              _buildResourceCard(
                context,
                'Selling Checklist',
                'Complete guide for home sellers',
                Icons.sell,
                () => Get.toNamed('/checklist', arguments: {
                  'type': 'seller',
                  'title': 'Home Seller Checklist',
                }),
              ),
              
              SizedBox(height: 12.h),
              
              _buildResourceCard(
                context,
                'Rebate Calculator',
                'Calculate your potential rebate',
                Icons.calculate,
                () => Get.toNamed('/rebate-calculator'),
              ),
              
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.help_outline,
            size: 40.sp,
            color: AppTheme.white,
          ),
          SizedBox(height: 12.h),
          Text(
            'We\'re Here to Help',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Find answers and get support',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.9),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            context,
            Icons.search,
            'Search FAQ',
            () => _showFAQSearchDialog(context),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildQuickActionCard(
            context,
            Icons.feedback,
            'Send Feedback',
            () => _launchEmail('support@getarebate.com', subject: 'App Feedback'),
          ),
        ),
      ],
    );
  }

  void _showFAQSearchDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    String searchQuery = '';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            child: Container(
              padding: EdgeInsets.all(20.w),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Search FAQ',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGray,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.mediumGray),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search questions...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGray,
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: _buildFAQSearchResults(context, searchQuery, _faqs),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildFAQSearchResults(BuildContext context, String query, List<Map<String, String>> faqs) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          'Type to search FAQs...',
          style: TextStyle(
            color: AppTheme.mediumGray,
            fontSize: 14.sp,
          ),
        ),
      );
    }

    final filteredFAQs = faqs.where((faq) {
      final question = faq['question']?.toLowerCase() ?? '';
      final answer = faq['answer']?.toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      return question.contains(searchQuery) || answer.contains(searchQuery);
    }).toList();

    if (filteredFAQs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48.sp, color: AppTheme.mediumGray),
            SizedBox(height: 16.h),
            Text(
              'No results found',
              style: TextStyle(
                color: AppTheme.mediumGray,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try different keywords',
              style: TextStyle(
                color: AppTheme.mediumGray,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: filteredFAQs.length,
      itemBuilder: (context, index) {
        final faq = filteredFAQs[index];
        return _buildFAQItem(context, faq['question']!, faq['answer']!);
      },
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 32.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.darkGray,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.darkGray,
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        childrenPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
        title: Text(
          question,
          style: TextStyle(
            color: AppTheme.darkGray,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: AppTheme.mediumGray,
              fontSize: 14.sp,
              height: 1.6,
            ),
          ),
        ],
        iconColor: AppTheme.primaryBlue,
        collapsedIconColor: AppTheme.mediumGray,
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String description,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.darkGray,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.mediumGray,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppTheme.mediumGray, size: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.lightGray),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 24.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.darkGray,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.mediumGray,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppTheme.mediumGray, size: 16.sp),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email, {String? subject}) async {
    try {
      // Try Gmail compose URL first (works on Android and iOS)
      final String gmailUrl = 'https://mail.google.com/mail/?view=cm&fs=1&to=$email${subject != null ? '&su=${Uri.encodeComponent(subject)}' : ''}';
      final Uri gmailUri = Uri.parse(gmailUrl);
      
      // Try to launch Gmail
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      // Continue to fallback
    }
    
    // Fallback 1: Try standard mailto
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: subject != null ? 'subject=${Uri.encodeComponent(subject)}' : null,
      );
      
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      // Continue to fallback
    }
    
    // Fallback 2: Show dialog with email address and copy option
    _showEmailDialog(email, subject);
  }

  void _showEmailDialog(String email, String? subject) {
    final String emailText = subject != null ? '$email\nSubject: $subject' : email;
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Contact Support',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkGray,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email address:',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.mediumGray,
              ),
            ),
            SizedBox(height: 8.h),
            SelectableText(
              emailText,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Please copy the email address and send your message from your email app.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.darkGray,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Close',
              style: TextStyle(color: AppTheme.mediumGray),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: email));
              Get.back();
              Get.snackbar(
                'Copied!',
                'Email address copied to clipboard',
                backgroundColor: AppTheme.primaryBlue,
                colorText: AppTheme.white,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppTheme.white,
            ),
            child: Text('Copy Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      Get.snackbar(
        'Error',
        'Could not open phone dialer',
        backgroundColor: Colors.red,
        colorText: AppTheme.white,
      );
    }
  }
}



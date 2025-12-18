import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

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
          onPressed: () => Get.back(),
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
                'How do I find a real estate agent?',
                'Use the search bar on the home screen to enter a ZIP code. Browse through the Agents tab to see available agents in your area. You can view their profiles, ratings, and contact them directly.',
              ),
              
              _buildFAQItem(
                context,
                'How does the rebate work?',
                'When you work with an agent through GetRebate and complete a real estate transaction, you may be eligible for a rebate. The rebate amount varies by agent and transaction. Check each agent\'s profile for their rebate percentage.',
              ),
              
              _buildFAQItem(
                context,
                'Is GetRebate free to use?',
                'Yes, GetRebate is completely free for buyers and sellers. There are no hidden fees. Agents pay subscription fees to be featured on our platform.',
              ),
              
              _buildFAQItem(
                context,
                'How do I contact an agent?',
                'Tap on any agent\'s profile card to view their full profile. From there, you can use the "Contact" button to send them a message or start a conversation.',
              ),
              
              _buildFAQItem(
                context,
                'Can I save my favorite agents?',
                'Yes! Tap the heart icon on any agent or loan officer card to add them to your favorites. You can view all your favorites in the Favorites tab.',
              ),
              
              _buildFAQItem(
                context,
                'How do I calculate my potential rebate?',
                'Use the Rebate Calculator tool available on the home screen. Enter your estimated home purchase price and the agent\'s rebate percentage to see your potential savings.',
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
                '+1 (555) 123-4567',
                'Call us Monday-Friday, 9 AM - 6 PM EST',
                () => _launchPhone('+15551234567'),
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
            size: 48.sp,
            color: AppTheme.white,
          ),
          SizedBox(height: 12.h),
          Text(
            'We\'re Here to Help',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 24.sp,
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
            () {
              // Show search dialog or navigate to FAQ search
              Get.snackbar(
                'Search FAQ',
                'FAQ search feature coming soon!',
                backgroundColor: AppTheme.primaryBlue,
                colorText: AppTheme.white,
              );
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildQuickActionCard(
            context,
            Icons.feedback,
            'Send Feedback',
            () => _launchEmail('feedback@getrebate.com', subject: 'App Feedback'),
          ),
        ),
      ],
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
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: subject != null ? 'subject=${Uri.encodeComponent(subject)}' : null,
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      Get.snackbar(
        'Error',
        'Could not open email client',
        backgroundColor: Colors.red,
        colorText: AppTheme.white,
      );
    }
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


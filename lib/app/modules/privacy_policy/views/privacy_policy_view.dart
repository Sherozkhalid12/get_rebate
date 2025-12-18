import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
          'Privacy Policy',
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
              ),
              SizedBox(height: 24.h),
              
              // Last Updated
              _buildLastUpdated(context),
              SizedBox(height: 32.h),
              
              // Content Sections
              _buildSection(
                context,
                '1. Introduction',
                'GetRebate ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
              ),
              
              _buildSection(
                context,
                '2. Information We Collect',
                'We collect information that you provide directly to us, including:\n\n'
                '• Personal Information: Name, email address, phone number, mailing address\n'
                '• Account Information: Username, password, profile information\n'
                '• Property Information: Property details, preferences, search history\n'
                '• Financial Information: Payment details, transaction history (processed securely through third-party providers)\n'
                '• Communication Data: Messages, inquiries, and correspondence\n'
                '• Usage Data: Device information, IP address, browser type, access times, pages viewed\n'
                '• Location Data: ZIP codes, geographic location (with your permission)',
              ),
              
              _buildSection(
                context,
                '3. How We Use Your Information',
                'We use the information we collect to:\n\n'
                '• Provide, maintain, and improve our services\n'
                '• Process transactions and send related information\n'
                '• Send you technical notices, updates, and support messages\n'
                '• Respond to your comments, questions, and requests\n'
                '• Communicate with you about products, services, and promotions\n'
                '• Monitor and analyze trends, usage, and activities\n'
                '• Detect, prevent, and address technical issues and fraudulent activity\n'
                '• Personalize your experience and provide relevant content',
              ),
              
              _buildSection(
                context,
                '4. Information Sharing and Disclosure',
                'We do not sell your personal information. We may share your information in the following circumstances:\n\n'
                '• With Service Providers: Third-party vendors who perform services on our behalf\n'
                '• With Real Estate Professionals: Agents and loan officers you choose to contact\n'
                '• For Legal Reasons: When required by law or to protect our rights\n'
                '• Business Transfers: In connection with a merger, acquisition, or sale of assets\n'
                '• With Your Consent: When you explicitly authorize us to share information',
              ),
              
              _buildSection(
                context,
                '5. Data Security',
                'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the Internet or electronic storage is 100% secure, and we cannot guarantee absolute security.',
              ),
              
              _buildSection(
                context,
                '6. Your Rights and Choices',
                'You have the right to:\n\n'
                '• Access and update your personal information\n'
                '• Delete your account and associated data\n'
                '• Opt-out of marketing communications\n'
                '• Request a copy of your data\n'
                '• Object to certain processing of your information\n\n'
                'You can exercise these rights by contacting us at privacy@getrebate.com or through the app settings.',
              ),
              
              _buildSection(
                context,
                '7. Cookies and Tracking Technologies',
                'We use cookies and similar tracking technologies to track activity on our app and hold certain information. You can instruct your device to refuse all cookies or to indicate when a cookie is being sent.',
              ),
              
              _buildSection(
                context,
                '8. Children\'s Privacy',
                'Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.',
              ),
              
              _buildSection(
                context,
                '9. Changes to This Privacy Policy',
                'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
              ),
              
              _buildSection(
                context,
                '10. Contact Us',
                'If you have any questions about this Privacy Policy, please contact us:\n\n'
                'Email: privacy@getrebate.com\n'
                'Address: GetRebate, Inc.\n'
                'Attn: Privacy Officer\n'
                '[Your Business Address]',
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
            Icons.privacy_tip,
            size: 48.sp,
            color: AppTheme.white,
          ),
          SizedBox(height: 12.h),
          Text(
            'Privacy Policy',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your privacy matters to us',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.9),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: AppTheme.primaryBlue, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(
                color: AppTheme.darkGray,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: TextStyle(
              color: AppTheme.darkGray,
              fontSize: 14.sp,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}


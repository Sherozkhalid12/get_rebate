import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/widgets/compliance_footer.dart';

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({super.key});

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
          'Terms of Service',
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
                '0. Definitions and Company Identity',
                'For the purposes of these Terms of Use, the following terms refer to the same company and business entity:\n\n'
                '• "Get a Rebate Real Estate"\n'
                '• "Get a Rebate"\n'
                '• "GetaRebate.com"\n\n'
                'These names may be used interchangeably throughout the Service (including this mobile application, website, and any related platforms), legal documents, communications, marketing materials, and any other context. All references to any of these names shall be understood to refer to one single legal entity and business organization.\n\n'
                'This clarification is intended to eliminate any potential confusion or ambiguity regarding the identity of the company providing the Service. Any use of these names, whether individually or collectively, does not create separate legal entities or alter the singular nature of the company providing the Service described in these Terms.',
              ),
              
              _buildSection(
                context,
                '1. Acceptance of Terms',
                'By accessing and using Get a Rebate Real Estate  ("the Service"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
              ),
              
              _buildSection(
                context,
                '2. Description of Service',
                'GetaRebate  is a platform that connects homebuyers and sellers with real estate agents and loan officers. We facilitate connections and provide tools to help users find properties, calculate potential rebates, and manage their real estate transactions. We do not act as a real estate broker, agent, or lender.',
              ),
              
              _buildSection(
                context,
                '3. User Accounts',
                'To use certain features of the Service, you must register for an account. You agree to:\n\n'
                '• Provide accurate, current, and complete information\n'
                '• Maintain and update your information to keep it accurate\n'
                '• Maintain the security of your password and identification\n'
                '• Accept all responsibility for activities that occur under your account\n'
                '• Notify us immediately of any unauthorized use of your account',
              ),
              
              _buildSection(
                context,
                '4. User Conduct',
                'You agree not to:\n\n'
                '• Use the Service for any illegal purpose or in violation of any laws\n'
                '• Transmit any harmful code, viruses, or malicious software\n'
                '• Attempt to gain unauthorized access to the Service\n'
                '• Interfere with or disrupt the Service or servers\n'
                '• Use automated systems to access the Service without permission\n'
                '• Impersonate any person or entity\n'
                '• Harass, abuse, or harm other users\n'
                '• Post false, misleading, or fraudulent information',
              ),

              _buildSection(
                context,
                '5. Real Estate Professionals',
                'Agents and loan officers who use the Get a Rebate Real Estate platform (“Platform”) do so as independent, third-party professionals affiliated with their own brokerages, lenders, or companies.\n\n'
                    'Nothing in these Terms of Use creates, or shall be deemed to create, any employment relationship, partnership, joint venture, agency, or independent contractor relationship between Get a Rebate Real Estate and any agent or loan officer using the Platform.\n\n'
                    'Agents and loan officers:\n\n'
                    '• Are not employees of Get a Rebate Real Estate\n'
                    '• Are not independent contractors of Get a Rebate Real Estate\n'
                    '• Operate solely under the license, supervision, and authority of their own brokerage, lender, or employer\n'
                    '• Are individually responsible for compliance with all applicable federal, state, and local laws, licensing requirements, regulations, disclosures, and ethical obligations\n\n'
                    'Get a Rebate Real Estate does not:\n\n'
                    '• Supervise, manage, or control the professional activities of agents or loan officers\n'
                    '• Provide legal, financial, or compliance oversight for transactions\n'
                    '• Participate in, negotiate, or represent any party in real estate or loan transactions, unless separately agreed in writing where Get a Rebate Real Estate is licensed.\n\n'
                    'All services provided to buyers or sellers are rendered solely by the agent’s or loan officer’s own brokerage, lender, or employer, and any commissions, rebates, fees, or compensation are handled in accordance with applicable law and the policies of their respective brokerages, lenders, or employers.',
              ),


              _buildSection(
                context,
                '6. Rebates and Financial Terms',
                'Rebate amounts displayed are estimates only and are not guaranteed. Agents, buyers, and sellers are solely responsible for using the provided checklists and calculators and for independently verifying rebate eligibility, structure, and amounts. Rebates may be reduced, limited, modified, or eliminated and may result in a \$0 rebate due to lender requirements, applicable laws or regulations, brokerage policies, or changes to transaction terms.\n\n'
                    'Checklists are provided for informational and compliance-support purposes only and do not constitute legal, financial, or lending advice. Certain lenders, builders, loan programs, down payment assistance programs, and other third parties may impose additional restrictions—even in jurisdictions where rebates are otherwise permitted. Users are responsible for confirming all requirements with their lender, brokerage, and settlement provider early in the transaction to determine rebate eligibility or to modify transaction terms accordingly.',
              ),


              _buildSection(
                context,
                '7. Intellectual Property',
                'The Service and its original content, features, and functionality are owned by GetaRebate  and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws. You may not copy, modify, distribute, sell, or lease any part of our Service.',
              ),
              
              _buildSection(
                context,
                '8. Disclaimer of Warranties',
                'THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.',
              ),
              
              _buildSection(
                context,
                '9. Limitation of Liability',
                'TO THE MAXIMUM EXTENT PERMITTED BY LAW, GETAREBATE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS OR REVENUES, WHETHER INCURRED DIRECTLY OR INDIRECTLY, OR ANY LOSS OF DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES.',
              ),
              
              _buildSection(
                context,
                '10. Indemnification',
                'You agree to indemnify and hold harmless GetaRebate , its officers, directors, employees, and agents from any claims, damages, losses, liabilities, and expenses (including legal fees) arising out of your use of the Service or violation of these Terms.',
              ),
              
              _buildSection(
                context,
                '11. Termination',
                'We may terminate or suspend your account and access to the Service immediately, without prior notice or liability, for any reason, including if you breach the Terms. Upon termination, your right to use the Service will immediately cease.',
              ),
              
              _buildSection(
                context,
                '12. Governing Law',
                'These Terms shall be governed by and construed in accordance with the laws of Minnesota, without regard to its conflict of law provisions. Any disputes arising under these Terms shall be subject to the exclusive jurisdiction of the courts in Minnesota.',
              ),
              
              _buildSection(
                context,
                '13. Changes to Terms',
                'We reserve the right to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.',
              ),
              
              _buildSection(
                context,
                '14. Contact Information',
                'If you have any questions about these Terms of Service, please contact us:\n\n'
                'Email: legal@getarebate.com\n\n'
                'Address: Get a Rebate Real Estate, 8400 Normandale Lake Blvd. #920, Bloomington, MN 55437\n'
                'Attn: Legal Department',
              ),
              
              const ComplianceFooter(),
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
            Icons.description,
            size: 48.sp,
            color: AppTheme.white,
          ),
          SizedBox(height: 12.h),
          Text(
            'Terms of Service',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please read these terms carefully',
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



import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/compliance_tutorial/controllers/compliance_tutorial_controller.dart';
import 'package:getrebate/app/widgets/gradient_card.dart';
import 'package:getrebate/app/widgets/custom_button.dart';

class ComplianceTutorialView extends StatelessWidget {
  const ComplianceTutorialView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ComplianceTutorialController>();

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
          'Compliance Tutorial',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Obx(() => _buildProgressIndicator(context, controller)),
            
            // Page View
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: (index) {
                  controller.currentPage.value = index;
                },
                children: [
                  _buildWelcomePage(context),
                  _buildDisclosurePage(context),
                  _buildRebateRulesPage(context),
                  _buildDocumentationPage(context),
                  _buildBestPracticesPage(context),
                ],
              ),
            ),
            
            // Navigation Buttons
            Obx(() => _buildNavigationButtons(context, controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, ComplianceTutorialController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              height: 4.h,
              decoration: BoxDecoration(
                color: controller.currentPage.value >= index
                    ? AppTheme.primaryBlue
                    : AppTheme.mediumGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Center(
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school,
                size: 64.sp,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Welcome to Compliance Tutorial',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Text(
            'Learn about real estate rebate compliance requirements and best practices to ensure you stay compliant with all regulations.',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.mediumGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          GradientCard(
            gradientColors: AppTheme.cardGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 24.sp),
                    SizedBox(width: 12.w),
                    Text(
                      'What You\'ll Learn',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildBulletPoint('Disclosure requirements'),
                _buildBulletPoint('Rebate rules and regulations'),
                _buildBulletPoint('Documentation best practices'),
                _buildBulletPoint('Compliance checklists'),
                _buildBulletPoint('Common pitfalls to avoid'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclosurePage(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Center(
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description,
                size: 64.sp,
                color: AppTheme.lightGreen,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Disclosure Requirements',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          GradientCard(
            gradientColors: AppTheme.cardGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Requirements',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.black,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildInfoCard(
                  Icons.check_circle,
                  'Written Disclosure',
                  'All rebate offers must be disclosed in writing before any agreement is signed.',
                  AppTheme.lightGreen,
                ),
                SizedBox(height: 12.h),
                _buildInfoCard(
                  Icons.check_circle,
                  'Timing Matters',
                  'Disclosures must be provided at the earliest opportunity, ideally during initial consultations.',
                  AppTheme.primaryBlue,
                ),
                SizedBox(height: 12.h),
                _buildInfoCard(
                  Icons.check_circle,
                  'Clear Language',
                  'Use plain, understandable language. Avoid technical jargon that may confuse clients.',
                  AppTheme.indigoBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRebateRulesPage(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Center(
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppTheme.indigoBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.gavel,
                size: 64.sp,
                color: AppTheme.indigoBlue,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Rebate Rules & Regulations',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          GradientCard(
            gradientColors: AppTheme.cardGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Rules',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.black,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildRuleItem(
                  'State Regulations',
                  'Rebate rules vary by state. Always check your state\'s specific requirements before offering rebates.',
                ),
                SizedBox(height: 12.h),
                _buildRuleItem(
                  'Licensing Requirements',
                  'Ensure you have proper licensing to offer rebates in your jurisdiction.',
                ),
                SizedBox(height: 12.h),
                _buildRuleItem(
                  'MLS Compliance',
                  'Check with your local MLS regarding rebate disclosure requirements in listings.',
                ),
                SizedBox(height: 12.h),
                _buildRuleItem(
                  'Lender Coordination',
                  'Coordinate with lenders to ensure rebates comply with loan requirements.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentationPage(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Center(
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppTheme.purpleBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder,
                size: 64.sp,
                color: AppTheme.purpleBlue,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Documentation Best Practices',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          GradientCard(
            gradientColors: AppTheme.cardGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What to Document',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.black,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildDocumentItem(
                  Icons.description,
                  'Rebate Agreement',
                  'Signed agreement outlining rebate terms and conditions.',
                ),
                SizedBox(height: 12.h),
                _buildDocumentItem(
                  Icons.receipt,
                  'Disclosure Forms',
                  'All disclosure forms provided to clients with timestamps.',
                ),
                SizedBox(height: 12.h),
                _buildDocumentItem(
                  Icons.chat_bubble_outline,
                  'Client Communications',
                  'Records of all communications regarding rebate offers.',
                ),
                SizedBox(height: 12.h),
                _buildDocumentItem(
                  Icons.payment,
                  'Payment Records',
                  'Documentation of rebate payments and receipts.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestPracticesPage(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Center(
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star,
                size: 64.sp,
                color: AppTheme.skyBlue,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Best Practices',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          GradientCard(
            gradientColors: AppTheme.cardGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips for Success',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.black,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildTipItem(
                  'Be Transparent',
                  'Always be upfront about rebate offers. Transparency builds trust.',
                ),
                SizedBox(height: 12.h),
                _buildTipItem(
                  'Document Everything',
                  'Keep detailed records of all rebate-related communications and agreements.',
                ),
                SizedBox(height: 12.h),
                _buildTipItem(
                  'Stay Updated',
                  'Regulations change. Regularly review and update your compliance practices.',
                ),
                SizedBox(height: 12.h),
                _buildTipItem(
                  'Consult Experts',
                  'When in doubt, consult with legal or compliance experts in your area.',
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          GradientCard(
            gradientColors: AppTheme.successGradient,
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48.sp,
                  color: AppTheme.white,
                ),
                SizedBox(height: 16.h),
                Text(
                  'You\'re All Set!',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'You now have a solid understanding of compliance requirements.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, ComplianceTutorialController controller) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (controller.currentPage.value > 0)
            Expanded(
              child: CustomButton(
                text: 'Previous',
                onPressed: controller.previousPage,
                isOutlined: true,
                icon: Icons.arrow_back,
              ),
            ),
          if (controller.currentPage.value > 0) SizedBox(width: 12.w),
          Expanded(
            flex: controller.currentPage.value == 0 ? 1 : 1,
            child: CustomButton(
              text: controller.currentPage.value == 4 ? 'Finish' : 'Next',
              onPressed: controller.currentPage.value == 4
                  ? () => Navigator.pop(context)
                  : controller.nextPage,
              icon: controller.currentPage.value == 4 ? Icons.check : Icons.arrow_forward,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String description, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.mediumGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String title, String description) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.mediumGray,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 24.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.black,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.mediumGray,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String title, String description) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          left: BorderSide(color: AppTheme.skyBlue, width: 4.w),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppTheme.skyBlue, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.mediumGray,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}


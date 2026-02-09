import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/about_legal/controllers/about_legal_controller.dart';

class AboutLegalView extends GetView<AboutLegalController> {
  const AboutLegalView({super.key});

  static const String _licenseText =
      'Get a Rebate Real Estate is a licensed real estate brokerage in the State of Minnesota. License #40896422.';
  static const String _pledgeText =
      'We are pledged to the letter and spirit of U.S. policy for the achievement of equal housing opportunity.';
  static const String _narDisclaimer =
      'Note, some agents may not be members of the National Association of Realtors. Check with the agent you elect to work with.';

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
          'About & Legal',
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
              // License text (brokerage info)
              _buildCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _licenseText,
                      style: TextStyle(
                        color: AppTheme.darkGray,
                        fontSize: 15.sp,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Equal Housing Opportunity section
              _buildSectionTitle(context, 'Equal Housing Opportunity'),
              SizedBox(height: 12.h),
              _buildCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/equal_housing_oppertunity.png',
                      height: 80.h,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.home_work,
                        size: 64.sp,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      _pledgeText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.darkGray,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      _narDisclaimer,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.mediumGray,
                        fontSize: 13.sp,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Multi Listing Service section
              _buildSectionTitle(context, 'Multiple Listing Service'),
              SizedBox(height: 12.h),
              _buildCard(
                context,
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/multi_listing_service.png',
                      height: 80.h,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.map_outlined,
                        size: 64.sp,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.primaryBlue,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}

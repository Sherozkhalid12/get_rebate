import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';

/// Equal Housing Opportunity + license compliance block for Privacy Policy / Terms of Service footers.
class ComplianceFooter extends StatelessWidget {
  const ComplianceFooter({super.key});

  static const String _licenseText =
      'Get a Rebate Real Estate is a licensed real estate brokerage in the State of Minnesota. License #40896422.';
  static const String _pledgeText =
      'We are pledged to the letter and spirit of U.S. policy for the achievement of equal housing opportunity.';
  static const String _narDisclaimer =
      'Note, some agents may not be members of the National Association of Realtors. Check with the agent you elect to work with.';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 24.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/equal_housing_oppertunity.png',
            height: 56.h,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.home_work,
              size: 48.sp,
              color: AppTheme.primaryBlue,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            _pledgeText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.darkGray,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            _narDisclaimer,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.mediumGray,
              fontSize: 12.sp,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            _licenseText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.darkGray,
              fontSize: 12.sp,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

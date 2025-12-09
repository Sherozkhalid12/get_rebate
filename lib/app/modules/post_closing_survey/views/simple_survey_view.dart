import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/modules/post_closing_survey/controllers/simple_survey_controller.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/widgets/custom_button.dart';

class SimpleSurveyView extends GetView<SimpleSurveyController> {
  const SimpleSurveyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: Text(
          'Survey Test',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
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
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.science,
                      size: 48.sp,
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Survey Test Page',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.darkGray,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Testing survey navigation and functionality',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Progress Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Current Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.darkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(
                      () => Text(
                        'Step ${controller.currentStep} of 9',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Obx(
                      () => LinearProgressIndicator(
                        value: controller.currentStep / 9,
                        backgroundColor: AppTheme.lightGray,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryBlue,
                        ),
                        minHeight: 8.h,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Navigation Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Previous',
                      onPressed: controller.previousStep,
                      isOutlined: true,
                      icon: Icons.arrow_back,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: CustomButton(
                      text: 'Next',
                      onPressed: controller.nextStep,
                      icon: Icons.arrow_forward,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Close Button
              CustomButton(
                text: 'Close Survey',
                onPressed: () => Get.back(),
                isOutlined: true,
                icon: Icons.close,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

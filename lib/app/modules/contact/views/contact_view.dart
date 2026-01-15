import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/contact/controllers/contact_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';

class ContactView extends GetView<ContactController> {
  const ContactView({super.key});

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
        title: Text(
          'Contact ${controller.userName}',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40.h),
          
          // Profile Image
          CircleAvatar(
            radius: 60.r,
            backgroundColor: _getUserColor().withOpacity(0.1),
            backgroundImage: controller.userProfilePic != null
                ? NetworkImage(controller.userProfilePic!)
                : null,
            child: controller.userProfilePic == null
                ? Icon(
                    _getUserIcon(),
                    color: _getUserColor(),
                    size: 60.r,
                  )
                : null,
          ),
          
          SizedBox(height: 24.h),
          
          // Name
          Text(
            controller.userName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 8.h),
          
          // Role
          Text(
            _getRoleLabel(controller.userRole),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 40.h),
          
          // Start Chat Button
          Obx(() {
            final isCreating = controller.isCreatingThread;
            return CustomButton(
              text: 'Start Chat',
              onPressed: isCreating ? null : controller.startChat,
              icon: Icons.chat,
              width: double.infinity,
              backgroundColor: AppTheme.primaryBlue,
              height: 56.h,
            );
          }),
          
          SizedBox(height: 16.h),
          
          // Loading indicator if creating thread
          Obx(() {
            final isCreating = controller.isCreatingThread;
            if (isCreating) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Column(
                  children: [
                    SizedBox(
                      width: 30.w,
                      height: 30.h,
                      child: SpinKitFadingCircle(
                        color: AppTheme.primaryBlue,
                        size: 30,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Starting conversation...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Color _getUserColor() {
    switch (controller.userRole) {
      case 'agent':
        return AppTheme.primaryBlue;
      case 'loan_officer':
        return AppTheme.lightGreen;
      default:
        return AppTheme.mediumGray;
    }
  }

  IconData _getUserIcon() {
    switch (controller.userRole) {
      case 'agent':
        return Icons.person;
      case 'loan_officer':
        return Icons.account_balance;
      default:
        return Icons.person;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'agent':
        return 'Real Estate Agent';
      case 'loan_officer':
        return 'Loan Officer';
      default:
        return 'User';
    }
  }
}


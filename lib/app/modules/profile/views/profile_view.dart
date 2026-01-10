import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/profile/controllers/profile_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

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
          'Profile',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            if (controller.isEditing) {
              return IconButton(
                icon: const Icon(Icons.close, color: AppTheme.white),
                onPressed: controller.toggleEditing,
              );
            }
            return IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.white),
              onPressed: controller.toggleEditing,
            );
          }),
        ],
      ),
      body: Obx(() {
        return RefreshIndicator(
          onRefresh: () async {
            controller.refreshUserData();
          },
          color: AppTheme.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Profile Header with Image
                _buildProfileHeader(context)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.2, duration: 400.ms),
                
                // Profile Form
                _buildProfileForm(context)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 100.ms)
                    .slideY(begin: 0.2, duration: 400.ms, delay: 100.ms),
                
                SizedBox(height: 20.h),
                
                // Settings
                _buildSettings(context)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: 0.2, duration: 400.ms, delay: 200.ms),
                
                SizedBox(height: 20.h),
                
                // Logout Button
                _buildLogoutButton(context)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 300.ms)
                    .slideY(begin: 0.2, duration: 400.ms, delay: 300.ms),
                
                SizedBox(height: 40.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.primaryGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
          child: Column(
            children: [
              // Profile Image
              Obx(() {
                final hasSelectedFile = controller.selectedImageFile != null;
                final hasImageUrl = controller.profileImageUrl != null &&
                    controller.profileImageUrl!.isNotEmpty;

                if (hasImageUrl && kDebugMode) {
                  print('🖼️ ProfileView: Displaying image from URL: ${controller.profileImageUrl}');
                }

                return GestureDetector(
                  onTap: controller.isEditing
                      ? controller.pickProfileImage
                      : null,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: hasSelectedFile
                              ? Image.file(
                                  controller.selectedImageFile!,
                                  fit: BoxFit.cover,
                                )
                              : hasImageUrl
                                  ? Image.network(
                                      controller.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        if (kDebugMode) {
                                          print('❌ ProfileView: Failed to load image: ${controller.profileImageUrl}');
                                          print('   Error: $error');
                                        }
                                        return Container(
                                          color: AppTheme.white.withOpacity(0.2),
                                          child: Icon(
                                            Icons.person,
                                            size: 60.sp,
                                            color: AppTheme.white,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppTheme.white.withOpacity(0.3),
                                            AppTheme.white.withOpacity(0.1),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        size: 60.sp,
                                        color: AppTheme.white,
                                      ),
                                    ),
                        ),
                      )
                          .animate()
                          .scale(
                            duration: 300.ms,
                            curve: Curves.elasticOut,
                          ),
                      if (controller.isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: AppTheme.primaryBlue,
                              size: 20.sp,
                            ),
                          )
                              .animate()
                              .scale(duration: 200.ms, curve: Curves.elasticOut),
                        ),
                    ],
                  ),
                );
              }),
              
              SizedBox(height: 20.h),
              
              // User Name
              Obx(() {
                final user = controller.currentUser;
                return Text(
                  user?.name ?? 'User',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                );
              }),
              
              SizedBox(height: 8.h),
              
              // User Email
              Obx(() {
                final user = controller.currentUser;
                return Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryBlue,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkGray,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24.h),
            
            // Name
            CustomTextField(
              controller: controller.nameController,
              labelText: 'Full Name',
              prefixIcon: Icons.person_outline,
              enabled: controller.isEditing,
            ),
            
            SizedBox(height: 16.h),
            
            // Email
            CustomTextField(
              controller: controller.emailController,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              enabled: false, // Email cannot be changed
            ),
            
            SizedBox(height: 16.h),
            
            // Phone
            CustomTextField(
              controller: controller.phoneController,
              labelText: 'Phone Number',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              enabled: controller.isEditing,
            ),
            
            SizedBox(height: 16.h),
            
            // Bio
            CustomTextField(
              controller: controller.bioController,
              labelText: 'Bio',
              prefixIcon: Icons.info_outline,
              maxLines: 4,
              enabled: controller.isEditing,
            ),
            
            SizedBox(height: 24.h),
            
            // Save/Cancel Buttons
            if (controller.isEditing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.toggleEditing,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        side: BorderSide(color: AppTheme.mediumGray),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppTheme.darkGray,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: Obx(() {
                      return ElevatedButton(
                        onPressed: controller.isLoading ? null : controller.saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: AppTheme.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: AppTheme.primaryBlue.withOpacity(0.6),
                        ),
                        child: controller.isLoading
                            ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: SpinKitThreeBounce(
                                  color: AppTheme.white,
                                  size: 12.sp,
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      );
                    }),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            context,
            icon: Icons.description_outlined,
            title: 'My Proposals',
            subtitle: 'View and manage your service proposals',
            onTap: () => Get.toNamed('/proposals'),
          ),
          Divider(height: 1, indent: 60.w),
          _buildSettingTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            onTap: () => Get.toNamed('/privacy-policy'),
          ),
          Divider(height: 1, indent: 60.w),
          _buildSettingTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'View our terms of service',
            onTap: () => Get.toNamed('/terms-of-service'),
          ),
          Divider(height: 1, indent: 60.w),
          _buildSettingTile(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help or contact support',
            onTap: () => Get.toNamed('/help-support'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      leading: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryBlue,
          size: 24.sp,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppTheme.darkGray,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13.sp,
          color: AppTheme.mediumGray,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppTheme.mediumGray,
        size: 16.sp,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: CustomButton(
        text: 'Logout',
        onPressed: controller.logout,
        backgroundColor: Colors.red,
        width: double.infinity,
        icon: Icons.logout,
      ),
    );
  }
}

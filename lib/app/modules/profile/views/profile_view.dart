import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Content
              _buildProfileContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Image
          _buildProfileImage(context),

          const SizedBox(height: 24),

          // Profile Form
          _buildProfileForm(context),

          const SizedBox(height: 24),

          // // Rebate Checklist
          // _buildRebateChecklistSection(context),
          //
          // const SizedBox(height: 24),

          // Settings
          _buildSettings(context),

          const SizedBox(height: 24),

          // Logout Button
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: controller.isEditing ? controller.changeProfileImage : null,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              backgroundImage: controller.selectedImage != null
                  ? NetworkImage(controller.selectedImage!)
                  : null,
              child: controller.selectedImage == null
                  ? const Icon(
                      Icons.person,
                      color: AppTheme.primaryBlue,
                      size: 60,
                    )
                  : null,
            ),
            if (controller.isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppTheme.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Name
            CustomTextField(
              controller: controller.nameController,
              labelText: 'Full Name',
              prefixIcon: Icons.person_outline,
              enabled: controller.isEditing,
            ),

            const SizedBox(height: 16),

            // Email
            CustomTextField(
              controller: controller.emailController,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              enabled: false, // Email cannot be changed
            ),

            const SizedBox(height: 16),

            // Phone
            CustomTextField(
              controller: controller.phoneController,
              labelText: 'Phone Number',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              enabled: controller.isEditing,
            ),

            const SizedBox(height: 16),

            // Bio
            CustomTextField(
              controller: controller.bioController,
              labelText: 'Bio',
              prefixIcon: Icons.info_outline,
              maxLines: 3,
              enabled: controller.isEditing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRebateChecklistSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rebate Checklist',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Follow step-by-step guidance to ensure you receive your rebate',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'View Rebate Checklist',
              onPressed: () {
                Get.toNamed('/rebate-checklist');
              },
              icon: Icons.checklist,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Privacy
            ListTile(
              leading: const Icon(
                Icons.privacy_tip_outlined,
                color: AppTheme.primaryBlue,
              ),
              title: const Text('Privacy Policy'),
              subtitle: const Text('View our privacy policy'),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.mediumGray,
                size: 16,
              ),
              onTap: () {
                Get.snackbar('Info', 'Privacy policy coming soon!');
              },
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            // Terms
            ListTile(
              leading: const Icon(
                Icons.description_outlined,
                color: AppTheme.primaryBlue,
              ),
              title: const Text('Terms of Service'),
              subtitle: const Text('View our terms of service'),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.mediumGray,
                size: 16,
              ),
              onTap: () {
                Get.snackbar('Info', 'Terms of service coming soon!');
              },
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            // Support
            ListTile(
              leading: const Icon(
                Icons.help_outline,
                color: AppTheme.primaryBlue,
              ),
              title: const Text('Help & Support'),
              subtitle: const Text('Get help or contact support'),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.mediumGray,
                size: 16,
              ),
              onTap: () {
                Get.snackbar('Info', 'Help & support coming soon!');
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return CustomButton(
      text: 'Logout',
      onPressed: controller.logout,
      backgroundColor: Colors.red,
      width: double.infinity,
      icon: Icons.logout,
    );
  }
}

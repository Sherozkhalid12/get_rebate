import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/auth/controllers/auth_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/models/agent_expertise.dart';
import 'package:getrebate/app/models/mortgage_types.dart';

class AuthView extends GetView<AuthViewController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Header
              _buildHeader(context),

              const SizedBox(height: 40),

              // Form
              _buildForm(context),

              const SizedBox(height: 32),

              // Social login
              _buildSocialLogin(context),

              const SizedBox(height: 24),

              // Toggle mode
              _buildToggleMode(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/mainlogo.png',
                  fit: BoxFit.contain,
                  width: 80,
                  height: 80,
                ),
              ),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 800.ms),

        const SizedBox(height: 24),

        // Title
        Obx(
              () => Text(
                controller.isLoginMode ? 'Welcome Back' : 'Create Account',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
            .animate()
            .slideY(
              begin: 0.3,
              duration: 800.ms,
              curve: Curves.easeOut,
              delay: 200.ms,
            )
            .fadeIn(duration: 800.ms, delay: 200.ms),

        const SizedBox(height: 8),

        // Subtitle
        Obx(
              () => Text(
                controller.isLoginMode
                    ? 'Sign in to continue to GetaRebate'
                    : 'Join GetaRebate and start saving on real estate',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.mediumGray),
                textAlign: TextAlign.center,
              ),
            )
            .animate()
            .slideY(
              begin: 0.3,
              duration: 800.ms,
              curve: Curves.easeOut,
              delay: 400.ms,
            )
            .fadeIn(duration: 800.ms, delay: 400.ms),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          // Name field (only for signup)
          if (!controller.isLoginMode) ...[
            CustomTextField(
                  controller: controller.nameController,
                  labelText: 'Full Name',
                  prefixIcon: Icons.person_outline,
                )
                .animate()
                .slideX(begin: -0.3, duration: 600.ms, curve: Curves.easeOut)
                .fadeIn(duration: 600.ms),

            const SizedBox(height: 16),

            // Profile Picture (only for signup)
            _buildProfilePicturePicker(context)
                .animate()
                .slideX(begin: -0.3, duration: 600.ms, curve: Curves.easeOut)
                .fadeIn(duration: 600.ms),

            const SizedBox(height: 16),
          ],

          // Email field
          CustomTextField(
                controller: controller.emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              )
              .animate()
              .slideX(
                begin: -0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
                delay: controller.isLoginMode ? 0.ms : 100.ms,
              )
              .fadeIn(
                duration: 600.ms,
                delay: controller.isLoginMode ? 0.ms : 100.ms,
              ),

          const SizedBox(height: 16),

          // Password field
          CustomTextField(
                controller: controller.passwordController,
                labelText: 'Password',
                obscureText: controller.obscurePassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppTheme.mediumGray,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
              )
              .animate()
              .slideX(
                begin: -0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
                delay: controller.isLoginMode ? 100.ms : 200.ms,
              )
              .fadeIn(
                duration: 600.ms,
                delay: controller.isLoginMode ? 100.ms : 200.ms,
              ),

          // Phone field (only for signup)
          if (!controller.isLoginMode) ...[
            const SizedBox(height: 16),
            CustomTextField(
                  controller: controller.phoneController,
                  labelText: 'Phone (Optional)',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                )
                .animate()
                .slideX(
                  begin: -0.3,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                  delay: 300.ms,
                )
                .fadeIn(duration: 600.ms, delay: 300.ms),
          ],

          // Agent Required Information (only for agent signup)
          if (!controller.isLoginMode &&
              controller.selectedRole == UserRole.agent) ...[
            const SizedBox(height: 24),
            _buildAgentRequiredFields(context),
          ],

          // Loan Officer Required Information (only for loan officer signup)
          if (!controller.isLoginMode &&
              controller.selectedRole == UserRole.loanOfficer) ...[
            const SizedBox(height: 24),
            _buildLoanOfficerRequiredFields(context),
          ],

          // Dual Agency Questions (only for agent signup)
          if (!controller.isLoginMode &&
              controller.selectedRole == UserRole.agent) ...[
            const SizedBox(height: 24),
            _buildDualAgencyQuestions(context),
          ],

          // Agent Profile Fields (only for agent signup)
          if (!controller.isLoginMode &&
              controller.selectedRole == UserRole.agent) ...[
            const SizedBox(height: 24),
            _buildAgentProfileFields(context),
          ],

          // Loan Officer Profile Fields (only for loan officer signup)
          if (!controller.isLoginMode &&
              controller.selectedRole == UserRole.loanOfficer) ...[
            const SizedBox(height: 24),
            _buildLoanOfficerProfileFields(context),
          ],

          // Role selection (only for signup)
          if (!controller.isLoginMode) ...[
            const SizedBox(height: 24),
            _buildRoleSelection(context),
          ],

          const SizedBox(height: 32),

          // Submit button
          Obx(
                () => CustomButton(
                  text: controller.isLoginMode ? 'Sign In' : 'Create Account',
                  onPressed: controller.isLoading
                      ? null
                      : controller.submitForm,
                  isLoading: controller.isLoading,
                  width: double.infinity,
                ),
              )
              .animate()
              .slideY(
                begin: 0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
                delay: controller.isLoginMode ? 200.ms : 500.ms,
              )
              .fadeIn(
                duration: 600.ms,
                delay: controller.isLoginMode ? 200.ms : 500.ms,
              ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your role',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.darkGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  context,
                  UserRole.buyerSeller,
                  'Buyer/Seller',
                  Icons.home,
                  'Looking to buy or sell a home',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRoleCard(
                  context,
                  UserRole.agent,
                  'Agent',
                  Icons.person,
                  'Real estate agent',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  context,
                  UserRole.loanOfficer,
                  'Loan Officer',
                  Icons.account_balance,
                  'Mortgage professional',
                ),
              ),
              const SizedBox(width: 12),
              // Empty space to maintain layout
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    UserRole role,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = controller.selectedRole == role;

    return GestureDetector(
      onTap: () => controller.selectRole(role),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : AppTheme.lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.mediumGray,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDualAgencyQuestions(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dual Agency Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dual Agency happens when the buyer is working with an agent from the same Brokerage that has the property listed for sale.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: 16),

              // Is Dual Agency Allowed in your State?
              Text(
                'Is Dual Agency Allowed in your State?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _buildYesNoButton(
                        context,
                        'Yes',
                        controller.isDualAgencyAllowedInState == true,
                        () => controller.setDualAgencyInState(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildYesNoButton(
                        context,
                        'No',
                        controller.isDualAgencyAllowedInState == false,
                        () => controller.setDualAgencyInState(false),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Is Dual Agency Allowed at your Brokerage?
              Text(
                'Is Dual Agency Allowed at your Brokerage?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _buildYesNoButton(
                        context,
                        'Yes',
                        controller.isDualAgencyAllowedAtBrokerage == true,
                        () => controller.setDualAgencyAtBrokerage(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildYesNoButton(
                        context,
                        'No',
                        controller.isDualAgencyAllowedAtBrokerage == false,
                        () => controller.setDualAgencyAtBrokerage(false),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .slideY(
          begin: 0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
          delay: 400.ms,
        )
        .fadeIn(duration: 600.ms, delay: 400.ms);
  }

  Widget _buildAgentRequiredFields(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Required Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Brokerage
              CustomTextField(
                controller: controller.brokerageController,
                labelText: 'Brokerage / Company Name *',
                prefixIcon: Icons.business_outlined,
                hintText: 'Enter your brokerage or company name',
              ),
              const SizedBox(height: 16),

              // License Number
              CustomTextField(
                controller: controller.agentLicenseNumberController,
                labelText: 'License Number *',
                prefixIcon: Icons.badge_outlined,
                hintText: 'Enter your real estate license number',
              ),
              const SizedBox(height: 16),

              // Company Logo
              _buildCompanyLogoPicker(
                context,
                accentColor: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 16),

              // Licensed States
              Text(
                'Licensed States *',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select all states where you are licensed',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: 12),
              _buildLicensedStatesSelection(context),
              const SizedBox(height: 16),

              // Service Areas (ZIP codes)
              CustomTextField(
                controller: controller.serviceZipCodesController,
                labelText: 'Enter your office ZIP code *',
                prefixIcon: Icons.location_on_outlined,
                hintText: 'Enter your office ZIP code',
                keyboardType: TextInputType.number,
                maxLength: 5,
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.my_location,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  onPressed: () => controller.useCurrentLocationForZip(
                    controller.serviceZipCodesController,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Verification Agreement
              _buildAgentVerificationAgreement(context),
            ],
          ),
        )
        .animate()
        .slideY(
          begin: 0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
          delay: 400.ms,
        )
        .fadeIn(duration: 600.ms, delay: 400.ms);
  }

  Widget _buildLoanOfficerRequiredFields(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Required Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Company
              CustomTextField(
                controller: controller.companyController,
                labelText: 'Mortgage / Lender Company Name *',
                prefixIcon: Icons.business_outlined,
                hintText: 'Enter your mortgage or lender company name',
              ),
              const SizedBox(height: 16),

              // License Number
              CustomTextField(
                controller: controller.loanOfficerLicenseNumberController,
                labelText: 'License Number *',
                prefixIcon: Icons.badge_outlined,
                hintText: 'Enter your mortgage license number',
              ),
              const SizedBox(height: 16),

              // Company Logo
              _buildCompanyLogoPicker(
                context,
                accentColor: AppTheme.lightGreen,
              ),
              const SizedBox(height: 16),

              // Licensed States
              Text(
                'Licensed States *',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select all states where you are licensed',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: 12),
              _buildLicensedStatesSelection(context),
              const SizedBox(height: 16),

              // Service Areas (ZIP codes)
              CustomTextField(
                controller: controller.loanOfficerOfficeZipController,
                labelText: 'Enter your office ZIP code *',
                prefixIcon: Icons.location_on_outlined,
                hintText: 'Enter your office ZIP code',
                keyboardType: TextInputType.number,
                maxLength: 5,
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.my_location,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  onPressed: () => controller.useCurrentLocationForZip(
                    controller.loanOfficerOfficeZipController,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Verification Agreement
              _buildLoanOfficerVerificationAgreement(context),
            ],
          ),
        )
        .animate()
        .slideY(
          begin: 0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
          delay: 400.ms,
        )
        .fadeIn(duration: 600.ms, delay: 400.ms);
  }

  Widget _buildLicensedStatesSelection(BuildContext context) {
    // Only include states where rebates are allowed
    final usStates = [
      'AZ',
      'AR',
      'CA',
      'CO',
      'CT',
      'DE',
      'FL',
      'GA',
      'HI',
      'ID',
      'IL',
      'IN',
      'KY',
      'ME',
      'MD',
      'MA',
      'MI',
      'MN',
      'MT',
      'NE',
      'NV',
      'NH',
      'NJ',
      'NM',
      'NY',
      'NC',
      'ND',
      'OH',
      'PA',
      'RI',
      'SC',
      'SD',
      'TX',
      'UT',
      'VT',
      'VA',
      'WA',
      'WV',
      'WI',
      'WY',
    ];

    return Obx(
      () => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: usStates.map((state) {
          final isSelected = controller.isLicensedStateSelected(state);
          final color = controller.selectedRole == UserRole.agent
              ? AppTheme.primaryBlue
              : AppTheme.lightGreen;
          return GestureDetector(
            onTap: () => controller.toggleLicensedState(state),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : AppTheme.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? color
                      : AppTheme.mediumGray.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: isSelected ? color : AppTheme.mediumGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    state,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected ? color : AppTheme.darkGray,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAgentProfileFields(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agent Profile Information (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your bio, expertise areas, and professional links to help buyers find you.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: 16),

              // Bio
              CustomTextField(
                controller: controller.bioController,
                labelText: 'Bio / Introduction (Optional)',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                hintText:
                    'Tell Buyers and Sellers about yourself and why they should pick you as their Agent...',
              ),
              const SizedBox(height: 16),

              // Video Upload
              _buildVideoUploadField(context),
              const SizedBox(height: 16),

              // Areas of Expertise
              Text(
                'Areas of Expertise (Select all that apply)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _buildExpertiseSelection(context),
              const SizedBox(height: 16),

              // Website URL
              CustomTextField(
                controller: controller.websiteUrlController,
                labelText: 'Website URL (Optional)',
                prefixIcon: Icons.language_outlined,
                keyboardType: TextInputType.url,
                hintText: 'https://yourwebsite.com',
              ),
              const SizedBox(height: 16),

              // Google Reviews URL
              CustomTextField(
                controller: controller.googleReviewsUrlController,
                labelText: 'Google Reviews Page (Optional)',
                prefixIcon: Icons.star_outline,
                keyboardType: TextInputType.url,
                hintText: 'Link to your Google Business reviews',
              ),
              const SizedBox(height: 16),

              // Third Party Reviews URL
              CustomTextField(
                controller: controller.thirdPartyReviewsUrlController,
                labelText: 'Third-Party Reviews (Optional)',
                prefixIcon: Icons.rate_review_outlined,
                keyboardType: TextInputType.url,
                hintText: 'Zillow, Realtor.com, or other review sites',
              ),
            ],
          ),
        )
        .animate()
        .slideY(
          begin: 0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
          delay: 500.ms,
        )
        .fadeIn(duration: 600.ms, delay: 500.ms);
  }

  Widget _buildLoanOfficerProfileFields(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loan Officer Profile Information (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your bio, specialty products, and professional links to help buyers find you.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: 16),

              // Bio
              CustomTextField(
                controller: controller.loanOfficerBioController,
                labelText: 'Bio / Introduction (Optional)',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                hintText: 'Tell buyers about yourself and your experience...',
              ),
              const SizedBox(height: 16),

              // Video Upload
              _buildVideoUploadField(context),
              const SizedBox(height: 16),

              // Specialty Products (Areas of Expertise)
              Text(
                'Areas of Expertise & Specialty Products (Select all that apply)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the mortgage types you specialize in. Buyers will see descriptions of each type.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              _buildSpecialtyProductsSelection(context),
              const SizedBox(height: 16),

              // Website URL
              CustomTextField(
                controller: controller.loanOfficerWebsiteUrlController,
                labelText: 'Website URL (Optional)',
                prefixIcon: Icons.language_outlined,
                keyboardType: TextInputType.url,
                hintText: 'https://yourwebsite.com',
              ),
              const SizedBox(height: 16),

              // Mortgage Application URL
              CustomTextField(
                controller: controller.mortgageApplicationUrlController,
                labelText: 'Mortgage Application Link (Optional)',
                prefixIcon: Icons.assignment_outlined,
                keyboardType: TextInputType.url,
                hintText: 'Link to apply for a mortgage now',
              ),
              const SizedBox(height: 16),

              // External Reviews URL
              CustomTextField(
                controller: controller.loanOfficerExternalReviewsUrlController,
                labelText: 'Reviews Page (Optional)',
                prefixIcon: Icons.star_outline,
                keyboardType: TextInputType.url,
                hintText: 'Google, Zillow, or other review sites',
              ),
            ],
          ),
        )
        .animate()
        .slideY(
          begin: 0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
          delay: 500.ms,
        )
        .fadeIn(duration: 600.ms, delay: 500.ms);
  }

  Widget _buildVideoUploadField(BuildContext context) {
    return Obx(() {
      final videoFile = controller.selectedVideo;
      final hasVideo = videoFile != null;
      final fileName = hasVideo
          ? videoFile.path.split('/').last
          : 'No video selected';
      final actionLabel = hasVideo ? 'Change Video' : 'Upload Video';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video Introduction (Optional)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a short intro video from your device (gallery or files).',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: hasVideo ? AppTheme.black : AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: controller.pickVideo,
                icon: Icon(Icons.upload_file, color: AppTheme.primaryBlue),
                label: Text(
                  actionLabel,
                  style: const TextStyle(color: AppTheme.primaryBlue),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
              if (hasVideo) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: controller.removeVideo,
                  icon: const Icon(Icons.close),
                  color: AppTheme.mediumGray,
                  tooltip: 'Remove video',
                ),
              ],
            ],
          ),
        ],
      );
    });
  }

  Widget _buildSpecialtyProductsSelection(BuildContext context) {
    return Obx(
      () => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: MortgageTypes.getAll().map((product) {
          final isSelected = controller.isSpecialtyProductSelected(product);
          return GestureDetector(
            onTap: () => controller.toggleSpecialtyProduct(product),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightGreen.withOpacity(0.1)
                    : AppTheme.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightGreen
                      : AppTheme.mediumGray.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: isSelected
                        ? AppTheme.lightGreen
                        : AppTheme.mediumGray,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      product,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? AppTheme.lightGreen
                            : AppTheme.darkGray,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpertiseSelection(BuildContext context) {
    return Obx(
      () => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: AgentExpertise.getAll().map((expertise) {
          final isSelected = controller.isExpertiseSelected(expertise);
          return GestureDetector(
            onTap: () => controller.toggleExpertise(expertise),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlue.withOpacity(0.1)
                    : AppTheme.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.mediumGray.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : AppTheme.mediumGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    expertise,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.darkGray,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAgentVerificationAgreement(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.agentVerificationAgreed
                ? AppTheme.primaryBlue
                : AppTheme.mediumGray.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: controller.agentVerificationAgreed,
                  onChanged: (value) =>
                      controller.setAgentVerificationAgreed(value ?? false),
                  activeColor: AppTheme.primaryBlue,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verification Statement *',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.darkGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'I confirm that:\n'
                        '• I am in good standing and properly licensed to practice real estate in the states I have selected\n'
                        '• I have confirmed with my broker that I am able to offer real estate rebates with buyers and sellers on this platform\n'
                        '• I understand that buyers and sellers should do their own due diligence',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.darkGray,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanOfficerVerificationAgreement(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.lightGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.loanOfficerVerificationAgreed
                ? AppTheme.lightGreen
                : AppTheme.mediumGray.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: controller.loanOfficerVerificationAgreed,
                  onChanged: (value) => controller
                      .setLoanOfficerVerificationAgreed(value ?? false),
                  activeColor: AppTheme.lightGreen,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verification Statement *',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.darkGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'I confirm that:\n'
                        '• I am properly licensed to originate mortgages in the states I have selected\n'
                        '• I have confirmed with my lender that real estate rebates are allowed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.darkGray,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoButton(
    BuildContext context,
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.mediumGray,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? AppTheme.white : AppTheme.darkGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLogin(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppTheme.mediumGray)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
              ),
            ),
            const Expanded(child: Divider(color: AppTheme.mediumGray)),
          ],
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: CustomIconButton(
                icon: Icons.g_mobiledata,
                onPressed: () => controller.socialLogin('google'),
                backgroundColor: AppTheme.lightGray,
                iconColor: AppTheme.darkGray,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomIconButton(
                icon: Icons.apple,
                onPressed: () => controller.socialLogin('apple'),
                backgroundColor: AppTheme.black,
                iconColor: AppTheme.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomIconButton(
                icon: Icons.facebook,
                onPressed: () => controller.socialLogin('facebook'),
                backgroundColor: const Color(0xFF1877F2),
                iconColor: AppTheme.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfilePicturePicker(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Picture (Optional)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: controller.pickProfilePicture,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.mediumGray.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: controller.selectedProfilePic != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            controller.selectedProfilePic!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => controller.removeProfilePicture(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: AppTheme.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppTheme.mediumGray,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add profile picture',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mediumGray),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyLogoPicker(
    BuildContext context, {
    required Color accentColor,
  }) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Logo (Optional)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a square logo so your branding appears on your profile.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: controller.pickCompanyLogo,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: controller.selectedCompanyLogo != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            controller.selectedCompanyLogo!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: controller.removeCompanyLogo,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: AppTheme.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: accentColor,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload your company logo',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mediumGray),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleMode(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            controller.isLoginMode
                ? "Don't have an account? "
                : "Already have an account? ",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
          ),
          GestureDetector(
            onTap: controller.toggleMode,
            child: Text(
              controller.isLoginMode ? 'Sign Up' : 'Sign In',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

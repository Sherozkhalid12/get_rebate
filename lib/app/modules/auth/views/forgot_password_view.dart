import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/auth/controllers/forgot_password_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.04),
              AppTheme.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.darkGray,
                          size: 18,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      _buildHeader(context),
                      const SizedBox(height: 40),
                      _buildEmailField(context),
                      const SizedBox(height: 32),
                      _buildSubmitButton(context),
                      const SizedBox(height: 24),
                      _buildBackToLogin(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.2),
                AppTheme.lightBlue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.lock_reset_rounded,
            size: 48,
            color: AppTheme.primaryBlue,
          ),
        )
            .animate()
            .scale(duration: 700.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 500.ms),

        const SizedBox(height: 32),

        Text(
          'Forgot password?',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        )
            .animate()
            .slideY(begin: 0.2, duration: 550.ms, curve: Curves.easeOutCubic, delay: 80.ms)
            .fadeIn(duration: 550.ms, delay: 80.ms),

        const SizedBox(height: 12),

        Text(
          'Enter your email and we\'ll send you a code to reset your password.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.mediumGray,
              ),
          textAlign: TextAlign.center,
        )
            .animate()
            .slideY(begin: 0.2, duration: 550.ms, curve: Curves.easeOutCubic, delay: 120.ms)
            .fadeIn(duration: 550.ms, delay: 120.ms),
      ],
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return CustomTextField(
      controller: controller.emailController,
      labelText: 'Email',
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.email_outlined,
    )
        .animate()
        .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut, delay: 200.ms)
        .fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Obx(
      () => CustomButton(
        text: 'Send reset code',
        onPressed: controller.isLoading ? null : controller.sendResetCode,
        isLoading: controller.isLoading,
        width: double.infinity,
      ),
    )
        .animate()
        .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut, delay: 280.ms)
        .fadeIn(duration: 500.ms, delay: 280.ms);
  }

  Widget _buildBackToLogin(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => Get.back(),
        child: Text(
          'Back to sign in',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut, delay: 320.ms)
        .fadeIn(duration: 500.ms, delay: 320.ms);
  }
}

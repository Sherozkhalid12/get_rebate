import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/auth/controllers/reset_password_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

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
                      _buildOtpInput(context),
                      const SizedBox(height: 24),
                      _buildPasswordField(context),
                      const SizedBox(height: 16),
                      _buildConfirmPasswordField(context),
                      const SizedBox(height: 32),
                      _buildResendSection(context),
                      const SizedBox(height: 40),
                      _buildResetButton(context),
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
            Icons.password_rounded,
            size: 48,
            color: AppTheme.primaryBlue,
          ),
        )
            .animate()
            .scale(duration: 700.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 500.ms),

        const SizedBox(height: 32),

        Text(
          'Reset password',
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
          'We sent a 6-digit code to',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.mediumGray,
              ),
          textAlign: TextAlign.center,
        )
            .animate()
            .slideY(begin: 0.2, duration: 550.ms, curve: Curves.easeOutCubic, delay: 120.ms)
            .fadeIn(duration: 550.ms, delay: 120.ms),

        const SizedBox(height: 6),

        Text(
          controller.email,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        )
            .animate()
            .slideY(begin: 0.2, duration: 550.ms, curve: Curves.easeOutCubic, delay: 160.ms)
            .fadeIn(duration: 550.ms, delay: 160.ms),
      ],
    );
  }

  Widget _buildOtpInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextFormField(
        controller: controller.otpController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.bold,
              letterSpacing: 12,
            ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(
          counterText: '',
          hintText: '000000',
          hintStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.mediumGray.withOpacity(0.5),
                letterSpacing: 12,
              ),
          filled: true,
          fillColor: AppTheme.lightGray,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          prefixIcon: Icon(
            Icons.pin_rounded,
            color: AppTheme.primaryBlue.withOpacity(0.7),
            size: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.mediumGray.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppTheme.primaryBlue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
        onChanged: (value) {
          if (value.length == 6) {
            FocusScope.of(context).unfocus();
          }
        },
      ),
    )
        .animate()
        .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut, delay: 200.ms)
        .fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildPasswordField(BuildContext context) {
    return Obx(
      () => CustomTextField(
        controller: controller.passwordController,
        labelText: 'New password',
        obscureText: controller.obscurePassword,
        prefixIcon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            controller.obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.mediumGray,
          ),
          onPressed: controller.togglePasswordVisibility,
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut, delay: 250.ms)
        .fadeIn(duration: 500.ms, delay: 250.ms);
  }

  Widget _buildConfirmPasswordField(BuildContext context) {
    return Obx(
      () => CustomTextField(
        controller: controller.confirmPasswordController,
        labelText: 'Confirm new password',
        obscureText: controller.obscureConfirm,
        prefixIcon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            controller.obscureConfirm ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.mediumGray,
          ),
          onPressed: controller.toggleConfirmVisibility,
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut, delay: 280.ms)
        .fadeIn(duration: 500.ms, delay: 280.ms);
  }

  Widget _buildResendSection(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          if (controller.canResend)
            TextButton(
              onPressed: controller.isResending ? null : controller.resendCode,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: controller.isResending
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryBlue,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Resend code',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: AppTheme.mediumGray,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resend code in ${controller.resendCountdown}s',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                ),
              ],
            ),
        ],
      ),
    )
        .animate()
        .slideY(begin: 0.2, duration: 550.ms, curve: Curves.easeOutCubic, delay: 300.ms)
        .fadeIn(duration: 550.ms, delay: 300.ms);
  }

  Widget _buildResetButton(BuildContext context) {
    return Obx(
      () => CustomButton(
        text: 'Reset password',
        onPressed: controller.isLoading ? null : controller.resetPassword,
        isLoading: controller.isLoading,
        width: double.infinity,
      ),
    )
        .animate()
        .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut, delay: 350.ms)
        .fadeIn(duration: 500.ms, delay: 350.ms);
  }
}

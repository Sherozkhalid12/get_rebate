import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/utils/guest_auth_guard.dart';
import 'package:getrebate/app/widgets/custom_button.dart';

/// Premium sign-in prompt shown when a guest attempts a restricted action.
class GuestAuthDialog extends StatelessWidget {
  final String? featureDescription;

  const GuestAuthDialog({super.key, this.featureDescription});

  static Future<void> show({String? featureDescription}) {
    return Get.dialog(
      GuestAuthDialog(featureDescription: featureDescription),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = featureDescription != null && featureDescription!.isNotEmpty
        ? 'Sign in or create a free account to $featureDescription.'
        : 'Sign in or create a free account to unlock this feature and save your progress.';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppTheme.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create your free account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join GetaRebate to connect with verified agents, save favorites, and message professionals.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.white.withOpacity(0.92),
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mediumGray,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 20),
                    _BenefitRow(
                      icon: Icons.savings_outlined,
                      text: 'Estimate rebates and track your savings',
                    ),
                    const SizedBox(height: 10),
                    _BenefitRow(
                      icon: Icons.favorite_border,
                      text: 'Save agents, listings, and loan officers',
                    ),
                    const SizedBox(height: 10),
                    _BenefitRow(
                      icon: Icons.chat_bubble_outline,
                      text: 'Message verified agents and lenders',
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Log In',
                      onPressed: GuestAuthGuard.navigateToLogin,
                      width: double.infinity,
                      icon: Icons.login_rounded,
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Sign Up',
                      onPressed: GuestAuthGuard.navigateToSignUp,
                      width: double.infinity,
                      isOutlined: true,
                      icon: Icons.person_add_outlined,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Continue browsing',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.mediumGray,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 280.ms, curve: Curves.easeOut)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              duration: 320.ms,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

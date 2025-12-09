import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/onboarding/controllers/onboarding_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: controller.skipOnboarding,
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                children: const [
                  _OnboardingPage(
                    icon: Icons.search,
                    title: 'Get a Rebate When You Buy, Build, or Sell',
                    description:
                        'Connect with local real estate agents who give back a portion of their commission, saving you money at closing.',
                    color: AppTheme.primaryBlue,
                  ),
                  _OnboardingPage(
                    icon: Icons.people,
                    title: 'Verified Agents. Approved Lenders. Real Savings.',
                    description:
                        'Every agent on our site offers a rebate, and every loan officer has confirmed their lender allows it. Start your smarter real estate journey today.',
                    color: AppTheme.lightGreen,
                  ),
                  _OnboardingPage(
                    icon: Icons.calculate,
                    title: 'Know your savings before you buy, build or sell.',
                    description:
                        'Our Rebate Calculator gives you an instant estimate of your potential rebate.',
                    color: AppTheme.lightBlue,
                  ),
                ],
              ),
            ),

            // Bottom section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Page indicators
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: controller.currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: controller.currentPage == index
                                ? AppTheme.primaryBlue
                                : AppTheme.mediumGray.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ).animate().scale(
                          duration: 300.ms,
                          curve: Curves.easeInOut,
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Get Started button
                  CustomButton(
                        text: 'Get Started',
                        onPressed: controller.nextPage,
                        width: double.infinity,
                      )
                      .animate()
                      .slideY(
                        begin: 0.3,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(duration: 600.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(icon, size: 60, color: color),
              )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 800.ms),

          const SizedBox(height: 48),

          // Title
          Text(
                title,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .slideY(
                begin: 0.3,
                duration: 800.ms,
                curve: Curves.easeOut,
                delay: 200.ms,
              )
              .fadeIn(duration: 800.ms, delay: 200.ms),

          const SizedBox(height: 24),

          // Description
          Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.mediumGray,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/splash/controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    print('Splash: View building...');
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20.r,
                        offset: Offset(0, 10.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.home_work,
                    size: 60.sp,
                    color: AppTheme.primaryBlue,
                  ),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 800.ms),

            SizedBox(height: 32.h),

            // App Name
            Text(
                  'Get a Rebate',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32.sp,
                  ),
                )
                .animate()
                .slideY(begin: 0.3, duration: 800.ms, curve: Curves.easeOut)
                .fadeIn(duration: 800.ms),

            SizedBox(height: 16.h),

            // Tagline
            Text(
                  'Get a Rebate Real Estate',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 18.sp,
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

            SizedBox(height: 60.h),
          ],
        ),
      ),
    );
  }
}

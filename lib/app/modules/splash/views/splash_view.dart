import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/splash/controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    print('Splash: View building...');

    // Remove native splash after first frame so Flutter splash with text shows
    // Wait a tiny bit to ensure Flutter splash is fully rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        FlutterNativeSplash.remove();
        print(
          'Splash: Native splash removed, Flutter splash with text now visible',
        );
      });
    });

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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: Image.asset(
                      'assets/images/mainlogo.png',
                      fit: BoxFit.contain,
                      width: 120.w,
                      height: 120.w,
                    ),
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

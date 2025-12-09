import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/bindings/initial_binding.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'GetaRebate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,
          initialBinding: InitialBinding(),
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}

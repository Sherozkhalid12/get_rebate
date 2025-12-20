import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? fontSize;
  final int? maxLines;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.fontSize,
    this.maxLines,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.borderRadius = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20.w,
            height: 20.w,
            child: SpinKitFadingCircle(
              color: isOutlined ? AppTheme.primaryBlue : AppTheme.white,
              size: 20.w,
            ),
          ),
          SizedBox(width: 12.w),
        ] else if (icon != null) ...[
          Icon(
            icon,
            size: 20.sp,
            color: isOutlined
                ? (textColor ?? AppTheme.primaryBlue)
                : AppTheme.white,
          ),
          SizedBox(width: 8.w),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: maxLines ?? 2,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isOutlined
                  ? (textColor ?? AppTheme.primaryBlue)
                  : AppTheme.white,
              fontWeight: FontWeight.w600,
              fontSize: fontSize ?? 12.sp,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    if (isOutlined) {
      return Container(
        width: width,
        height: height ?? 48.h,
        constraints: width != null ? null : BoxConstraints(minWidth: 100.w),
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: backgroundColor ?? AppTheme.primaryBlue,
              width: 1.5.w,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding:
                padding ??
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          child: buttonChild,
        ),
      );
    }

    return Container(
      width: width,
      height: height ?? 48.h,
      constraints: width != null ? null : BoxConstraints(minWidth: 100.w),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.primaryBlue,
          foregroundColor: textColor ?? AppTheme.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding:
              padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        ),
        child: buttonChild,
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double borderRadius;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.lightGray,
          foregroundColor: iconColor ?? AppTheme.darkGray,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: size * 0.4.sp),
      ),
    );
  }
}

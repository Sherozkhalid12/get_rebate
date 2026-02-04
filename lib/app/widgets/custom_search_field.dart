import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class CustomSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;
  final bool showClearButton;
  final VoidCallback? onLocationTap;
  final bool isLocationLoading;

  const CustomSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.showClearButton = true,
    this.onLocationTap,
    this.isLocationLoading = false,
  });

  @override
  State<CustomSearchField> createState() => _CustomSearchFieldState();
}

class _CustomSearchFieldState extends State<CustomSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      keyboardType: TextInputType.number, // Numeric keyboard for ZIP codes
      maxLength: 5, // ZIP codes are 5 digits
      inputFormatters: [
        // Only allow digits
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(Icons.search, color: AppTheme.mediumGray, size: 20.sp),
        suffixIcon: _buildSuffixIcon(),
        filled: true,
        fillColor: AppTheme.lightGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2.w),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        hintStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    // If text is not empty, show clear button
    if (widget.showClearButton && widget.controller.text.isNotEmpty) {
      return IconButton(
        icon: Icon(Icons.clear, color: AppTheme.mediumGray, size: 20.sp),
        onPressed: () {
          widget.controller.clear();
          widget.onClear?.call();
        },
      );
    }

    // If text is empty and location tap is provided, show location icon or loading
    if (widget.onLocationTap != null && widget.controller.text.isEmpty) {
      if (widget.isLocationLoading) {
        return Padding(
          padding: EdgeInsets.all(12.sp),
          child: SizedBox(
            width: 24.sp,
            height: 24.sp,
            child: SpinKitRing(
              color: AppTheme.primaryBlue,
              lineWidth: 2.0,
              size: 24.sp,
            ),
          ),
        );
      }
      return IconButton(
        icon: Icon(Icons.my_location, color: AppTheme.primaryBlue, size: 20.sp),
        onPressed: widget.onLocationTap,
      );
    }

    return null;
  }
}

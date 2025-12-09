import 'package:flutter/material.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? shadowColor;

  const GradientCard({
    super.key,
    required this.child,
    this.gradientColors,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? AppTheme.cardGradient;
    final cardBorderRadius = borderRadius ?? BorderRadius.circular(20);

    Widget cardContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: cardBorderRadius,
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? AppTheme.primaryBlue.withOpacity(0.15),
            blurRadius: elevation ?? 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: cardBorderRadius,
            child: cardContent,
          ),
        ),
      );
    }

    return Container(margin: margin, child: cardContent);
  }
}

class GradientCardWithIcon extends StatelessWidget {
  final Widget child;
  final IconData icon;
  final Color? iconColor;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GradientCardWithIcon({
    super.key,
    required this.child,
    required this.icon,
    this.iconColor,
    this.gradientColors,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? AppTheme.primaryGradient;
    final cardBorderRadius = borderRadius ?? BorderRadius.circular(20);

    Widget cardContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: cardBorderRadius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            blurRadius: elevation ?? 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor ?? Colors.white, size: 18),
              ),
            ),
            // const SizedBox(height: 4),
            Expanded(child: Center(child: child)),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: cardBorderRadius,
            child: cardContent,
          ),
        ),
      );
    }

    return Container(margin: margin, child: cardContent);
  }
}

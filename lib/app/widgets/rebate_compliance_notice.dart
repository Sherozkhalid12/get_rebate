import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/widgets/rebate_states_info_modal.dart';

/// Reusable compliance notice widget for rebate eligibility
/// Shows a professional disclaimer about rebate-allowed states
class RebateComplianceNotice extends StatelessWidget {
  final Color? accentColor;
  final bool showViewStatesButton;
  final EdgeInsets? padding;
  final double? borderRadius;

  const RebateComplianceNotice({
    super.key,
    this.accentColor,
    this.showViewStatesButton = false,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primaryBlue;

    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(borderRadius ?? 10),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rebate Eligibility Notice',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Only states that allow real-estate rebates are shown. Please verify that rebates are permitted in your state.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkGray,
                        height: 1.4,
                        fontSize: 12,
                      ),
                ),
                if (showViewStatesButton) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showStatesInfoModal(context, color),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View allowed states',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatesInfoModal(BuildContext context, Color accentColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RebateStatesInfoModal(accentColor: accentColor),
    );
  }
}

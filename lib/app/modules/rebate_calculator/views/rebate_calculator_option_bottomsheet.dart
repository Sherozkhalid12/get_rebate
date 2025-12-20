// lib/app/modules/rebate_calculator/widgets/rebate_calculator_options_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/rebate_calculator/views/rebate_calculator_view.dart';

class RebateCalculatorOptionsBottomSheet extends StatelessWidget {
  const RebateCalculatorOptionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose Calculator',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppTheme.darkGray),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Option 1: Estimated Tiers
          _buildOption(
            icon: Icons.bar_chart,
            title: 'Estimated Rebate Tiers',
            subtitle: 'Enter estimated price → see all 6 rebate tiers',
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const RebateCalculatorView(), arguments: {'mode': 0});
            },
          ),
          const Divider(height: 1),

          // Option 2: Actual Rebate
          _buildOption(
            icon: Icons.calculate,
            title: 'Actual Rebate Calculator',
            subtitle: 'Enter actual price + BAC → exact rebate',
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const RebateCalculatorView(), arguments: {'mode': 1});
            },
          ),
          const Divider(height: 1),

          // Option 3: Seller Conversion
          _buildOption(
            icon: Icons.swap_horiz,
            title: 'Seller Rebate Conversion',
            subtitle: 'Convert original fee → new effective % after rebate',
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const RebateCalculatorView(), arguments: {'mode': 2});
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue, size: 28),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTheme.mediumGray, fontSize: 13),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: AppTheme.primaryBlue.withOpacity(0.05),
    );
  }
}
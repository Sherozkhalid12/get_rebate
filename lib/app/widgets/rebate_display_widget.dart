import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/services/rebate_calculator_service.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/utils/rebate_restricted_states.dart';

class RebateDisplayWidget extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onFindAgents;
  final VoidCallback? onDualAgencyInfo;

  const RebateDisplayWidget({
    super.key,
    required this.listing,
    this.onFindAgents,
    this.onDualAgencyInfo,
  });

  @override
  Widget build(BuildContext context) {
    final rebateRange = RebateCalculatorService.calculateRebateRange(
      listPrice: listing.priceCents / 100.0, // Convert cents to dollars
      bacPercentage:
          listing.bacPercent / 100.0, // Convert percentage to decimal
      allowsDualAgency: listing.dualAgencyAllowed,
      dualAgencyCommissionPercentage:
          listing.dualAgencyCommissionPercent != null
          ? listing.dualAgencyCommissionPercent! / 100.0
          : null,
    );
    final String bacPercentText = listing.bacPercent.toStringAsFixed(1);
    final String? dualAgencyPercentText = listing.dualAgencyCommissionPercent != null
        ? listing.dualAgencyCommissionPercent!.toStringAsFixed(1)
        : null;

    final isRestricted = RebateRestrictedStates.isRestricted(listing.address.state);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on, color: AppTheme.lightGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRestricted
                      ? 'Potential Buyer Rebate (not permitted in this state)'
                      : 'Potential Buyer Rebate',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (isRestricted) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.mediumGray.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.gavel, color: AppTheme.darkGray, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      RebateRestrictedStates.restrictedStateNotice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkGray,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Find agents button - moved above rebate options

          // Standard rebate range
          _buildRebateRange(
            context,
            'When you work with an Agent from this site',
            rebateRange.standardRebateRangeText,
            'Estimated rebate based on the $bacPercentText% BAC entered by the listing agent',
            Icons.handshake,
            onTap: () => _showBACDialog(context),
          ),
          if (onFindAgents != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onFindAgents,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Find Nearby Agents'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightGreen,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (rebateRange.hasDualAgencyOption) ...[
            const SizedBox(height: 12),
            _buildRebateRange(
              context,
              'When you work directly with the listing agent',
              rebateRange.dualAgencyRebateRangeText,
              dualAgencyPercentText != null
                  ? 'Estimated rebate based on the ${dualAgencyPercentText}% total commission entered by the listing agent'
                  : 'Estimated rebate based on the total commission the listing agent receives when dual agency applies',
              Icons.person,
              isHighlighted: true,
              onTap: onDualAgencyInfo,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRebateRange(
    BuildContext context,
    String title,
    String amount,
    String subtitle,
    IconData icon, {
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppTheme.lightGreen.withOpacity(0.1)
              : AppTheme.lightGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: isHighlighted
              ? Border.all(color: AppTheme.lightGreen.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isHighlighted ? AppTheme.lightGreen : AppTheme.mediumGray,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.darkGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isHighlighted ? AppTheme.lightGreen : AppTheme.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            if (onTap != null) ...[
              Icon(
                Icons.info_outline,
                color: isHighlighted
                    ? AppTheme.lightGreen
                    : AppTheme.primaryBlue,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBACDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => BACExplanationDialog());
  }
}

class BACExplanationDialog extends StatelessWidget {
  const BACExplanationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  'What is BAC?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'BAC stands for Buyer Agent Commission. This is the percentage of the home\'s sale price that the seller offers to pay the buyer\'s agent as commission. LAC refers to the Listing Agent Commission, which covers the listing agent\'s side of the transaction.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DualAgencyExplanationDialog extends StatelessWidget {
  const DualAgencyExplanationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.lightGreen, size: 24),
                const SizedBox(width: 12),
                Text(
                  'What is Dual Agency?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Dual agency occurs when one real estate agent represents both the buyer and seller in the same transaction.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
            ),
            const SizedBox(height: 12),

            Text(
              'Benefits:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            _buildBenefitItem(
              context,
              'Higher rebate potential',
              'You may receive a larger rebate since the agent doesn\'t need to split commission with another agent.',
            ),
            _buildBenefitItem(
              context,
              'Streamlined process',
              'Direct communication with the listing agent can speed up negotiations.',
            ),

            const SizedBox(height: 16),

            Text(
              'Considerations:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            _buildBenefitItem(
              context,
              'Limited representation',
              'The agent cannot provide exclusive advocacy for either party.',
              isWarning: true,
            ),
            _buildBenefitItem(
              context,
              'Potential conflicts',
              'The agent must remain neutral and cannot negotiate aggressively for either side.',
              isWarning: true,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightGreen,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    String title,
    String description, {
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning
                ? Icons.warning_amber_outlined
                : Icons.check_circle_outline,
            color: isWarning ? Colors.orange : AppTheme.lightGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

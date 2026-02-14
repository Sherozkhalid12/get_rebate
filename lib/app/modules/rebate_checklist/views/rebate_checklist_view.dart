import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/rebate_checklist/controllers/rebate_checklist_controller.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/models/user_model.dart';

class RebateChecklistView extends GetView<RebateChecklistController> {
  const RebateChecklistView({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is an agent or loan officer
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser;
    final canAccessChecklist =
        currentUser != null &&
        (currentUser.role == UserRole.agent ||
            currentUser.role == UserRole.loanOfficer);
    
    // If user is not an agent/loan officer, show access denied message
    if (!canAccessChecklist) {
      return Scaffold(
        backgroundColor: AppTheme.lightGray,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryBlue,
          elevation: 0,
          title: Text(
            'Access Restricted',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Agent/Loan Officer Checklists',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'These checklists contain real estate jargon and are designed for agents and loan officers.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.darkGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you\'re a buyer or seller, please use the consumer checklists available in the main menu.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.primaryGradient,
            ),
          ),
        ),
        title: Text(
          'Rebate Checklist',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildRebateChecklists(context),
        ),
      ),
    );
  }

  Widget _buildRebateChecklists(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rebate Checklists',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Buying/Building Checklist
        _buildChecklistCard(
          context,
          'Real Estate Agent Rebate Checklist – Buying/Building (Agent view)',
          controller.getRebateChecklistForBuying(),
          Icons.shopping_bag,
          AppTheme.primaryBlue,
          isBuyingChecklist: true,
        ),

        const SizedBox(height: 16),

        // Selling Checklist
        _buildChecklistCard(
          context,
          'Rebate Checklist for Selling (Agent view)',
          controller.getRebateChecklistForSelling(),
          Icons.sell,
          AppTheme.lightGreen,
          isSellingChecklist: true,
        ),
      ],
    );
  }

  Widget _buildChecklistCard(
    BuildContext context,
    String title,
    List<String> items,
    IconData icon,
    Color color, {
    bool isBuyingChecklist = false,
    bool isSellingChecklist = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (isBuyingChecklist) ...[
            const SizedBox(height: 12),
            Text(
              'Follow these steps to ensure compliance when working with a buyer who will receive a real estate commission rebate.\n\n(Continue providing your standard services—such as MLS searches, showings, negotiations, and client support—as usual.)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...List.generate(items.length, (index) {
            final stepNumber = index + 1;
            final hasAddendum =
                (isBuyingChecklist && (stepNumber == 2 || stepNumber == 9)) ||
                (isSellingChecklist && stepNumber == 2);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: color, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '$stepNumber',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[index],
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.darkGray,
                                    height: 1.4,
                                  ),
                            ),
                            if (hasAddendum) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => _showAddendumDialog(
                                  context,
                                  isBuyingChecklist
                                      ? (stepNumber == 2
                                            ? 'Buyer Representation Agreement Addendum (Step #2)'
                                            : 'Purchase Offer Rebate Disclosure (Step #9)')
                                      : 'Listing Agreement Rebate Disclosure (Step #2)',
                                  isBuyingChecklist
                                      ? (stepNumber == 2
                                            ? controller
                                                  .getRebateAddendumForBuyerRepresentation()
                                            : controller
                                                  .getRebateDisclosureForPurchaseOffer())
                                      : controller
                                            .getRebateDisclosureForListingAgreement(),
                                  color,
                                ),
                                icon: Icon(
                                  Icons.description,
                                  color: color,
                                  size: 18,
                                ),
                                label: Text(
                                  'View Addendum Text',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _printChecklist(context, title, items),
                icon: Icon(Icons.print, color: color, size: 18),
                label: Text(
                  'Print',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _printChecklist(BuildContext context, String title, List<String> items) {
    // For now, show a dialog with the checklist that can be printed
    Get.dialog(
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      ...List.generate(items.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.primaryBlue,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${index + 1}. ${items[index]}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.darkGray,
                                        height: 1.4,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.snackbar(
                        'Print',
                        'Print functionality will be available soon!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppTheme.primaryBlue,
                        colorText: AppTheme.white,
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: AppTheme.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddendumDialog(
    BuildContext context,
    String title,
    String content,
    Color color,
  ) {
    Get.dialog(
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SelectableText(
                      content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkGray,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: content));
                      if (context.mounted) {
                        Get.snackbar(
                          'Copied',
                          'Addendum text copied to clipboard',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppTheme.lightGreen,
                          colorText: AppTheme.white,
                          duration: const Duration(seconds: 2),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: AppTheme.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/loan_officer_checklist/controllers/loan_officer_checklist_controller.dart';

class LoanOfficerChecklistView extends GetView<LoanOfficerChecklistController> {
  const LoanOfficerChecklistView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.lightGreen,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightGreen,
                AppTheme.lightGreen.withOpacity(0.8),
              ],
            ),
          ),
        ),
        title: Text(
          'Loan Officer Checklist',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: AppTheme.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(context),

            const SizedBox(height: 24),

            // Platform Overview
            _buildPlatformOverview(context),

            const SizedBox(height: 24),

            // Main Checklist
            _buildChecklistSection(context),

            const SizedBox(height: 24),

            // Success Tips
            _buildSuccessTipsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.checklist_rtl,
                    color: AppTheme.lightGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Officer Guide',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your step-by-step guide to success',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.lightGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This platform connects you with opportunities. Most of your loan processing work happens outside the app through your mortgage application link.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformOverview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.lightGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'How the Platform Works',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              controller.getPlatformOverview(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistSection(BuildContext context) {
    final checklistItems = controller.getLoanOfficerChecklist();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: AppTheme.lightGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Loan Officer Checklist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...checklistItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildChecklistItem(context, index + 1, item);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(BuildContext context, int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.lightGreen.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: AppTheme.lightGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessTipsSection(BuildContext context) {
    final tips = controller.getSuccessTips();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_outline,
                  color: AppTheme.lightGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tips for Success',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.lightGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkGray,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

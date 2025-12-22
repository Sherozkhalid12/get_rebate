// lib/app/modules/rebate_calculator/views/rebate_calculator_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/rebate_calculator/controllers/rebate_calculator_controller.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/services/rebate_calculator_api_service.dart';

class RebateCalculatorView extends StatelessWidget {
  const RebateCalculatorView({super.key});

  @override
  Widget build(BuildContext context) {
    // Auto-inject controller
    final controller = Get.put(RebateCalculatorController());

    // Read mode from bottom sheet
    final args = Get.arguments;
    if (args != null && args['mode'] is int) {
      controller.currentMode.value = args['mode'] as int;
    }

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, controller),
            _buildModeTabs(context, controller),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildFullForm(context, controller),
                    const SizedBox(height: 20),
                    Obx(() => _buildResults(context, controller)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader(BuildContext context, RebateCalculatorController c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              'Rebate Calculator',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: c.resetAll,
            icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
          ),
        ],
      ),
    );
  }

  // TABS
  Widget _buildModeTabs(BuildContext context, RebateCalculatorController c) {
    return Container(
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(
        () => Row(
          children: [
            _tab(context, c, 'Estimated', 0),
            _tab(context, c, 'Actual', 1),
            _tab(context, c, 'Seller Conversion', 2),
          ],
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    RebateCalculatorController c,
    String label,
    int idx,
  ) {
    final active = c.currentMode.value == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => c.setMode(idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : AppTheme.darkGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullForm(BuildContext context, RebateCalculatorController c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property & Commission',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            CustomTextField(
              controller: c.homePriceController,
              labelText: 'Sales Price',
              prefixIcon: Icons.home,
            ),

            const SizedBox(height: 20),
            _dropdown(
              context,
              'State',
              c.selectedState,
              c.allowedStates,
              c.setSelectedState,
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (c.isStateRestricted) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.getStateRestrictionMessage(c.selectedState),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            Obx(() {
              if (!c.shouldShowSellerRestriction) {
                return const SizedBox.shrink();
              }
              final message = c.getSellerRestrictionMessage();
              if (message.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.lightBlue),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),
            Text('Commission', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Obx(() {
              // For sellers (mode 2), show LAC field
              if (c.currentMode.value == 2) {
                return Column(
                  children: [
                    CustomTextField(
                      controller: c.sellerOriginalFeeController,
                      labelText: 'Listing Agent Commission (LAC) %',
                      prefixIcon: Icons.percent,
                      hintText: 'e.g. 2.5, 3.0',
                    ),
                  ],
                );
              }
              // For buyers (modes 0 and 1), show BAC field
              return CustomTextField(
                controller: c.agentCommissionController,
                labelText: 'Buyer Agent Commission (BAC) %',
                prefixIcon: Icons.percent,
                hintText: 'e.g. 2.5, 3.0',
              );
            }),

            const SizedBox(height: 20),
            _buildCommissionTierReference(context),

            const SizedBox(height: 16),
            _buildRebateInfoNote(context),

            const SizedBox(height: 24),
            // Convert/Calculate Button
            Obx(() => _buildConvertButton(context, c)),
          ],
        ),
      ),
    );
  }

  Widget _buildConvertButton(
    BuildContext context,
    RebateCalculatorController c,
  ) {
    // Only show Convert button for Estimated tab (mode 0)
    // Hide for Actual (mode 1) and Seller Conversion (mode 2)
    if (c.currentMode.value != 0) {
      return const SizedBox.shrink();
    }

    final isLoading = c.isLoading;
    final isFormValid = c.isFormValid;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isFormValid && !isLoading)
            ? () {
                c.calculateEstimated();
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: SpinKitFadingCircle(
                  color: Colors.white,
                  size: 20,
                ),
              )
            : Text(
                'Convert',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
      ),
    );
  }

  Widget _dropdown(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_on, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionTierReference(BuildContext context) {
    return ExpansionTile(
      title: const Text('Commission Tier Reference'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tierRow(
                context,
                'Tier 1: 4.0% or more',
                '40% rebate',
                AppTheme.lightGreen,
              ),
              _tierRow(
                context,
                'Tier 2: 3.01% - 3.99%',
                '35% rebate',
                AppTheme.lightBlue,
              ),
              _tierRow(
                context,
                'Tier 3: 2.5% - 3.0%',
                '30% rebate',
                AppTheme.mediumGray,
              ),
              _tierRow(
                context,
                'Tier 4: 2.0% - 2.49%',
                '25% rebate',
                AppTheme.mediumGray,
              ),
              _tierRow(
                context,
                'Tier 5: 1.5% - 1.99%',
                '20% rebate',
                AppTheme.mediumGray,
              ),
              _tierRow(
                context,
                'Tier 6: .25% - 1.49%',
                '10% rebate',
                AppTheme.mediumGray,
              ),
              _tierRow(
                context,
                'Tier 7: 0 - .24%',
                '0% rebate',
                AppTheme.mediumGray,
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Note: For homes \$700,000 or higher, Tiers 5 and 6 do not apply. The minimum rebate will be Tier 4 (25%).',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.darkGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRebateInfoNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: const Text(
        'Your rebate is based on the commission your agent (from this site) negotiates with the seller, listing agent, or builder. Real estate commissions are 100% negotiable.',
        style: TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }

  Widget _tierRow(
    BuildContext context,
    String range,
    String rebate,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(range),
          Text(
            rebate,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // RESULTS
  Widget _buildResults(BuildContext context, RebateCalculatorController c) {
    // Show API results if available, otherwise show local calculations
    final apiResult = c.currentApiResult;
    
    if (apiResult != null && apiResult.success) {
      return _buildApiResults(context, c, apiResult);
    }

    // Fallback to local calculations
    if (c.estimatedRebate.value <= 0 && c.currentMode.value != 0) {
      return _emptyState(context, "Enter details to calculate");
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.currentMode.value == 0
                  ? 'Rebate Tiers'
                  : c.currentMode.value == 1
                  ? 'Your Rebate'
                  : 'Commission Converted to Lower % Fee',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // State restriction warning in results
            Obx(() {
              if (c.isStateRestricted) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.block,
                                color: Colors.red.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Rebates Not Available in ${c.selectedState}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.getStateRestrictionMessage(c.selectedState),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'The calculations shown are for informational purposes only and may not apply in your state. Please consult with a licensed real estate professional in your area.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),

            // MODE 0: Tiers
            if (c.currentMode.value == 0) ...[
              // Show threshold warning if home price >= 700k
              if ((double.tryParse(c.homePriceController.text) ?? 0.0) >=
                  700000)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'For homes \$700,000+: Tiers 5 & 6 do not apply. Minimum is Tier 4.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ...c.tiers.map(
                (t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          t['range'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          t['rebate'],
                          style: TextStyle(color: t['color'], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\$${t['amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // MODE 1: Actual
            if (c.currentMode.value == 1) ...[
              _resultItem(
                context,
                'Rebate',
                '\$${c.actualRebate.toStringAsFixed(0)}',
                AppTheme.lightGreen,
              ),
              _resultItem(
                context,
                'Tier',
                c.actualTier.value,
                AppTheme.primaryBlue,
              ),
            ],

            // MODE 2: Seller
            if (c.currentMode.value == 2) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'This shows the lower listing agent commission (LAC) percentage when the rebate is applied directly to the listing agent commission.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              _resultItem(
                context,
                'Original Listing Agent Commission (LAC)',
                '${c.sellerOriginalFeeController.text}%',
                AppTheme.mediumGray,
              ),
              _resultItem(
                context,
                'Rebate Amount',
                '\$${c.sellerRebate.toStringAsFixed(0)}',
                AppTheme.lightGreen,
              ),
              const Divider(height: 24),
              _resultItem(
                context,
                'New Listing Agent Commission (LAC)',
                '${c.sellerNewFee.toStringAsFixed(2)}%',
                AppTheme.primaryBlue,
                bold: true,
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.toNamed('/find-agents');
                },
                icon: const Icon(Icons.search, size: 24),
                label: const Text(
                  'Find Agents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultItem(
    BuildContext context,
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 20 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, String msg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.calculate, size: 48, color: AppTheme.mediumGray),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.mediumGray),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds API results display
  Widget _buildApiResults(
    BuildContext context,
    RebateCalculatorController c,
    RebateCalculatorResponse result,
  ) {
    // Check if maxRebate is "or more" from rawData
    bool isOrMore = false;
    if (result.rawData != null) {
      final estimate = result.rawData!['estimate'];
      if (estimate is Map<String, dynamic>) {
        final range = estimate['estimatedRebateRange'];
        if (range is Map<String, dynamic>) {
          final max = range['max'];
          if (max != null && max.toString().toLowerCase().contains('more')) {
            isOrMore = true;
          }
        }
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppTheme.lightGray.withOpacity(0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calculate_rounded,
                      color: AppTheme.primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.currentMode.value == 0
                          ? 'Estimated Rebate Results'
                          : c.currentMode.value == 1
                          ? 'Exact Rebate Results'
                          : 'Seller Conversion Results',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGray,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main Results Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightBlue.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Tier with badge
                    if (result.tier != null && result.tier!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          result.tier!,
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Rebate Percentage - Large display
                    if (result.rebatePercentage != null) ...[
                      Text(
                        'Rebate Percentage',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.mediumGray,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${result.rebatePercentage!.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: AppTheme.lightGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Estimated Rebate Range - Highlighted
                    if (result.minRebate != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.lightGreen,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Estimated Rebate Range',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.darkGray,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isOrMore || result.maxRebate == null
                                  ? '${_formatCurrency(result.minRebate!)} or more'
                                  : _formatCurrencyRange(result.minRebate!, result.maxRebate!),
                              style: TextStyle(
                                color: AppTheme.lightGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Commission Range for Tier
                    if (result.minCommission != null) ...[
                      _buildResultRow(
                        context,
                        'Commission Range for Tier',
                        result.maxCommission != null
                            ? '${result.minCommission!.toStringAsFixed(2)}% – ${result.maxCommission!.toStringAsFixed(2)}%'
                            : '${result.minCommission!.toStringAsFixed(2)}% or more',
                        AppTheme.mediumGray,
                      ),
                    ],
                  ],
                ),
              ),

              // Notes
              if (result.notes != null && result.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                    ),
                    title: Text(
                      'Additional Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    children: [
                      ...result.notes!.map((note) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  note,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.blue.shade900,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],

              // Warnings
              if (result.warnings != null && result.warnings!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Important Warnings',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...result.warnings!.map((warning) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  warning,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.orange.shade900,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              // Find Agents Button - Enhanced
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed('/find-agents');
                  },
                  icon: const Icon(Icons.search, size: 24),
                  label: const Text(
                    'Find Agents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(
    BuildContext context,
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                    color: AppTheme.darkGray,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    fontSize: isBold ? 18 : 16,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _formatCurrencyRange(double min, double max) {
    return '${_formatCurrency(min)} – ${_formatCurrency(max)}';
  }
}
